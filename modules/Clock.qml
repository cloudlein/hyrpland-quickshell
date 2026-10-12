import QtQuick
import ".."
import "../components"

Pill {
    id: root
    textColor: Theme.secondary_fixed_dim

    function updateTime() {
        let now = new Date()
        let h = String(now.getHours()).padStart(2, '0')
        let m = String(now.getMinutes()).padStart(2, '0')
        root.text = `< ${h}:${m} >`
        root.tooltipText = Qt.formatDate(now, "dddd, d MMMM yyyy")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }
}
