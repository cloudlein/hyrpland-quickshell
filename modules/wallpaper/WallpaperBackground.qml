import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

Scope {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: win
            required property var modelData

            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-wallpaper"

            color: "#050505"

            Item {
                id: container
                anchors.fill: parent

                // 1. Static Wallpaper (displayed when NOT transitioning)
                Image {
                    id: staticImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: WallpaperManager.sourceWallpaper ? ("file://" + WallpaperManager.sourceWallpaper) : ""
                    asynchronous: true
                    cache: true
                    visible: !WallpaperManager.isTransitioning
                }

                // 2. Animated GPU Transition Container (active during transition)
                Item {
                    id: transContainer
                    anchors.fill: parent
                    visible: WallpaperManager.isTransitioning

                    Image {
                        id: imgSource
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: WallpaperManager.sourceWallpaper ? ("file://" + WallpaperManager.sourceWallpaper) : ""
                        visible: true
                    }

                    Image {
                        id: imgTarget
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: WallpaperManager.targetWallpaper ? ("file://" + WallpaperManager.targetWallpaper) : ""
                        visible: true
                    }

                    ShaderEffectSource {
                        id: srcSource
                        sourceItem: imgSource
                        hideSource: true
                        live: true
                    }

                    ShaderEffectSource {
                        id: srcTarget
                        sourceItem: imgTarget
                        hideSource: true
                        live: true
                    }

                    ShaderEffect {
                        id: shader
                        anchors.fill: parent
                        property variant source: srcSource
                        property variant target: srcTarget
                        property real progress: WallpaperManager.transitionProgress
                        property int transitionType: WallpaperManager.currentTransitionType
                        property vector2d resolution: Qt.vector2d(win.width, win.height)

                        fragmentShader: Qt.resolvedUrl("transition.frag.qsb")
                    }
                }
            }
        }
    }
}
