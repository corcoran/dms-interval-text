import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Settings
    property string command: pluginData.command || ""
    property string iconName: pluginData.icon || "info"
    property int refreshInterval: (pluginData.refreshInterval || 10) * 1000
    property string clickCommand: pluginData.clickCommand || ""
    property bool popoutEnabled: pluginData.popoutEnabled || false
    property int popoutRefreshInterval: (pluginData.popoutRefreshInterval || 5) * 1000

    // State
    property string outputText: command === "" ? "No command set" : "..."
    property string popoutText: ""

    onCommandChanged: {
        if (command === "") {
            outputText = "No command set";
        } else {
            outputText = "...";
            commandProcess.stdout.captured = false;
            commandProcess.running = true;
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
                    if (line.length > 30) {
                        line = line.substring(0, 30);
                    }
                    root.outputText = line;
                    captured = true;
                }
            }
        }

        onRunningChanged: {
            if (!running && !commandProcess.stdout.captured) {
                root.outputText = "N/A";
            }
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
            }
        }

        onRunningChanged: {
            if (!running) {
                let text = popoutProcess.stdout.buffer.replace(/\n+$/, "");
                root.popoutText = text || "No output";
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
        interval: root.refreshInterval
        running: root.command !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.command !== "") {
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

    popoutWidth: pluginData.popoutWidth || 600
    popoutHeight: pluginData.popoutHeight || 450

    popoutContent: Component {
        PopoutComponent {
            id: popout

            Component.onCompleted: {
                popoutTimer.running = true;
            }

            Component.onDestruction: {
                popoutTimer.running = false;
            }

            Text {
                width: parent.width
                text: root.popoutText || "Running..."
                font.pixelSize: Theme.fontSizeSmall
                font.family: "monospace"
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }
        }
    }
}
