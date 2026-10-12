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
    visible: ClipboardManager.open || fadeAnim.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: ClipboardManager.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        active: ClipboardManager.open
        windows: [root]
        onCleared: ClipboardManager.closePicker()
    }

    readonly property var filteredItems: {
        let q = searchInput.text.toLowerCase().trim()
        let items = ClipboardManager.history || []
        if (!q) return items
        return items.filter(it => it.text && it.text.toLowerCase().includes(q))
    }

    Connections {
        target: ClipboardManager
        function onOpenChanged() {
            if (ClipboardManager.open) {
                searchInput.text = ""
                listView.currentIndex = 0
                Qt.callLater(() => searchInput.forceActiveFocus())
            }
        }
    }

    // Scrim Dimming Background
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#99000000"
        opacity: ClipboardManager.open ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ClipboardManager.closePicker()
        }
    }

    // Center Card Modal
    Rectangle {
        id: modal
        anchors.centerIn: parent
        width: 540
        height: 520
        radius: 20
        color: Theme.surface_container_high
        border.color: Theme.outline_variant
        border.width: 1

        opacity: ClipboardManager.open ? 1.0 : 0.0
        scale: ClipboardManager.open ? 1.0 : 0.94
        transformOrigin: Item.Center

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Header Bar
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰅌 Clipboard History"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                    color: Theme.on_surface
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 76
                    height: 28
                    radius: 8
                    color: clearMouse.containsMouse ? Theme.error_container : Theme.surface_container
                    border.color: clearMouse.containsMouse ? Theme.error : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: clearMouse.containsMouse ? Theme.on_error_container : Theme.secondary_fixed_dim
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ClipboardManager.clearAll()
                    }
                }
            }

            // Search Input Box
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 12
                color: Theme.surface_container
                border.color: searchInput.activeFocus ? Theme.primary : Theme.outline_variant
                border.width: 1.5

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        color: Theme.secondary_fixed_dim
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.on_surface
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Type to search clipboard..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.outline
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }

                        Keys.onDownPressed: (event) => {
                            if (listView.count > 0) {
                                listView.currentIndex = (listView.currentIndex + 1) % listView.count
                                listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                            }
                            event.accepted = true
                        }

                        Keys.onUpPressed: (event) => {
                            if (listView.count > 0) {
                                listView.currentIndex = (listView.currentIndex - 1 + listView.count) % listView.count
                                listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                            }
                            event.accepted = true
                        }

                        Keys.onReturnPressed: (event) => {
                            if (root.filteredItems.length > 0 && listView.currentIndex >= 0 && listView.currentIndex < root.filteredItems.length) {
                                ClipboardManager.copyItem(root.filteredItems[listView.currentIndex].id)
                            }
                            event.accepted = true
                        }

                        Keys.onEscapePressed: (event) => {
                            ClipboardManager.closePicker()
                            event.accepted = true
                        }
                    }
                }
            }

            // List of Clipboard Items
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    clip: true
                    spacing: 6
                    model: root.filteredItems

                    delegate: Rectangle {
                        id: itemCard
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: listView.currentIndex === index
                        readonly property bool isHovered: itemMouse.containsMouse

                        width: listView.width
                        height: 58
                        radius: 12

                        color: (isSelected || isHovered) ? Theme.surface_container_highest : Theme.surface_container
                        border.color: isSelected ? Theme.primary : "transparent"
                        border.width: 1.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Text Content and Meta
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: itemCard.modelData.preview || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.on_surface
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Row {
                                    spacing: 8
                                    Text {
                                        text: itemCard.modelData.time || ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.secondary_fixed_dim
                                    }
                                    Text {
                                        text: "•"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.outline
                                    }
                                    Text {
                                        text: `${itemCard.modelData.chars || 0} chars`
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.secondary_fixed_dim
                                    }
                                }
                            }

                            // Delete Action Button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 6
                                color: delMouse.containsMouse ? Theme.error_container : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: delMouse.containsMouse ? Theme.error : Theme.outline
                                }

                                MouseArea {
                                    id: delMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClipboardManager.deleteItem(itemCard.modelData.id)
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            anchors.rightMargin: 36 // leave space for delete button
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardManager.copyItem(itemCard.modelData.id)
                            onEntered: listView.currentIndex = itemCard.index
                        }
                    }

                    // Empty State
                    Text {
                        anchors.centerIn: parent
                        text: "Clipboard is empty"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.outline
                        visible: listView.count === 0
                    }
                }
            }

            // Bottom Footer
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: `${root.filteredItems.length} items`
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.secondary_fixed_dim
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "↑↓ Navigate • Enter Copy • Esc Close"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.outline
                }
            }
        }
    }
}
