import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Variant properties — set by WidgetHost at instantiation (not reactive)
    property var variantId: null
    property var variantData: null

    // Config resolution: variant → base → hardcoded default
    // Uses ?? (nullish coalescing) not || to correctly handle falsy values (0, false, "")
    property string command: (variantData?.command ?? pluginData.command ?? "").replace(/[\r\n]+/g, " ").trim()
    property string iconName: variantData?.icon ?? pluginData.icon ?? "info"
    property int refreshInterval: ((variantData?.refreshInterval ?? pluginData.refreshInterval ?? 10)) * 1000
    property string clickCommand: (variantData?.clickCommand ?? pluginData.clickCommand ?? "").replace(/[\r\n]+/g, " ").trim()
    property bool popoutEnabled: variantData?.popoutEnabled ?? pluginData.popoutEnabled ?? false
    property int popoutRefreshInterval: ((variantData?.popoutRefreshInterval ?? pluginData.popoutRefreshInterval ?? 5)) * 1000

    // State
    property string outputText: command === "" ? "No command set" : "..."
    property string popoutText: ""

    onCommandChanged: {
        if (commandProcess.running) {
            commandProcess.killed = true;
            commandProcess.running = false;
        }
        if (command === "") {
            outputText = "No command set";
        } else {
            outputText = "...";
        }
        // Restart the refresh timer so it runs the new command immediately (triggeredOnStart)
        // and resets the interval counter
        refreshTimer.restart();
    }

    // Re-fetch variant data when settings change (variantData from WidgetHost is not reactive)
    Connections {
        target: pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId && root.variantId) {
                root.variantData = pluginService.getPluginVariantData(root.pluginId, root.variantId);
            }
        }
    }

    // Click handler — only used when popout is disabled
    pillClickAction: popoutEnabled ? null : (x, y, width, section, screen) => {
        if (clickCommand !== "") {
            clickProcess.command = ["sh", "-c", root.clickCommand];
            clickProcess.running = true;
        }
    }

    // Process to run the configured command on a timer
    Process {
        id: commandProcess
        command: ["sh", "-c", root.command + "; echo"]
        running: false

        stdout: SplitParser {
            property bool captured: false
            onRead: data => {
                if (!captured) {
                    let line = data.trim();
                    if (line === "") return;
                    if (line.length > 50) {
                        line = line.substring(0, 50);
                    }
                    root.outputText = line;
                    captured = true;
                    commandProcess.hasEverCaptured = true;
                }
            }
        }

        property bool killed: false
        property bool hasEverCaptured: false
        onRunningChanged: {
            if (!running && !killed && !commandProcess.stdout.captured && hasEverCaptured) {
                root.outputText = "N/A";
            }
            killed = false;
        }
    }

    // Process to run the click command silently
    Process {
        id: clickProcess
        running: false
    }

    // Process to run the click command and capture full output for popout
    Process {
        id: popoutProcess
        command: ["sh", "-c", root.clickCommand + " | sed 's/\\x1b\\[[0-9;?]*[a-zA-Z]//g; s/\\x1b\\][^\\x07]*\\x07//g'; echo"]
        running: false

        stdout: SplitParser {
            property string buffer: ""
            onRead: data => {
                buffer = buffer === "" ? data : buffer + "\n" + data;
                root.popoutText = buffer.replace(/\n+$/, "");
            }
        }

        onRunningChanged: {
            if (!running) {
                let text = popoutProcess.stdout.buffer.replace(/\n+$/, "");
                root.popoutText = text || root.popoutText || "No output";
            }
        }
    }

    // Timer for popout refresh — only runs while popout is open
    Timer {
        id: popoutTimer
        interval: root.popoutRefreshInterval
        running: false
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.clickCommand !== "") {
                popoutProcess.stdout.buffer = "";
                popoutProcess.running = true;
            }
        }
    }

    // Timer to periodically execute the command
    Timer {
        id: refreshTimer
        interval: root.refreshInterval
        running: root.command !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.command !== "") {
                if (commandProcess.running) {
                    commandProcess.killed = true;
                    commandProcess.running = false;
                }
                commandProcess.stdout.captured = false;
                commandProcess.running = true;
            }
        }
    }

    // Horizontal bar layout
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.iconName
                size: root.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.outputText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Vertical bar layout
    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.iconName
                size: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.outputText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutWidth: variantData?.popoutWidth ?? pluginData.popoutWidth ?? 600
    popoutHeight: variantData?.popoutHeight ?? pluginData.popoutHeight ?? 450

    popoutContent: Component {
        PopoutComponent {
            id: popout

            Component.onCompleted: {
                popoutTimer.running = true;
            }

            Component.onDestruction: {
                popoutTimer.running = false;
            }

            Flickable {
                id: popoutFlickable
                width: parent.width
                height: Math.min(popoutTextItem.implicitHeight, root.popoutHeight)
                contentWidth: width
                contentHeight: popoutTextItem.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: popoutTextItem
                    width: popoutFlickable.width
                    text: root.popoutText || "Running..."
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: "monospace"
                    color: Theme.surfaceText
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
