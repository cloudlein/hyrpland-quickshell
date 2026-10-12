import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../components"

Pill {
    id: root
    text: "Weather --°"
    tooltipText: "Cuaca"

    Process {
        id: weatherProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data)
                    root.text = obj.text || "Weather"
                    root.tooltipText = obj.tooltip || ""
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    onClicked: Quickshell.execDetached(["xdg-open", "https://wttr.in"])
}
