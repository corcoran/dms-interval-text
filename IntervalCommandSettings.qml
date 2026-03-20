import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "intervalCommand"

    // Track selected widget index in the variants array
    property int selectedIndex: 0

    // Get the currently selected variant data (null if none)
    property var selectedVariant: variants.length > 0 && selectedIndex >= 0 && selectedIndex < variants.length
        ? variants[selectedIndex] : null

    // Re-sync all form fields when switching widgets (bindings break after user edits)
    property bool _syncing: false
    onSelectedVariantChanged: {
        if (!selectedVariant) return;
        _syncing = true;
        nameField.text = selectedVariant.name ?? "";
        commandField.text = selectedVariant.command ?? "";
        iconField.text = selectedVariant.icon ?? "info";
        clickCommandField.text = selectedVariant.clickCommand ?? "";
        refreshSlider.value = selectedVariant.refreshInterval ?? 10;
        popoutToggle.checked = selectedVariant.popoutEnabled ?? false;
        popoutRefreshSlider.value = selectedVariant.popoutRefreshInterval ?? 5;
        popoutWidthSlider.value = selectedVariant.popoutWidth ?? 600;
        popoutHeightSlider.value = selectedVariant.popoutHeight ?? 450;
        _syncing = false;
    }

    // Re-sync selection when variants change, and auto-migrate if needed
    property bool migrationDone: false
    onVariantsChanged: {
        // Auto-migrate base widget to variant on first load
        if (!migrationDone && variants.length === 0 && pluginService) {
            let baseCommand = loadValue("command", "");
            if (baseCommand) {
                migrationDone = true;
                migrateBaseToVariant();
                return;  // migrateBaseToVariant creates a variant, which re-triggers onVariantsChanged
            }
        }

        // Clamp selection to valid range
        if (selectedIndex >= variants.length) {
            selectedIndex = Math.max(0, variants.length - 1);
        }
    }

    // Auto-incrementing counter for default widget names
    property int widgetCounter: 0

    function nextWidgetName() {
        widgetCounter++;
        return "Widget " + widgetCounter;
    }

    function migrateBaseToVariant() {
        let config = {
            command: loadValue("command", ""),
            icon: loadValue("icon", "info"),
            refreshInterval: loadValue("refreshInterval", 10),
            clickCommand: loadValue("clickCommand", ""),
            popoutEnabled: loadValue("popoutEnabled", false),
            popoutRefreshInterval: loadValue("popoutRefreshInterval", 5),
            popoutWidth: loadValue("popoutWidth", 600),
            popoutHeight: loadValue("popoutHeight", 450)
        };

        let variantId = createVariant("Widget", config);
        if (!variantId) return;

        // Replace base widget ID in all bar configs
        let fullId = "intervalCommand:" + variantId;
        let configs = JSON.parse(JSON.stringify(SettingsData.barConfigs));
        let changed = false;
        for (let i = 0; i < configs.length; i++) {
            let sections = ["leftWidgets", "centerWidgets", "rightWidgets"];
            for (let s = 0; s < sections.length; s++) {
                let widgets = configs[i][sections[s]];
                if (!widgets) continue;
                for (let w = 0; w < widgets.length; w++) {
                    let wid = typeof widgets[w] === "string" ? widgets[w] : widgets[w].id;
                    if (wid === "intervalCommand") {
                        if (typeof widgets[w] === "string") {
                            widgets[w] = fullId;
                        } else {
                            widgets[w].id = fullId;
                        }
                        changed = true;
                    }
                }
            }
        }
        if (changed) {
            SettingsData.barConfigs = configs;
            SettingsData.updateBarConfigs();
        }

        selectedIndex = 0;
    }

    // Save a single field for a specific variant (or selected if no id given)
    function saveFieldFor(variantId, key, value) {
        if (!variantId) return;
        // Strip newlines from text fields (can be pasted in but break shell commands)
        if (typeof value === "string")
            value = value.replace(/[\r\n]+/g, " ").trim();
        let config = {};
        config[key] = value;
        updateVariant(variantId, config);
    }

    function saveField(key, value) {
        if (!selectedVariant) return;
        saveFieldFor(selectedVariant.id, key, value);
    }

    // Debounced save for text fields — saves after 500ms of no typing
    // Tracks the variant ID at the time typing started so switching widgets
    // doesn't save to the wrong variant
    property string _pendingKey: ""
    property string _pendingValue: ""
    property string _pendingVariantId: ""
    Timer {
        id: saveDebounce
        interval: 500
        onTriggered: {
            if (root._pendingKey !== "" && root._pendingVariantId !== "")
                root.saveFieldFor(root._pendingVariantId, root._pendingKey, root._pendingValue);
        }
    }
    function debounceSave(key, value, field) {
        if (_syncing) return;
        if (field && !field.getActiveFocus()) return;
        _pendingKey = key;
        _pendingValue = value;
        _pendingVariantId = selectedVariant ? selectedVariant.id : "";
        saveDebounce.restart();
    }

    // Flush any pending debounced save immediately
    function flushPendingSave() {
        if (saveDebounce.running) {
            saveDebounce.stop();
            if (_pendingKey !== "" && _pendingVariantId !== "")
                saveFieldFor(_pendingVariantId, _pendingKey, _pendingValue);
            _pendingKey = "";
            _pendingVariantId = "";
        }
    }

    // ── Title & Description ──

    StyledText {
        width: parent.width
        text: "Interval Command"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    // ── State 1: No widgets — show "Add Widget" button ──

    DankButton {
        visible: root.variants.length === 0
        text: "Add Widget"
        iconName: "add"
        buttonHeight: 28
        horizontalPadding: Theme.spacingS
        iconSize: 16
        onClicked: {
            createVariant(root.nextWidgetName(), {});
            loadVariants();
            root.selectedIndex = 0;
        }
    }

    // ── State 2: One or more widgets exist ──

    // Widget list
    Column {
        id: widgetListSection
        visible: root.variants.length > 0
        width: parent.width
        spacing: Theme.spacingXS

        StyledText {
            text: "Widgets"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        Column {
            id: widgetList
            width: parent.width
            spacing: Theme.spacingXS

            Repeater {
                model: root.variantsModel

                delegate: Rectangle {
                    id: widgetRow
                    required property int index
                    required property var model
                    width: widgetList.width
                    height: rowContent.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: "transparent"
                    border.width: 1
                    border.color: index === root.selectedIndex
                        ? Theme.primary
                        : rowMouseArea.containsMouse
                            ? Theme.outline
                            : Theme.outlineMedium

                    Row {
                        id: rowContent
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            name: widgetRow.model.icon || "info"
                            size: Theme.iconSizeSmall
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: widgetRow.model.name || "Unnamed"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: rowContent.width - rowContent.spacing * 2
                                - deleteBtn.width - Theme.iconSizeSmall
                        }

                        Rectangle {
                            id: deleteBtn
                            width: 28
                            height: 28
                            radius: 14
                            color: deleteArea.containsMouse ? Theme.errorHover : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "delete"
                                size: 16
                                color: deleteArea.containsMouse
                                    ? Theme.error : Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: deleteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    removeVariant(widgetRow.model.id);
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.flushPendingSave();
                            root.selectedIndex = widgetRow.index;
                        }
                        z: -1
                    }
                }
            }
        }

        DankButton {
            text: "Add Another Widget"
            iconName: "add"
            buttonHeight: 28
            horizontalPadding: Theme.spacingS
            iconSize: 16
            onClicked: {
                createVariant(root.nextWidgetName(), {});
                loadVariants();
                root.selectedIndex = root.variants.length - 1;
            }
        }
    }

    // ── Settings form for selected widget ──

    Column {
        id: settingsForm
        visible: root.selectedVariant !== null
        width: parent.width
        spacing: Theme.spacingM

        StyledText {
            text: (root.selectedVariant?.name || "Widget") + " Settings"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        // Name
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Name"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            DankTextField {
                id: nameField
                width: parent.width
                text: root.selectedVariant?.name ?? ""
                placeholderText: "Widget name"
                onTextEdited: root.debounceSave("name", text, nameField)
                onEditingFinished: root.flushPendingSave()
            }
        }

        // Command
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Command"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: "Shell command to run (e.g. ~/.config/DankMaterialShell/plugins/intervalCommand/uptime-compact.sh)"
                font.pixelSize: Theme.fontSizeXSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            DankTextField {
                id: commandField
                width: parent.width
                text: root.selectedVariant?.command ?? ""
                placeholderText: "echo 'hello'"
                onTextEdited: root.debounceSave("command", text, commandField)
                onEditingFinished: root.flushPendingSave()
            }
        }

        // Icon
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Icon"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: "Material Design icon name — browse at fonts.google.com/icons"
                font.pixelSize: Theme.fontSizeXSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            DankTextField {
                id: iconField
                width: parent.width
                text: root.selectedVariant?.icon ?? "info"
                placeholderText: "info"
                onTextEdited: root.debounceSave("icon", text, iconField)
                onEditingFinished: root.flushPendingSave()
            }
        }

        // Refresh Interval
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Refresh Interval"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: "How often to run the command (in seconds)"
                font.pixelSize: Theme.fontSizeXSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            DankSlider {
                id: refreshSlider
                width: parent.width
                value: root.selectedVariant?.refreshInterval ?? 10
                minimum: 1
                maximum: 300
                unit: "s"
                leftIcon: "schedule"
                onSliderDragFinished: finalValue => root.saveField("refreshInterval", finalValue)
            }
        }

        // Click Command
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Click Command"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: "Command to run when the widget is clicked (leave empty for no action)"
                font.pixelSize: Theme.fontSizeXSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            DankTextField {
                id: clickCommandField
                width: parent.width
                text: root.selectedVariant?.clickCommand ?? ""
                placeholderText: "notify-send 'hello'"
                onTextEdited: root.debounceSave("clickCommand", text, clickCommandField)
                onEditingFinished: root.flushPendingSave()
            }
        }

        // Popout Toggle
        DankToggle {
            id: popoutToggle
            width: parent.width
            text: "Show Click Output in Popout"
            description: "Clicking the widget opens a panel showing the full click command output"
            checked: root.selectedVariant?.popoutEnabled ?? false
            onToggled: isChecked => {
                checked = isChecked;
                root.saveField("popoutEnabled", isChecked);
            }
        }

        // Popout Refresh Interval
        Column {
            visible: popoutToggle.checked
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Popout Refresh Interval"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: "How often to refresh the click command output in the popout (in seconds)"
                font.pixelSize: Theme.fontSizeXSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            DankSlider {
                id: popoutRefreshSlider
                width: parent.width
                value: root.selectedVariant?.popoutRefreshInterval ?? 5
                minimum: 1
                maximum: 300
                unit: "s"
                leftIcon: "refresh"
                onSliderDragFinished: finalValue => root.saveField("popoutRefreshInterval", finalValue)
            }
        }

        // Popout Width
        Column {
            visible: popoutToggle.checked
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Popout Width"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            DankSlider {
                id: popoutWidthSlider
                width: parent.width
                value: root.selectedVariant?.popoutWidth ?? 600
                minimum: 200
                maximum: 1920
                unit: "px"
                leftIcon: "width"
                onSliderDragFinished: finalValue => root.saveField("popoutWidth", finalValue)
            }
        }

        // Popout Max Height
        Column {
            visible: popoutToggle.checked
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "Popout Max Height"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            DankSlider {
                id: popoutHeightSlider
                width: parent.width
                value: root.selectedVariant?.popoutHeight ?? 450
                minimum: 100
                maximum: 1080
                unit: "px"
                leftIcon: "height"
                onSliderDragFinished: finalValue => root.saveField("popoutHeight", finalValue)
            }
        }
    }
}
