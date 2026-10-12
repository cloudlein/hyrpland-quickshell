pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    // --- State Properties ---
    property bool dnd: false
    property bool controlCenterOpen: false
    property var activeToasts: []
    property var notificationTimes: ({})
    property int unreadCount: notifServer.trackedNotifications ? notifServer.trackedNotifications.values.length : 0

    // Quick Settings states
    property bool wifiEnabled: true
    property string wifiSsid: ""
    property bool bluetoothEnabled: false
    property int volume: 50
    property bool isMuted: false
    property bool isMicMuted: false

    property alias server: notifServer

    NotificationServer {
        id: notifServer
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true

        onNotification: (notif) => {
            notif.tracked = true

            // Record timestamp
            let times = Object.assign({}, root.notificationTimes)
            times[notif.id] = Date.now()
            root.notificationTimes = times

            // Connect closed signal to auto-cleanup toast
            notif.closed.connect((reason) => {
                root.removeToast(notif.id)
            })

            // If DND is inactive, show on-screen toast & play sound
            if (!root.dnd) {
                root.pushToast(notif)
                Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"])
            }
        }
    }

    // --- Toast Management ---
    function pushToast(notif) {
        let arr = root.activeToasts.slice()
        // Limit max simultaneous on-screen toasts to 4
        if (arr.length >= 4) {
            arr.shift()
        }
        // Avoid duplicate ID
        arr = arr.filter(item => item.id !== notif.id)
        arr.push(notif)
        root.activeToasts = arr
    }

    function removeToast(notifId) {
        let arr = root.activeToasts.filter(item => item.id !== notifId)
        root.activeToasts = arr
    }

    function clearAll() {
        if (!notifServer.trackedNotifications) return
        let list = notifServer.trackedNotifications.values
        for (let i = list.length - 1; i >= 0; i--) {
            try {
                list[i].dismiss()
            } catch(e) {}
        }
        root.activeToasts = []
    }

    function toggleControlCenter() {
        root.controlCenterOpen = !root.controlCenterOpen
        if (root.controlCenterOpen) {
            root.refreshSystemStatus()
        }
    }

    function openControlCenter() {
        root.controlCenterOpen = true
        root.refreshSystemStatus()
    }

    function closeControlCenter() {
        root.controlCenterOpen = false
    }

    function toggleDnd() {
        root.dnd = !root.dnd
    }

    function formatTime(notifId) {
        let t = root.notificationTimes[notifId]
        if (!t) return "Just now"
        let diff = Math.floor((Date.now() - t) / 1000)
        if (diff < 10) return "Just now"
        if (diff < 60) return `${diff}s ago`
        if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
        return `${Math.floor(diff / 3600)}h ago`
    }

    // --- Quick Settings Controls ---
    function toggleWifi() {
        let target = root.wifiEnabled ? "off" : "on"
        Quickshell.execDetached(["nmcli", "radio", "wifi", target])
        root.wifiEnabled = !root.wifiEnabled
        wifiTimer.restart()
    }

    function toggleBluetooth() {
        let target = root.bluetoothEnabled ? "off" : "on"
        Quickshell.execDetached(["bluetoothctl", "power", target])
        root.bluetoothEnabled = !root.bluetoothEnabled
        btTimer.restart()
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        root.isMuted = !root.isMuted
        audioSinkProc.running = true
    }

    function toggleMicMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        root.isMicMuted = !root.isMicMuted
        audioSourceProc.running = true
    }

    function setVolume(pct) {
        let safePct = Math.max(0, Math.min(100, pct))
        root.volume = safePct
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${safePct}%`])
        audioSinkProc.running = true
    }

    function refreshSystemStatus() {
        wifiProc.running = true
        btProc.running = true
        audioSinkProc.running = true
        audioSourceProc.running = true
    }

    // --- Background Pollers ---
    // Wi-Fi
    Process {
        id: wifiProc
        command: ["bash", "-c", "echo $(nmcli radio wifi); nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n")
                if (lines.length > 0) {
                    root.wifiEnabled = (lines[0].trim() === "enabled")
                    root.wifiSsid = lines.length > 1 ? lines[1].trim() : ""
                }
            }
        }
    }

    Timer {
        id: wifiTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    // Bluetooth
    Process {
        id: btProc
        command: ["bash", "-c", "bluetoothctl show | grep 'Powered:'"]
        stdout: SplitParser {
            onRead: data => {
                root.bluetoothEnabled = data.includes("Powered: yes")
            }
        }
    }

    Timer {
        id: btTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: btProc.running = true
    }

    // Audio Sink (Volume & Mute)
    Process {
        id: audioSinkProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let parts = data.trim().split(" ")
                    if (parts.length >= 2) {
                        root.isMuted = data.includes("[MUTED]")
                        let val = Math.round(parseFloat(parts[1]) * 100)
                        root.volume = Math.min(100, val)
                    }
                } catch(e) {}
            }
        }
    }

    // Mic Source (Mic Mute)
    Process {
        id: audioSourceProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: SplitParser {
            onRead: data => {
                root.isMicMuted = data.includes("[MUTED]")
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            audioSinkProc.running = true
            audioSourceProc.running = true
        }
    }
}
