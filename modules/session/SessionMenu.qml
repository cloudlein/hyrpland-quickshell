import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../.."

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: SessionManager.open || fadeAnim.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-session-menu"
    WlrLayershell.keyboardFocus: SessionManager.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        active: SessionManager.open
        windows: [root]
        onCleared: SessionManager.open = false
    }

    property int selectedIndex: 2 // Default: Logout or Center

    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "󰌾", desc: "Lock Screen", danger: false },
        { id: "suspend", label: "Sleep", icon: "󰒲", desc: "Suspend System", danger: false },
        { id: "logout", label: "Exit", icon: "󰍃", desc: "Logout Hyprland", danger: false },
        { id: "reboot", label: "Reboot", icon: "󰜉", desc: "Restart Computer", danger: true },
        { id: "shutdown", label: "Power", icon: "󰐥", desc: "Shut Down", danger: true }
    ]

    Connections {
        target: SessionManager
        function onOpenChanged() {
            if (SessionManager.open) {
                root.selectedIndex = 2
                keyHandler.forceActiveFocus()
            }
        }
    }

    // Scrim Dimming Background
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#99000000"
        opacity: SessionManager.open ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: SessionManager.open = false
        }
    }

    // Keyboard Handler
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onLeftPressed: (event) => {
            root.selectedIndex = (root.selectedIndex - 1 + root.actions.length) % root.actions.length
            event.accepted = true
        }

        Keys.onRightPressed: (event) => {
            root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
            event.accepted = true
        }

        Keys.onTabPressed: (event) => {
            root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
            event.accepted = true
        }

        Keys.onReturnPressed: (event) => {
            SessionManager.execute(root.selectedIndex)
            event.accepted = true
        }

        Keys.onEnterPressed: (event) => {
            SessionManager.execute(root.selectedIndex)
            event.accepted = true
        }

        Keys.onEscapePressed: (event) => {
            SessionManager.open = false
            event.accepted = true
        }
    }

    // Center Card Modal
    Rectangle {
        id: modal
        anchors.centerIn: parent
        width: contentLayout.implicitWidth + 48
        height: contentLayout.implicitHeight + 48
        radius: 24
        color: Theme.surface_container_high
        border.color: Theme.outline_variant
        border.width: 1

        opacity: SessionManager.open ? 1.0 : 0.0
        scale: SessionManager.open ? 1.0 : 0.92
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutBack }
        }

        ColumnLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 24

            // Header Title
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "System Session"
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.on_surface
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.actions[root.selectedIndex].desc
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.secondary_fixed_dim
                }
            }

            // Action Buttons Row
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: btn
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedIndex === index
                        readonly property bool isHovered: btnMouse.containsMouse

                        width: 80
                        height: 90
                        radius: 18

                        color: (isSelected || isHovered)
                            ? (modelData.danger ? Theme.error_container : Theme.primary_container)
                            : Theme.surface_container

                        border.color: isSelected
                            ? (modelData.danger ? Theme.error : Theme.primary)
                            : "transparent"
                        border.width: 2

                        scale: (isSelected || isHovered) ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 28
                                color: (btn.isSelected || btn.isHovered)
                                    ? (btn.modelData.danger ? Theme.on_error_container : Theme.on_primary_container)
                                    : Theme.on_surface
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: (btn.isSelected || btn.isHovered)
                                    ? (btn.modelData.danger ? Theme.on_error_container : Theme.on_primary_container)
                                    : Theme.secondary_fixed_dim
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SessionManager.execute(btn.index)
                            onEntered: root.selectedIndex = btn.index
                        }
                    }
                }
            }

            // Bottom Hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Use Arrow Keys or Tab to navigate • Enter to select • Esc to cancel"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.outline
            }
        }
    }
}
