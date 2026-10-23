import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root
    height: 28
    radius: 12
    color: Theme.surface_container
    implicitWidth: contentRow.implicitWidth + 24

    property string timeText: "00:00"
    property string dateBadge: "Jum, 9"
    property string clockTooltip: ""
    property string weatherText: "Weather --°"
    property string weatherTooltip: "Cuaca"

    function updateClock() {
        let now = new Date()
        let days = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
        let dayName = days[now.getDay()]
        let dateNum = now.getDate()
        root.dateBadge = `${dayName}, ${dateNum}`
        let h = String(now.getHours()).padStart(2, '0')
        let m = String(now.getMinutes()).padStart(2, '0')
        root.timeText = `${h}:${m}`
        root.clockTooltip = Qt.formatDate(now, "dddd, d MMMM yyyy")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateClock()
    }

    Process {
        id: weatherProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data)
                    root.weatherText = obj.text || "Weather"
                    root.weatherTooltip = obj.tooltip || ""
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

    Row {
        id: contentRow
        anchors.centerIn: parent
        height: 28
        spacing: 11

        // Clock: Minimalist layout with time and date chip
        Item {
            implicitWidth: clockRow.implicitWidth
            height: 28

            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 6

                // Clock Icon
                Text {
                    text: "󰥔"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Time (HH:MM)
                Text {
                    text: root.timeText
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.on_surface
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Subtle separator dot
                Text {
                    text: "•"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    color: Theme.outline_variant
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Formatted date indicator chip
                Rectangle {
                    height: 18
                    radius: 6
                    color: Theme.surface_container_high
                    implicitWidth: dateText.implicitWidth + 10
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: dateText
                        anchors.centerIn: parent
                        text: root.dateBadge
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.secondary_fixed_dim
                    }
                }
            }
        }

        // Divider
        Text {
            height: 28
            verticalAlignment: Text.AlignVCenter
            text: "|"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.outline_variant
        }

        // Weather (Cuaca)
        Item {
            implicitWidth: weatherLabel.implicitWidth
            height: 28

            Text {
                id: weatherLabel
                anchors.centerIn: parent
                text: root.weatherText
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.on_surface
            }

            MouseArea {
                id: weatherMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["xdg-open", "https://wttr.in"])
            }
        }
    }
}
