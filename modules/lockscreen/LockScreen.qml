import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."
import "../.."

WlSessionLock {
    id: sessionLock
    locked: LockManager.locked

    onLockedChanged: {
        if (LockManager.locked !== sessionLock.locked) {
            LockManager.locked = sessionLock.locked
        }
    }

    surface: Component {
        WlSessionLockSurface {
            id: lockSurface

            Item {
                id: rootItem
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (!passwordField.activeFocus) {
                        passwordField.forceActiveFocus()
                    }
                    if (event.key === Qt.Key_Escape) {
                        passwordField.text = ""
                    }
                }

                // ── 1. Dynamic Wallpaper Background ───────────────
                Image {
                    id: wallBg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: LockManager.currentWallpaperPath ? "file://" + LockManager.currentWallpaperPath : ""
                    asynchronous: true
                    cache: false

                    // Subtle zoom-in on load
                    scale: 1.0
                    NumberAnimation on scale {
                        from: 1.06
                        to: 1.0
                        duration: 1800
                        easing.type: Easing.OutCubic
                        running: true
                    }
                }

                // ── 2. Multi-layer Scrim ───────────────────────────
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0.42
                }

                // Vignette gradient
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#55000000" }
                        GradientStop { position: 0.4; color: "#10000000" }
                        GradientStop { position: 0.6; color: "#10000000" }
                        GradientStop { position: 1.0; color: "#70000000" }
                    }
                }

                // ── 3. Ambient Glow Orbs (accent lighting) ──────────
                Item {
                    anchors.fill: parent

                    // Primary accent orb — top-left
                    Rectangle {
                        id: orb1
                        width: 420
                        height: 420
                        radius: 210
                        x: -80
                        y: parent.height * 0.05
                        opacity: 0.0
                        color: "transparent"

                        // Soft radial glow using nested rects
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            radius: parent.radius
                            color: Theme.primary
                            opacity: 0.06
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.6
                            height: parent.height * 0.6
                            radius: parent.radius
                            color: Theme.primary
                            opacity: 0.07
                        }

                        SequentialAnimation on opacity {
                            running: true
                            PauseAnimation { duration: 200 }
                            NumberAnimation { from: 0.0; to: 1.0; duration: 1400; easing.type: Easing.OutCubic }
                        }

                        SequentialAnimation on y {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: parent.height * 0.05 - 18; duration: 5000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: parent.height * 0.05 + 18; duration: 5000; easing.type: Easing.InOutSine }
                        }
                    }

                    // Secondary accent orb — bottom-right
                    Rectangle {
                        id: orb2
                        width: 360
                        height: 360
                        radius: 180
                        x: parent.width - 200
                        y: parent.height * 0.55
                        opacity: 0.0
                        color: "transparent"

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            radius: parent.radius
                            color: Theme.tertiary !== undefined ? Theme.tertiary : Theme.secondary
                            opacity: 0.07
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.5
                            height: parent.height * 0.5
                            radius: parent.radius
                            color: Theme.tertiary !== undefined ? Theme.tertiary : Theme.secondary
                            opacity: 0.08
                        }

                        SequentialAnimation on opacity {
                            running: true
                            PauseAnimation { duration: 400 }
                            NumberAnimation { from: 0.0; to: 1.0; duration: 1600; easing.type: Easing.OutCubic }
                        }

                        SequentialAnimation on y {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: parent.height * 0.55 + 22; duration: 6500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: parent.height * 0.55 - 22; duration: 6500; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // ── 4. Top Info Bar ───────────────────────────────
                Item {
                    id: topBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 60
                    anchors.margins: 24
                    opacity: 0.0
                    anchors.topMargin: 18

                    SequentialAnimation on opacity {
                        running: true
                        PauseAnimation { duration: 300 }
                        NumberAnimation { from: 0.0; to: 1.0; duration: 700; easing.type: Easing.OutCubic }
                    }

                    // Slide down from above
                    property real slideOffset: -16
                    SequentialAnimation on slideOffset {
                        running: true
                        PauseAnimation { duration: 300 }
                        NumberAnimation { from: -16; to: 0; duration: 700; easing.type: Easing.OutCubic }
                    }
                    transform: Translate { y: topBar.slideOffset }

                    // Left Host Info
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            text: ""
                            color: Theme.primary
                            font.pixelSize: 20
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "Hyprland Session"
                            color: Theme.on_surface_variant
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    // Right Lock Badge
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 32
                        radius: 16
                        color: Theme.surface_container
                        opacity: 0.90
                        border.width: 1
                        border.color: Theme.outline_variant
                        implicitWidth: lockBadgeRow.implicitWidth + 24

                        // Subtle pulse on the lock badge
                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            PauseAnimation { duration: 3000 }
                            NumberAnimation { to: 0.60; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.90; duration: 600; easing.type: Easing.InOutSine }
                        }

                        Row {
                            id: lockBadgeRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: ""
                                color: Theme.primary
                                font.pixelSize: 13
                                font.family: Theme.fontFamily
                            }

                            Text {
                                text: "Locked"
                                color: Theme.on_surface
                                font.pixelSize: 13
                                font.family: Theme.fontFamily
                            }
                        }
                    }
                }

                // ── 5. Center Hero & Login Form ───────────────────
                Column {
                    id: centerCol
                    anchors.centerIn: parent
                    spacing: 0
                    opacity: 0.0

                    SequentialAnimation on opacity {
                        running: true
                        PauseAnimation { duration: 500 }
                        NumberAnimation { from: 0.0; to: 1.0; duration: 900; easing.type: Easing.OutCubic }
                    }

                    property real slideY: 32
                    SequentialAnimation on slideY {
                        running: true
                        PauseAnimation { duration: 500 }
                        NumberAnimation { from: 32; to: 0; duration: 900; easing.type: Easing.OutCubic }
                    }
                    transform: Translate { y: centerCol.slideY }

                    // ── Big Clock with floating effect ──────────────
                    Item {
                        id: clockItem
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: clockText.implicitWidth
                        implicitHeight: clockText.implicitHeight

                        property real floatY: 0
                        SequentialAnimation on floatY {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: -8; duration: 3200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0;  duration: 3200; easing.type: Easing.InOutSine }
                        }

                        transform: Translate { y: clockItem.floatY }

                        Text {
                            id: clockText
                            text: LockManager.timeStr
                            color: "white"
                            font.pixelSize: 88
                            font.bold: true
                            font.family: Theme.fontFamily
                            style: Text.Outline
                            styleColor: "#30000000"
                        }
                    }

                    Item { width: 1; height: 6 }

                    // Date Pill — slides in slightly delayed
                    Rectangle {
                        id: datePill
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 32
                        radius: 16
                        color: Qt.rgba(1,1,1,0.08)
                        border.width: 1
                        border.color: Qt.rgba(1,1,1,0.18)
                        implicitWidth: dateText.implicitWidth + 28
                        opacity: 0.0

                        SequentialAnimation on opacity {
                            running: true
                            PauseAnimation { duration: 800 }
                            NumberAnimation { from: 0.0; to: 1.0; duration: 700; easing.type: Easing.OutCubic }
                        }

                        Text {
                            id: dateText
                            anchors.centerIn: parent
                            text: LockManager.dateStr
                            color: Qt.rgba(1,1,1,0.80)
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                        }
                    }

                    Item { width: 1; height: 44 }

                    // ── Avatar with glow ring ────────────────────────
                    Item {
                        id: avatarItem
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 90
                        height: 90
                        opacity: 0.0

                        SequentialAnimation on opacity {
                            running: true
                            PauseAnimation { duration: 950 }
                            NumberAnimation { from: 0.0; to: 1.0; duration: 700; easing.type: Easing.OutBack }
                        }

                        // Pulsing glow ring behind avatar
                        Rectangle {
                            id: glowRing
                            anchors.centerIn: parent
                            width: 90
                            height: 90
                            radius: 45
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.primary
                            opacity: 0.5

                            SequentialAnimation on border.width {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { to: 3.5; duration: 1800; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 2.0; duration: 1800; easing.type: Easing.InOutSine }
                            }
                            SequentialAnimation on opacity {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.9; duration: 1800; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.4; duration: 1800; easing.type: Easing.InOutSine }
                            }
                            SequentialAnimation on scale {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.12; duration: 1800; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0;  duration: 1800; easing.type: Easing.InOutSine }
                            }
                        }

                        // Avatar circle
                        Rectangle {
                            anchors.centerIn: parent
                            width: 80
                            height: 80
                            radius: 40
                            color: Theme.surface_container_high
                            border.width: 2.5
                            border.color: Theme.primary

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: Theme.primary
                                font.pixelSize: 36
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    Item { width: 1; height: 14 }

                    // Username
                    Text {
                        id: usernameText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: LockManager.username
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: Theme.fontFamily
                        opacity: 0.0

                        SequentialAnimation on opacity {
                            running: true
                            PauseAnimation { duration: 1050 }
                            NumberAnimation { from: 0.0; to: 1.0; duration: 600; easing.type: Easing.OutCubic }
                        }
                    }

                    Item { width: 1; height: 22 }

                    // ── Password Input Container (with shake animation) ──
                    Item {
                        id: shakeContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 320
                        height: 52
                        opacity: 0.0

                        SequentialAnimation on opacity {
                            running: true
                            PauseAnimation { duration: 1150 }
                            NumberAnimation { from: 0.0; to: 1.0; duration: 600; easing.type: Easing.OutCubic }
                        }

                        property real shakeX: 0

                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation { target: shakeContainer; property: "shakeX"; from: 0;   to: -16; duration: 45; easing.type: Easing.OutQuad }
                            NumberAnimation { target: shakeContainer; property: "shakeX"; from: -16; to: 16;  duration: 45; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: shakeContainer; property: "shakeX"; from: 16;  to: -10; duration: 45; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: shakeContainer; property: "shakeX"; from: -10; to: 10;  duration: 45; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: shakeContainer; property: "shakeX"; from: 10;  to: 0;   duration: 45; easing.type: Easing.OutQuad }
                        }

                        Connections {
                            target: LockManager
                            function onShakeTriggerChanged() {
                                passwordField.text = ""
                                shakeAnim.restart()
                                passwordField.forceActiveFocus()
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            x: shakeContainer.shakeX
                            radius: 26
                            color: Qt.rgba(1,1,1,0.08)
                            border.width: 1.5
                            border.color: LockManager.authError.length > 0
                                ? Theme.error
                                : (passwordField.activeFocus ? Theme.primary : Qt.rgba(1,1,1,0.20))

                            // Breathe border when focused
                            SequentialAnimation on border.width {
                                running: passwordField.activeFocus
                                loops: Animation.Infinite
                                NumberAnimation { to: 2.2; duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.5; duration: 1000; easing.type: Easing.InOutSine }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 8
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ""
                                    color: passwordField.activeFocus ? Theme.primary : Qt.rgba(1,1,1,0.40)
                                    font.pixelSize: 16
                                    font.family: Theme.fontFamily
                                }

                                TextField {
                                    id: passwordField
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 70
                                    height: parent.height
                                    placeholderText: "Masukkan password..."
                                    color: "white"
                                    placeholderTextColor: Qt.rgba(1,1,1,0.35)
                                    font.pixelSize: 14
                                    font.family: Theme.fontFamily
                                    echoMode: TextInput.Password
                                    background: null
                                    focus: true

                                    onAccepted: {
                                        if (text.length > 0 && !LockManager.isAuthenticating) {
                                            LockManager.submitPassword(text)
                                        }
                                    }
                                }

                                Rectangle {
                                    id: submitBtn
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 36
                                    height: 36
                                    radius: 18
                                    color: submitMouse.pressed
                                        ? Qt.rgba(1,1,1,0.25)
                                        : (passwordField.text.length > 0 ? Theme.primary : Qt.rgba(1,1,1,0.06))

                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    scale: submitMouse.pressed ? 0.92 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: LockManager.isAuthenticating ? "…" : ""
                                        color: passwordField.text.length > 0 ? Theme.on_primary : Qt.rgba(1,1,1,0.40)
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: Theme.fontFamily
                                    }

                                    MouseArea {
                                        id: submitMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (passwordField.text.length > 0 && !LockManager.isAuthenticating) {
                                                LockManager.submitPassword(passwordField.text)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 10 }

                    // Status / Error / Verifying Message
                    Text {
                        id: statusText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: LockManager.isAuthenticating ? "Memverifikasi..." : LockManager.authError
                        color: LockManager.authError.length > 0 ? Theme.error : Theme.primary
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                        visible: text.length > 0

                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        opacity: text.length > 0 ? 1.0 : 0.0
                    }
                }

                // ── 6. Bottom Bar (Media & Power Actions) ─────────
                Item {
                    id: bottomBar
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 54
                    anchors.margins: 28
                    opacity: 0.0

                    SequentialAnimation on opacity {
                        running: true
                        PauseAnimation { duration: 700 }
                        NumberAnimation { from: 0.0; to: 1.0; duration: 800; easing.type: Easing.OutCubic }
                    }

                    property real slideY: 20
                    SequentialAnimation on slideY {
                        running: true
                        PauseAnimation { duration: 700 }
                        NumberAnimation { from: 20; to: 0; duration: 800; easing.type: Easing.OutCubic }
                    }
                    transform: Translate { y: bottomBar.slideY }

                    // Bottom Left: Media Player Widget
                    Item {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: 46
                        implicitWidth: mediaCard.visible ? mediaCard.implicitWidth : hintText.implicitWidth

                        // Fallback Hint Text
                        Text {
                            id: hintText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Tekan Enter untuk membuka"
                            color: Qt.rgba(1,1,1,0.30)
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            visible: !mediaCard.visible
                        }

                        // Glassmorphic Music Card
                        Rectangle {
                            id: mediaCard
                            visible: LockManager.hasMusic && LockManager.musicTitle.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            height: 44
                            radius: 14
                            color: Qt.rgba(1,1,1,0.07)
                            border.color: Qt.rgba(1,1,1,0.14)
                            border.width: 1
                            implicitWidth: mediaRow.implicitWidth + 20
                            clip: true

                            // Shimmer/shine line across card
                            Rectangle {
                                id: shimmer
                                width: 60
                                height: parent.height
                                x: -60
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.06) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }

                                SequentialAnimation on x {
                                    running: mediaCard.visible
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: 3500 }
                                    NumberAnimation { to: mediaCard.implicitWidth + 60; duration: 900; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: -60; duration: 0 }
                                }
                            }

                            Row {
                                id: mediaRow
                                anchors.centerIn: parent
                                spacing: 10

                                // Album Art or Music Icon
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 8
                                    color: Qt.rgba(1,1,1,0.10)
                                    anchors.verticalCenter: parent.verticalCenter
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: LockManager.musicArt || ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: LockManager.musicArt.length > 0
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        color: Theme.primary
                                        font.pixelSize: 13
                                        font.family: Theme.fontFamily
                                        visible: LockManager.musicArt.length === 0

                                        RotationAnimation on rotation {
                                            running: LockManager.isPlaying && LockManager.musicArt.length === 0
                                            loops: Animation.Infinite
                                            from: 0; to: 360
                                            duration: 4000
                                        }
                                    }
                                }

                                // Song & Artist Title
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: LockManager.musicTitle || ""
                                        color: "white"
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: Theme.fontFamily
                                        elide: Text.ElideRight
                                        width: Math.min(200, implicitWidth)
                                    }

                                    Text {
                                        text: LockManager.musicArtist || LockManager.musicPlayerName
                                        color: Qt.rgba(1,1,1,0.55)
                                        font.pixelSize: 10
                                        font.family: Theme.fontFamily
                                        elide: Text.ElideRight
                                        width: Math.min(200, implicitWidth)
                                    }
                                }

                                // Media Control Buttons
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    // Prev
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 7
                                        color: prevM.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒮"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: "white"
                                        }

                                        MouseArea {
                                            id: prevM
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: LockManager.prevMusic()
                                        }
                                    }

                                    // Play/Pause
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                        scale: ppMouse.pressed ? 0.88 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: LockManager.isPlaying ? "󰏤" : "󰐊"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: Theme.on_primary
                                        }

                                        MouseArea {
                                            id: ppMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: LockManager.playPauseMusic()
                                        }
                                    }

                                    // Next
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 7
                                        color: nextM.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒭"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: "white"
                                        }

                                        MouseArea {
                                            id: nextM
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: LockManager.nextMusic()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Right Power Actions
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // Suspend
                        Rectangle {
                            id: suspendBtn
                            width: 40
                            height: 40
                            radius: 20
                            color: suspendMouse.containsMouse
                                ? Qt.rgba(1,1,1,0.18)
                                : Qt.rgba(1,1,1,0.08)
                            border.width: 1
                            border.color: Qt.rgba(1,1,1,0.16)
                            scale: suspendMouse.pressed ? 0.88 : 1.0

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "white"
                                font.pixelSize: 15
                                font.family: Theme.fontFamily
                            }

                            MouseArea {
                                id: suspendMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                            }
                        }

                        // Reboot
                        Rectangle {
                            id: rebootBtn
                            width: 40
                            height: 40
                            radius: 20
                            color: rebootMouse.containsMouse
                                ? Qt.rgba(1,1,1,0.18)
                                : Qt.rgba(1,1,1,0.08)
                            border.width: 1
                            border.color: Qt.rgba(1,1,1,0.16)
                            scale: rebootMouse.pressed ? 0.88 : 1.0

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "white"
                                font.pixelSize: 15
                                font.family: Theme.fontFamily
                            }

                            MouseArea {
                                id: rebootMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                            }
                        }

                        // Power Off
                        Rectangle {
                            id: powerBtn
                            width: 40
                            height: 40
                            radius: 20
                            color: powerMouse.containsMouse
                                ? Qt.rgba(0.9, 0.2, 0.2, 0.45)
                                : Qt.rgba(1,1,1,0.08)
                            border.width: 1
                            border.color: powerMouse.containsMouse
                                ? Theme.error
                                : Qt.rgba(1,1,1,0.16)
                            scale: powerMouse.pressed ? 0.88 : 1.0

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: powerMouse.containsMouse ? Theme.error : "white"
                                font.pixelSize: 15
                                font.family: Theme.fontFamily
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            MouseArea {
                                id: powerMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    passwordField.forceActiveFocus()
                }
            }
        }
    }
}
