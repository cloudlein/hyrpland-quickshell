import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: root
    height: 28
    radius: 12
    color: Theme.surface_container
    implicitWidth: contentRow.implicitWidth + 20

    property int trackWidth: 200

    // Select actively playing player, or the first available player
    readonly property MprisPlayer activePlayer: {
        let list = Mpris.players.values
        if (!list || list.length === 0) return null
        for (let i = 0; i < list.length; i++) {
            let p = list[i]
            if (p && p.playbackState === MprisPlaybackState.Playing) return p
        }
        return list[0]
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string trackTitle: (hasPlayer && activePlayer.trackTitle) ? activePlayer.trackTitle : ""
    readonly property string trackArtist: (hasPlayer && activePlayer.trackArtist) ? activePlayer.trackArtist : ""

    readonly property string playerIcon: {
        if (!hasPlayer) return ""
        let idName = (activePlayer.identity || "").toLowerCase()
        if (idName.includes("spotify")) return ""
        if (idName.includes("brave") || idName.includes("chrome") || idName.includes("firefox")) return "󰖟"
        return "󰝚"
    }

    readonly property string displayText: {
        if (!hasPlayer || (!trackTitle && !trackArtist)) {
            return " No Music"
        }
        if (trackArtist && trackTitle) {
            return playerIcon + " " + trackArtist + " - " + trackTitle
        }
        return playerIcon + " " + (trackTitle || trackArtist)
    }

    readonly property string tooltipText: {
        if (!hasPlayer) return "Music Player (Inactive)"
        let status = isPlaying ? "Playing" : "Paused"
        let player = activePlayer.identity || "Media Player"
        return `${player} (${status}): ${displayText}`
    }

    MouseArea {
        id: mainMouse
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            if (!root.activePlayer) return
            if (wheel.angleDelta.y > 0) {
                root.activePlayer.next()
            } else if (wheel.angleDelta.y < 0) {
                root.activePlayer.previous()
            }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        height: 28
        spacing: 7

        // Track Info with fixed width and marquee scrolling for long titles
        Item {
            id: trackContainer
            width: root.trackWidth
            implicitWidth: root.trackWidth
            height: 28
            clip: true

            readonly property bool needsScroll: trackLabel.implicitWidth > width

            Text {
                id: trackLabel
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayText
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: root.isPlaying ? Theme.on_surface : Theme.secondary_fixed_dim

                SequentialAnimation {
                    id: marqueeAnim
                    running: trackContainer.needsScroll && root.isPlaying
                    loops: Animation.Infinite

                    PauseAnimation { duration: 2000 }

                    NumberAnimation {
                        target: trackLabel
                        property: "x"
                        from: 0
                        to: -(trackLabel.implicitWidth - trackContainer.width + 10)
                        duration: Math.max(1600, (trackLabel.implicitWidth - trackContainer.width) * 32)
                        easing.type: Easing.InOutQuad
                    }

                    PauseAnimation { duration: 2000 }

                    NumberAnimation {
                        target: trackLabel
                        property: "x"
                        from: -(trackLabel.implicitWidth - trackContainer.width + 10)
                        to: 0
                        duration: Math.max(1600, (trackLabel.implicitWidth - trackContainer.width) * 32)
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Connections {
                target: root
                function onDisplayTextChanged() {
                    trackLabel.x = 0
                    if (marqueeAnim.running) {
                        marqueeAnim.restart()
                    }
                }
                function onIsPlayingChanged() {
                    if (!root.isPlaying) {
                        trackLabel.x = 0
                    }
                }
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer) {
                        root.activePlayer.playPause()
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

        // Nav Buttons: Previous | Play/Pause | Next
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            // Previous Button
            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: prevMouse.pressed ? Theme.surface_container_high : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: prevMouse.pressed ? Theme.primary : Theme.secondary_fixed_dim
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer) {
                            root.activePlayer.previous()
                        }
                    }
                }
            }

            // Play / Pause Button
            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: playMouse.pressed ? Theme.surface_container_high : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: root.isPlaying ? Theme.primary : Theme.secondary_fixed_dim
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer) {
                            root.activePlayer.playPause()
                        }
                    }
                }
            }

            // Next Button
            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: nextMouse.pressed ? Theme.surface_container_high : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: nextMouse.pressed ? Theme.primary : Theme.secondary_fixed_dim
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer) {
                            root.activePlayer.next()
                        }
                    }
                }
            }
        }
    }
}
