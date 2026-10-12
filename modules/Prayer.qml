import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../components"

Pill {
    id: root
    text: "Prayer --:--"
    tooltipText: "Jadwal Sholat"

    Process {
        id: prayerProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/prayer.sh"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data)
                    root.text = obj.text || "Prayer"
                    root.tooltipText = obj.tooltip || ""
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: prayerProc.running = true
    }

    onClicked: Quickshell.execDetached(["xdg-open", "https://www.jadwalsholat.org/adzan/monthly.php?kotaId=419"])
}
