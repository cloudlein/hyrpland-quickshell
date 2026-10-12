import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    property int barCount: 20
    property var bars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    implicitWidth: barRow.implicitWidth
    implicitHeight: 28

    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/cava.conf"]
        running: true
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

    Row {
        id: barRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.bars
            Rectangle {
                required property int modelData
                width: 3
                height: Math.max(2, Math.min(13, (modelData / 10) * 13))
                radius: 1.5
                color: modelData > 0 ? Theme.primary : Theme.outline_variant
                anchors.verticalCenter: parent.verticalCenter
                Behavior on height { NumberAnimation { duration: 35 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }
}
