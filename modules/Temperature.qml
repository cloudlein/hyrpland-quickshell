import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../components"

Pill {
    id: root
    text: "CPU --°"
    tooltipText: "Sensors"

    Process {
        id: tempProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/temperature.sh", "text"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data)
                    root.text = obj.text || "CPU --°"
                    root.tooltipText = obj.tooltip || ""
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: tempProc.running = true
    }

    onClicked: Quickshell.execDetached(["kitty", "-e", "htop"])
}
