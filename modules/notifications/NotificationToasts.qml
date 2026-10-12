import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
    id: root

    anchors {
        top: true
        right: true
    }

    margins {
        top: 42
        right: 14
    }

    implicitWidth: 380
    implicitHeight: toastCol.implicitHeight

    color: "transparent"
    visible: NotificationManager.activeToasts.length > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-toasts"
    WlrLayershell.exclusiveZone: 0

    Column {
        id: toastCol
        width: 380
        spacing: 8

        Repeater {
            model: NotificationManager.activeToasts
            delegate: ToastCard {
                required property var modelData
                notifData: modelData
            }
        }
    }
}
