import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "intervalCommandPlugin"

    StyledText {
        width: parent.width
        text: "Interval Command Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Run a shell command on an interval and display the output in the bar."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "command"
        label: "Command"
        description: "Shell command to run (e.g. ~/.config/DankMaterialShell/plugins/IntervalCommand/uptime-compact.sh)"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "icon"
        label: "Icon"
        description: "Material Design icon name — browse at fonts.google.com/icons"
        defaultValue: "info"
    }

    SliderSetting {
        settingKey: "refreshInterval"
        label: "Refresh Interval"
        description: "How often to run the command (in seconds)"
        defaultValue: 10
        minimum: 1
        maximum: 300
        unit: "s"
        leftIcon: "schedule"
    }

    StringSetting {
        settingKey: "clickCommand"
        label: "Click Command"
        description: "Optional command to run when the widget is clicked (e.g. notify-send 'hello')"
        defaultValue: ""
    }

    ToggleSetting {
        id: popoutToggle
        settingKey: "popoutEnabled"
        label: "Show Click Output in Popout"
        description: "When enabled, clicking the widget opens a panel showing the full click command output instead of running it silently"
        defaultValue: false
    }

    SliderSetting {
        visible: popoutToggle.value
        settingKey: "popoutRefreshInterval"
        label: "Popout Refresh Interval"
        description: "How often to refresh the click command output in the popout (in seconds)"
        defaultValue: 5
        minimum: 1
        maximum: 300
        unit: "s"
        leftIcon: "refresh"
    }

    SliderSetting {
        visible: popoutToggle.value
        settingKey: "popoutWidth"
        label: "Popout Width"
        description: "Width of the popout panel in pixels"
        defaultValue: 600
        minimum: 200
        maximum: 1920
        unit: "px"
        leftIcon: "width"
    }

    SliderSetting {
        visible: popoutToggle.value
        settingKey: "popoutHeight"
        label: "Popout Max Height"
        description: "Maximum height of the popout panel in pixels"
        defaultValue: 450
        minimum: 100
        maximum: 1080
        unit: "px"
        leftIcon: "height"
    }
}
