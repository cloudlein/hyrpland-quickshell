import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../components"

Pill {
    id: root
    text: "00:00"
    tooltipText: "Timer"

    Process {
        id: timerProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/timer.sh"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data)
                    root.text = obj.text || "00:00"
                    root.tooltipText = obj.tooltip || ""
                    root.active = (obj.class && obj.class === "active")
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: timerProc.running = true
    }

    onClicked: {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/timer-cancel.sh"])
    }
}
