import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../components"

Rectangle {
    id: root
    height: 26
    radius: 13
    color: Theme.surface_container
    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
    border.width: 1
    implicitWidth: dotRow.implicitWidth + 24

    property var workspaces: [1, 2, 3, 4, 5]
    property int activeId: 1
    property var windowCounts: ({})

    Process {
        id: wpProc
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onDataChanged: {
                try {
                    let list = JSON.parse(text)
                    let counts = {}
                    let ids = []
                    for (let i = 0; i < list.length; i++) {
                        let w = list[i]
                        if (w.id > 0) {
                            ids.push(w.id)
                            counts[w.id] = w.windows
                        }
                    }
                    root.windowCounts = counts

                    let base = [1, 2, 3, 4, 5]
                    let combined = base.concat(ids)
                    if (root.activeId > 0 && !combined.includes(root.activeId)) {
                        combined.push(root.activeId)
                    }
                    let unique = []
                    for (let i = 0; i < combined.length; i++) {
                        if (!unique.includes(combined[i])) {
                            unique.push(combined[i])
                        }
                    }
                    unique.sort((a, b) => a - b)
                    root.workspaces = unique
                } catch(e) {}
            }
        }
    }

    Process {
        id: activeProc
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            onDataChanged: {
                try {
                    let obj = JSON.parse(text)
                    if (obj.id > 0) {
                        root.activeId = obj.id
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wpProc.running = true
            activeProc.running = true
        }
    }

    // Scroll wheel on workspace widget to switch workspaces
    MouseArea {
        anchors.fill: parent
        z: -1
        onWheel: (wheel) => {
            if (wheel.angleDelta.y < 0) {
                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e+1"])
            } else if (wheel.angleDelta.y > 0) {
                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e-1"])
            }
            activeProc.running = true
            wpProc.running = true
        }
    }

    Row {
        id: dotRow
        anchors.centerIn: parent
        spacing: 9

        Repeater {
            model: root.workspaces
            delegate: Item {
                id: dotDelegate
                width: 14
                height: 26

                property bool isActive: modelData === root.activeId
                property int winCount: (root.windowCounts && root.windowCounts[modelData] !== undefined) ? root.windowCounts[modelData] : 0
                property bool hasWindows: winCount > 0
                property bool isHovered: dotMouse.containsMouse

                // Ambient glow indicator for active or hovered workspace dot
                Rectangle {
                    anchors.centerIn: parent
                    width: dotDelegate.isActive ? 20 : (dotDelegate.isHovered ? 15 : 0)
                    height: width
                    radius: width / 2
                    color: Theme.primary
                    opacity: dotDelegate.isActive ? 0.35 : (dotDelegate.isHovered ? 0.2 : 0.0)

                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }
                }

                // Minimalist circular workspace indicator
                Rectangle {
                    id: dot
                    anchors.centerIn: parent

                    // Dot diameter dimensions:
                    // Active: 10px
                    // Hovered: 8px
                    // Occupied (contains windows): 7px
                    // Empty: 5px
                    width: {
                        if (dotDelegate.isActive) return 10;
                        if (dotDelegate.isHovered) return 8;
                        if (dotDelegate.hasWindows) return 7;
                        return 5;
                    }
                    height: width
                    radius: width / 2

                    // Dot color mapping:
                    // Active: Theme.primary
                    // Hovered: Theme.secondary_fixed_dim
                    // Occupied: Theme.on_surface_variant
                    // Empty: Theme.outline_variant (semi-transparent)
                    color: {
                        if (dotDelegate.isActive) return Theme.primary;
                        if (dotDelegate.isHovered) return Theme.secondary_fixed_dim;
                        if (dotDelegate.hasWindows) return Theme.on_surface_variant;
                        return Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.45);
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 160 }
                    }
                }

                MouseArea {
                    id: dotMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activeId = modelData
                        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", modelData.toString()])
                        activeProc.running = true
                        wpProc.running = true
                    }
                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y < 0) {
                            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e+1"])
                        } else if (wheel.angleDelta.y > 0) {
                            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e-1"])
                        }
                        activeProc.running = true
                        wpProc.running = true
                    }
                }
            }
        }
    }
}
