import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    property int barCount: 140
    property var bars: []

    Component.onCompleted: {
        let arr = []
        for (let i = 0; i < root.barCount; i++) arr.push(0)
        root.bars = arr
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/cava.conf"]
        running: true
        onExited: (exitCode, exitStatus) => {
            let arr = []
            for (let i = 0; i < root.barCount; i++) arr.push(0)
            root.bars = arr
            restartTimer.start()
        }
        stdout: SplitParser {
            onRead: data => {
                let str = data.trim()
                if (!str) return
                let parts = str.split(";")
                let vals = []
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i].length > 0) {
                        let n = parseInt(parts[i])
                        if (!isNaN(n)) vals.push(n)
                    }
                }
                if (vals.length === root.barCount) root.bars = vals
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        repeat: false
        onTriggered: cavaProc.running = true
    }

    // Watchdog
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!cavaProc.running) {
                cavaProc.running = true
            }
        }
    }

    Row {
        id: barRow
        anchors.fill: parent
        spacing: Math.max(1, (parent.width - (root.barCount * 4)) / Math.max(1, root.barCount - 1))

        Repeater {
            model: root.bars
            Item {
                required property int modelData
                width: 4
                height: barRow.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 3.2
                    // Visualizer bar lebih responsif dan tinggi
                    height: Math.max(2.5, Math.min(barRow.height, (Math.pow(modelData / 100.0, 0.85)) * barRow.height))
                    radius: 1.6
                    color: modelData > 0 ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.35)
                    opacity: modelData > 0 ? 1.0 : 0.25

                    Behavior on height { NumberAnimation { duration: 35; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }
            }
        }
    }
}
