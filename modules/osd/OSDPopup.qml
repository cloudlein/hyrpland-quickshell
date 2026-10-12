import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
    id: root

    anchors {
        bottom: true
    }

    margins {
        bottom: 75
    }

    implicitWidth: 260
    implicitHeight: 48
    color: "transparent"

    visible: OSDManager.osdVisible || fadeAnim.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: Theme.surface_container_high
        border.color: Theme.outline_variant
        border.width: 1

        opacity: OSDManager.osdVisible ? 1.0 : 0.0
        scale: OSDManager.osdVisible ? 1.0 : 0.94
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutBack
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            // OSD Icon
            Text {
                id: iconText
                anchors.verticalCenter: parent.verticalCenter
                text: OSDManager.icon
                font.family: Theme.fontFamily
                font.pixelSize: 18
                color: OSDManager.isMuted ? Theme.error : Theme.primary
            }

            // Progress Bar Track
            Rectangle {
                id: barTrack
                anchors.verticalCenter: parent.verticalCenter
                width: 140
                height: 8
                radius: 4
                color: Theme.surface_container_highest

                // Filled Bar
                Rectangle {
                    id: barFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(8, parent.width * OSDManager.value)
                    radius: 4
                    color: OSDManager.isMuted ? Theme.error : Theme.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Percentage Text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: OSDManager.isMuted ? "Mute" : `${Math.round(OSDManager.value * 100)}%`
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.on_surface
            }
        }
    }
}
