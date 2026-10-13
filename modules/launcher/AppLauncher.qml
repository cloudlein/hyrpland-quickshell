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
    visible: LauncherManager.launcherOpen || cardAnim.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-app-launcher"
    WlrLayershell.keyboardFocus: LauncherManager.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        active: LauncherManager.launcherOpen
        windows: [root]
        onCleared: LauncherManager.closeLauncher()
    }

    Connections {
        target: LauncherManager
        function onLauncherOpenChanged() {
            if (LauncherManager.launcherOpen) {
                searchInput.text = ""
                cardAnim.start()
                Qt.callLater(() => {
                    searchInput.forceActiveFocus()
                    if (appList) {
                        appList.positionViewAtBeginning()
                    }
                })
            }
        }
    }


    // ==========================================
    // AMBIENT GLOW BEHIND CARD
    // ==========================================
    Rectangle {
        anchors.centerIn: card
        width: card.width + 10
        height: card.height + 10
        radius: 26
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        opacity: card.opacity
        scale: card.scale
        visible: card.visible
    }

    // ==========================================
    // MINIMALIST KEYBOARD-ONLY CARD
    // ==========================================
    Rectangle {
        id: card
        width: 640
        height: 480
        anchors.centerIn: parent

        radius: 22
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.95)
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
        border.width: 1.5
        clip: true

        opacity: LauncherManager.launcherOpen ? 1.0 : 0.0
        scale: LauncherManager.launcherOpen ? 1.0 : 0.95

        ParallelAnimation {
            id: cardAnim
            NumberAnimation {
                target: card
                property: "opacity"
                from: LauncherManager.launcherOpen ? 0.0 : 1.0
                to: LauncherManager.launcherOpen ? 1.0 : 0.0
                duration: 150
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: card
                property: "scale"
                from: LauncherManager.launcherOpen ? 0.95 : 1.0
                to: LauncherManager.launcherOpen ? 1.0 : 0.95
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ==========================================
            // SEARCH INPUT BAR (Pure Keyboard)
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 14
                color: Theme.surface_container
                border.color: searchInput.activeFocus ? Theme.primary : Theme.outline_variant
                border.width: searchInput.activeFocus ? 1.5 : 1

                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: ">"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.on_surface
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.on_primary
                        clip: true

                        onTextChanged: {
                            LauncherManager.searchQuery = text
                            LauncherManager.updateFilter()
                            if (appList) {
                                appList.positionViewAtBeginning()
                            }
                        }

                        Keys.onDownPressed: (event) => {
                            if (LauncherManager.filteredApps.length > 0) {
                                LauncherManager.selectedIndex = Math.min(
                                    LauncherManager.filteredApps.length - 1,
                                    LauncherManager.selectedIndex + 1
                                )
                                appList.positionViewAtIndex(LauncherManager.selectedIndex, ListView.Contain)
                            }
                            event.accepted = true
                        }

                        Keys.onUpPressed: (event) => {
                            if (LauncherManager.filteredApps.length > 0) {
                                LauncherManager.selectedIndex = Math.max(0, LauncherManager.selectedIndex - 1)
                                appList.positionViewAtIndex(LauncherManager.selectedIndex, ListView.Contain)
                            }
                            event.accepted = true
                        }

                        Keys.onTabPressed: (event) => {
                            LauncherManager.cycleCategory(true)
                            event.accepted = true
                        }

                        Keys.onBacktabPressed: (event) => {
                            LauncherManager.cycleCategory(false)
                            event.accepted = true
                        }

                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ControlModifier) {
                                LauncherManager.launchTerminal(LauncherManager.currentApp)
                            } else {
                                LauncherManager.launchIndex(LauncherManager.selectedIndex)
                            }
                            event.accepted = true
                        }

                        Keys.onEnterPressed: (event) => {
                            if (event.modifiers & Qt.ControlModifier) {
                                LauncherManager.launchTerminal(LauncherManager.currentApp)
                            } else {
                                LauncherManager.launchIndex(LauncherManager.selectedIndex)
                            }
                            event.accepted = true
                        }

                        Keys.onEscapePressed: (event) => {
                            LauncherManager.closeLauncher()
                            event.accepted = true
                        }

                        // Text Placeholder
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                            text: "Type to search..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.outline
                        }
                    }

                    // Count Badge
                    Text {
                        text: `${LauncherManager.filteredApps.length}`
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.secondary_fixed_dim
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // ==========================================
            // CATEGORY FILTER PILLS (Keyboard Driven with Tab)
            // ==========================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: LauncherManager.categoryList
                    delegate: Rectangle {
                        required property var modelData

                        property bool isCurrentCat: LauncherManager.selectedCategory === modelData.id
                        height: 26
                        radius: 8
                        color: isCurrentCat ? Theme.primary : Theme.surface_container
                        border.color: isCurrentCat ? Theme.primary : Theme.outline_variant
                        border.width: 1
                        implicitWidth: catLabel.implicitWidth + 16

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: isCurrentCat
                            color: isCurrentCat ? Theme.on_primary : Theme.on_surface
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.outline_variant
                opacity: 0.35
            }

            // ==========================================
            // APPLICATION LISTVIEW (Keyboard Only, No Scrollbar)
            // ==========================================
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    model: LauncherManager.filteredApps
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false
                    currentIndex: LauncherManager.selectedIndex

                    delegate: Rectangle {
                        id: appItem
                        required property var modelData
                        required property int index

                        width: appList.width
                        height: 48
                        radius: 12

                        property bool isSelected: index === LauncherManager.selectedIndex

                        color: isSelected
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                            : "transparent"

                        border.color: isSelected
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.45)
                            : "transparent"
                        border.width: isSelected ? 1.2 : 0

                        Behavior on color { ColorAnimation { duration: 110 } }
                        Behavior on border.color { ColorAnimation { duration: 110 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 12

                            // Left Glowing Accent Strip when selected
                            Rectangle {
                                width: 3
                                height: 20
                                radius: 1.5
                                color: Theme.primary
                                visible: appItem.isSelected
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // App Details (Name + Subtitle/Comment)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: appItem.isSelected ? Theme.primary : Theme.on_surface
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.comment || modelData.genericName || modelData.id
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: appItem.isSelected ? Theme.on_surface : Theme.on_surface_variant
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            // Category Tag (Minimal text badge)
                            Rectangle {
                                height: 20
                                radius: 6
                                color: Theme.surface_container
                                border.color: Theme.outline_variant
                                border.width: 1
                                implicitWidth: catTagText.implicitWidth + 12
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    id: catTagText
                                    anchors.centerIn: parent
                                    text: (modelData.category || "App").toUpperCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: appItem.isSelected ? Theme.primary : Theme.secondary_fixed_dim
                                }
                            }
                        }
                    }
                }

                // Empty / Command Runner Fallback
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: LauncherManager.filteredApps.length === 0
                    spacing: 10
                    width: parent.width * 0.85

                    Text {
                        text: searchInput.text.trim().length > 0
                            ? `Run command: ${searchInput.text.trim()}`
                            : "No applications found"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideMiddle
                    }

                    Rectangle {
                        visible: searchInput.text.trim().length > 0
                        height: 32
                        radius: 8
                        color: Theme.primary
                        implicitWidth: runLabel.implicitWidth + 24
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            id: runLabel
                            anchors.centerIn: parent
                            text: "Execute"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.on_primary
                        }
                    }
                }
            }
        }
    }
}
