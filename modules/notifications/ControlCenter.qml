import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../.."

PanelWindow {
    id: root

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: 12
        right: 12
        bottom: 42
    }

    implicitWidth: 420
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control-center"
    WlrLayershell.exclusiveZone: 0

    visible: NotificationManager.controlCenterOpen || slideAnim.running

    onVisibleChanged: {
        if (visible && NotificationManager.controlCenterOpen) {
            slideAnim.start()
        }
    }

    ParallelAnimation {
        id: slideAnim
        NumberAnimation {
            target: panelCard
            property: "opacity"
            from: NotificationManager.controlCenterOpen ? 0.0 : 1.0
            to: NotificationManager.controlCenterOpen ? 1.0 : 0.0
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: panelTranslate
            property: "x"
            from: NotificationManager.controlCenterOpen ? 40 : 0
            to: NotificationManager.controlCenterOpen ? 0 : 40
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: panelCard
        anchors.fill: parent
        radius: 20
        color: Theme.surface_container_high
        border.color: Theme.outline_variant
        border.width: 1
        clip: true

        transform: Translate { id: panelTranslate; x: 0 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // ==========================================
            // 1. TOP HEADER
            // ==========================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Title Icon & Text
                Row {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: "󰂚"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Control Center"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.on_surface
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Count Badge
                    Rectangle {
                        visible: NotificationManager.unreadCount > 0
                        width: Math.max(18, countText.implicitWidth + 8)
                        height: 18
                        radius: 9
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: "" + NotificationManager.unreadCount
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.on_primary
                        }
                    }
                }

                // DND Toggle Button
                Rectangle {
                    height: 28
                    radius: 14
                    implicitWidth: dndRow.implicitWidth + 16
                    color: NotificationManager.dnd ? Theme.primary : Theme.surface_container
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        id: dndRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: NotificationManager.dnd ? "󰂛" : "󰂚"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: NotificationManager.dnd ? Theme.on_primary : Theme.primary
                        }

                        Text {
                            text: "DND"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: NotificationManager.dnd ? Theme.on_primary : Theme.on_surface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.toggleDnd()
                    }
                }

                // Clear All Button
                Rectangle {
                    height: 28
                    radius: 14
                    implicitWidth: clearRow.implicitWidth + 14
                    color: clearMouse.containsMouse ? Theme.surface_container : Theme.surface_container
                    opacity: NotificationManager.unreadCount > 0 ? 1.0 : 0.4
                    border.color: Theme.outline_variant
                    border.width: 1

                    Row {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰃢"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.outline
                        }

                        Text {
                            text: "Clear"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.on_surface
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        enabled: NotificationManager.unreadCount > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.clearAll()
                    }
                }

                // Close Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeHover.containsMouse ? Theme.surface_container : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: closeHover.containsMouse ? Theme.error : Theme.outline
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.closeControlCenter()
                    }
                }
            }

            // ==========================================
            // 2. QUICK SETTINGS GRID (2x2)
            // ==========================================
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                // Tile 1: Wi-Fi
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 14
                    color: NotificationManager.wifiEnabled ? Theme.primary : Theme.surface_container
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: NotificationManager.wifiEnabled ? "󰤨" : "󰤭"
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                            color: NotificationManager.wifiEnabled ? Theme.on_primary : Theme.primary
                        }

                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "Wi-Fi"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: NotificationManager.wifiEnabled ? Theme.on_primary : Theme.on_surface
                            }
                            Text {
                                text: NotificationManager.wifiEnabled ? (NotificationManager.wifiSsid || "Connected") : "Disabled"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: NotificationManager.wifiEnabled ? Theme.on_primary : Theme.on_surface_variant
                                elide: Text.ElideRight
                                width: 120
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.toggleWifi()
                    }
                }

                // Tile 2: Bluetooth
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 14
                    color: NotificationManager.bluetoothEnabled ? Theme.primary : Theme.surface_container
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: NotificationManager.bluetoothEnabled ? "󰂯" : "󰂲"
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                            color: NotificationManager.bluetoothEnabled ? Theme.on_primary : Theme.primary
                        }

                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "Bluetooth"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: NotificationManager.bluetoothEnabled ? Theme.on_primary : Theme.on_surface
                            }
                            Text {
                                text: NotificationManager.bluetoothEnabled ? "Enabled" : "Disabled"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: NotificationManager.bluetoothEnabled ? Theme.on_primary : Theme.on_surface_variant
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.toggleBluetooth()
                    }
                }

                // Tile 3: Audio Mute
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 14
                    color: NotificationManager.isMuted ? Theme.primary : Theme.surface_container
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: NotificationManager.isMuted ? "󰝟" : "󰕾"
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                            color: NotificationManager.isMuted ? Theme.on_primary : Theme.primary
                        }

                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "Audio Output"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: NotificationManager.isMuted ? Theme.on_primary : Theme.on_surface
                            }
                            Text {
                                text: NotificationManager.isMuted ? "Muted" : `${NotificationManager.volume}%`
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: NotificationManager.isMuted ? Theme.on_primary : Theme.on_surface_variant
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.toggleMute()
                    }
                }

                // Tile 4: Mic Mute
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 14
                    color: NotificationManager.isMicMuted ? Theme.primary : Theme.surface_container
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: NotificationManager.isMicMuted ? "󰍭" : "󰍬"
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                            color: NotificationManager.isMicMuted ? Theme.on_primary : Theme.primary
                        }

                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "Microphone"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: NotificationManager.isMicMuted ? Theme.on_primary : Theme.on_surface
                            }
                            Text {
                                text: NotificationManager.isMicMuted ? "Muted" : "Active"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: NotificationManager.isMicMuted ? Theme.on_primary : Theme.on_surface_variant
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.toggleMicMute()
                    }
                }
            }

            // ==========================================
            // 3. VOLUME SLIDER
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 14
                color: Theme.surface_container
                border.color: Theme.outline_variant
                border.width: 1
                clip: true

                // Progress Fill
                Rectangle {
                    height: parent.height
                    width: parent.width * (NotificationManager.volume / 100.0)
                    radius: 14
                    color: Theme.primary
                    opacity: NotificationManager.isMuted ? 0.35 : 0.65

                    Behavior on width { NumberAnimation { duration: 90 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text {
                        text: NotificationManager.isMuted ? "󰝟" : (NotificationManager.volume > 50 ? "󰕾" : "󰖀")
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.on_surface
                    }

                    Text {
                        text: "Volume"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.on_surface
                        Layout.fillWidth: true
                    }

                    Text {
                        text: `${NotificationManager.volume}%`
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function updateVolume(mouse) {
                        let pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                        NotificationManager.setVolume(pct)
                    }

                    onClicked: mouse => updateVolume(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) updateVolume(mouse)
                    }
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0) NotificationManager.setVolume(NotificationManager.volume + 5)
                        else if (wheel.angleDelta.y < 0) NotificationManager.setVolume(NotificationManager.volume - 5)
                    }
                }
            }

            // ==========================================
            // 4. MEDIA PLAYER (MPRIS)
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                height: 64
                radius: 14
                color: Theme.surface_container
                border.color: Theme.outline_variant
                border.width: 1
                clip: true

                property var activePlayer: (Mpris.players && Mpris.players.values.length > 0) ? Mpris.players.values[0] : null

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Album Art / Icon
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 8
                        color: Theme.surface_container_high
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: status === Image.Ready
                            source: parent.parent.parent.activePlayer ? (parent.parent.parent.activePlayer.trackArtUrl || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            mipmap: true
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !parent.parent.parent.activePlayer || !parent.parent.parent.activePlayer.trackArtUrl
                            text: ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            color: Theme.primary
                        }
                    }

                    // Track & Artist Info
                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: parent.parent.parent.activePlayer ? (parent.parent.parent.activePlayer.trackTitle || "Media Player") : "No Media Playing"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.on_surface
                            elide: Text.ElideRight
                            width: 190
                        }

                        Text {
                            text: parent.parent.parent.activePlayer ? (parent.parent.parent.activePlayer.trackArtist || parent.parent.parent.activePlayer.identity || "Idle") : "Spotify / YouTube"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.on_surface_variant
                            elide: Text.ElideRight
                            width: 190
                        }
                    }

                    // Playback Controls
                    Row {
                        spacing: 4
                        visible: parent.activePlayer !== null

                        // Prev
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: prevM.containsMouse ? Theme.surface_container_high : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_surface
                            }

                            MouseArea {
                                id: prevM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (parent.parent.parent.parent.activePlayer) {
                                        try { parent.parent.parent.parent.activePlayer.previous() } catch(e) {}
                                    }
                                }
                            }
                        }

                        // Play/Pause
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: Theme.primary

                            Text {
                                anchors.centerIn: parent
                                text: (parent.parent.parent.parent.activePlayer && parent.parent.parent.parent.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.on_primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (parent.parent.parent.parent.activePlayer) {
                                        try { parent.parent.parent.parent.activePlayer.togglePlaying() } catch(e) {}
                                    }
                                }
                            }
                        }

                        // Next
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: nextM.containsMouse ? Theme.surface_container_high : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_surface
                            }

                            MouseArea {
                                id: nextM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (parent.parent.parent.parent.activePlayer) {
                                        try { parent.parent.parent.parent.activePlayer.next() } catch(e) {}
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // 5. NOTIFICATION HISTORY LIST
            // ==========================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                Text {
                    text: `${NotificationManager.unreadCount} total`
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.outline
                }
            }

            // History Container
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: "transparent"
                clip: true

                // Empty State
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: NotificationManager.unreadCount === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂚"
                        font.family: Theme.fontFamily
                        font.pixelSize: 42
                        color: Theme.outline_variant
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No Notifications"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.on_surface_variant
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "You are all caught up!"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.outline
                    }
                }

                // Notifications ListView
                ListView {
                    id: historyList
                    anchors.fill: parent
                    visible: NotificationManager.unreadCount > 0
                    spacing: 8
                    clip: true
                    model: NotificationManager.server.trackedNotifications ? NotificationManager.server.trackedNotifications.values : []
                    delegate: NotificationCard {
                        required property var modelData
                        notifData: modelData
                    }
                }
            }
        }
    }
}
