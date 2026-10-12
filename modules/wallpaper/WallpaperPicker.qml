import QtQuick
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
    visible: WallpaperManager.pickerOpen || anim.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper-picker"
    WlrLayershell.keyboardFocus: WallpaperManager.pickerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        active: WallpaperManager.pickerOpen
        windows: [root]
        onCleared: WallpaperManager.cancelPicker()
    }

    Connections {
        target: WallpaperManager
        function onPickerOpenChanged() {
            if (WallpaperManager.pickerOpen) {
                anim.start()
                Qt.callLater(() => {
                    keyHandler.forceActiveFocus()
                    if (pathView) {
                        pathView.currentIndex = WallpaperManager.currentIndex
                    }
                })
            }
        }
    }

    // ==========================================
    // KEYBOARD INPUT HANDLER (Pure Keyboard)
    // ==========================================
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onUpPressed: (event) => {
            if (pathView) pathView.decrementCurrentIndex()
            event.accepted = true
        }

        Keys.onLeftPressed: (event) => {
            if (pathView) pathView.decrementCurrentIndex()
            event.accepted = true
        }

        Keys.onDownPressed: (event) => {
            if (pathView) pathView.incrementCurrentIndex()
            event.accepted = true
        }

        Keys.onRightPressed: (event) => {
            if (pathView) pathView.incrementCurrentIndex()
            event.accepted = true
        }

        Keys.onReturnPressed: (event) => {
            WallpaperManager.applyCurrent()
            event.accepted = true
        }

        Keys.onEnterPressed: (event) => {
            WallpaperManager.applyCurrent()
            event.accepted = true
        }

        Keys.onEscapePressed: (event) => {
            WallpaperManager.cancelPicker()
            event.accepted = true
        }
    }

    // ==========================================
    // FLOATING CURVED ARC CAROUSEL (100% Transparent Background)
    // ==========================================
    Item {
        id: contentContainer
        anchors.fill: parent

        opacity: WallpaperManager.pickerOpen ? 1.0 : 0.0
        scale: WallpaperManager.pickerOpen ? 1.0 : 0.97

        ParallelAnimation {
            id: anim
            NumberAnimation {
                target: contentContainer
                property: "opacity"
                from: WallpaperManager.pickerOpen ? 0.0 : 1.0
                to: WallpaperManager.pickerOpen ? 1.0 : 0.0
                duration: 150
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: contentContainer
                property: "scale"
                from: WallpaperManager.pickerOpen ? 0.97 : 1.0
                to: WallpaperManager.pickerOpen ? 1.0 : 0.97
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        PathView {
            id: pathView
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(840, parent.width * 0.58)
            height: parent.height

            model: WallpaperManager.wallpapers
            pathItemCount: 9
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 200
            interactive: false

            currentIndex: WallpaperManager.currentIndex
            onCurrentIndexChanged: {
                WallpaperManager.currentIndex = currentIndex
            }

            delegate: Item {
                id: cardItem
                required property var modelData
                required property int index

                width: 165
                height: 255
                scale: PathView.itemScale !== undefined ? PathView.itemScale : 1.0
                opacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 1.0
                z: PathView.itemZ !== undefined ? Math.round(PathView.itemZ) : 1

                readonly property bool isCurrent: PathView.isCurrentItem

                // Clean Wallpaper Thumbnail Card
                Rectangle {
                    id: cardBox
                    anchors.fill: parent
                    radius: 16
                    color: Theme.surface_container_high
                    border.color: cardItem.isCurrent ? Theme.primary : Qt.rgba(1, 1, 1, 0.12)
                    border.width: cardItem.isCurrent ? 2.0 : 1.0
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: modelData.path ? "file://" + modelData.path : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 340
                        sourceSize.height: 520
                    }
                }
            }

            // Parametric Arc Bezier Path (C-shape curved towards right apex)
            path: Path {
                startX: 120
                startY: pathView.height * 0.10

                PathAttribute { name: "itemScale"; value: 0.55 }
                PathAttribute { name: "itemOpacity"; value: 0.25 }
                PathAttribute { name: "itemZ"; value: 1 }

                PathCubic {
                    x: pathView.width * 0.65
                    y: pathView.height * 0.50
                    control1X: 180
                    control1Y: pathView.height * 0.26
                    control2X: pathView.width * 0.54
                    control2Y: pathView.height * 0.38
                }
                PathAttribute { name: "itemScale"; value: 1.32 }
                PathAttribute { name: "itemOpacity"; value: 1.0 }
                PathAttribute { name: "itemZ"; value: 50 }

                PathCubic {
                    x: 120
                    y: pathView.height * 0.90
                    control1X: pathView.width * 0.54
                    control1Y: pathView.height * 0.62
                    control2X: 180
                    control2Y: pathView.height * 0.74
                }
                PathAttribute { name: "itemScale"; value: 0.55 }
                PathAttribute { name: "itemOpacity"; value: 0.25 }
                PathAttribute { name: "itemZ"; value: 1 }
            }
        }
    }
}
