pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import "."

Item {
    id: root

    property bool locked: false
    property string currentWallpaperPath: ""
    property string username: Quickshell.env("USER") || "udin"
    property bool isAuthenticating: false
    property string authError: ""
    property int shakeTrigger: 0
    property string timeStr: ""
    property string dateStr: ""

    // MPRIS Active Media Player
    readonly property MprisPlayer activePlayer: {
        let list = Mpris.players.values
        if (!list || list.length === 0) return null
        for (let i = 0; i < list.length; i++) {
            let p = list[i]
            if (p && p.playbackState === MprisPlaybackState.Playing) return p
        }
        return list[0]
    }

    readonly property bool hasMusic: activePlayer !== null
    readonly property bool isPlaying: hasMusic && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string musicTitle: (hasMusic && activePlayer.trackTitle) ? activePlayer.trackTitle : ""
    readonly property string musicArtist: (hasMusic && activePlayer.trackArtist) ? activePlayer.trackArtist : ""
    readonly property string musicAlbum: (hasMusic && activePlayer.trackAlbum) ? activePlayer.trackAlbum : ""
    readonly property string musicArt: (hasMusic && activePlayer.artUrl) ? activePlayer.artUrl : ""
    readonly property string musicPlayerName: hasMusic ? (activePlayer.identity || "Media Player") : ""

    readonly property string musicText: {
        if (!hasMusic || (!musicTitle && !musicArtist)) return ""
        if (musicArtist && musicTitle) return `${musicArtist} - ${musicTitle}`
        return musicTitle || musicArtist
    }

    function playPauseMusic() {
        if (root.activePlayer) root.activePlayer.playPause()
    }

    function nextMusic() {
        if (root.activePlayer) root.activePlayer.next()
    }

    function prevMusic() {
        if (root.activePlayer) root.activePlayer.previous()
    }

    // Pam context using vlock configuration
    PamContext {
        id: pam
        config: "vlock"

        onCompleted: result => {
            root.isAuthenticating = false
            if (result === PamResult.Success) {
                root.authError = ""
                root.unlock()
            } else {
                root.authError = "Password salah, coba lagi"
                root.shakeTrigger++
                pam.start()
            }
        }

        onError: err => {
            root.isAuthenticating = false
            root.authError = "Autentikasi gagal"
            pam.start()
        }
    }

    function lock(): void {
        refreshWallpaper()
        root.authError = ""
        root.isAuthenticating = false
        root.locked = true
        pam.start()
    }

    function unlock(): void {
        root.locked = false
        root.authError = ""
        root.isAuthenticating = false
        if (pam.active) {
            pam.abort()
        }
    }

    function toggle(): void {
        if (root.locked) {
            root.unlock()
        } else {
            root.lock()
        }
    }

    function submitPassword(password: string): void {
        if (!password || password.length === 0) return
        root.isAuthenticating = true
        root.authError = ""
        if (pam.responseRequired) {
            pam.respond(password)
        } else {
            pam.start()
        }
    }

    function updateDateTime(): void {
        let now = new Date()
        let h = String(now.getHours()).padStart(2, '0')
        let m = String(now.getMinutes()).padStart(2, '0')
        root.timeStr = `${h}:${m}`
        root.dateStr = Qt.formatDate(now, "dddd, d MMMM yyyy")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateDateTime()
    }

    function refreshWallpaper(): void {
        wallProc.running = true
    }

    Process {
        id: wallProc
        command: ["sh", "-c", "cat \"$HOME/.cache/current-wallpaper\" 2>/dev/null || (awww query 2>/dev/null | grep -o '/.*' | head -n 1)"]
        stdout: StdioCollector {
            onDataChanged: {
                let p = text.trim()
                if (p && p.length > 0) {
                    root.currentWallpaperPath = p
                }
            }
        }
    }

    // Auto-update wallpaper when current-wallpaper cache file changes
    property var fileView: FileView {
        path: Quickshell.env("HOME") + "/.cache/current-wallpaper"
        preload: true
        watchChanges: true
        onTextChanged: {
            let p = text().trim()
            if (p && p.length > 0) {
                root.currentWallpaperPath = p
            }
        }
    }

    // Auto-lock on initial system boot (uses RAM tmpfs flag so it won't re-lock on hot-reloads)
    Process {
        id: bootCheckProc
        command: ["sh", "-c", "FLAG=\"${XDG_RUNTIME_DIR:-/run/user/1000}/quickshell_boot_locked\"; if [ ! -f \"$FLAG\" ]; then touch \"$FLAG\"; echo \"LOCK\"; fi"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "LOCK") {
                    root.lock()
                }
            }
        }
    }

    Component.onCompleted: {
        refreshWallpaper()
        updateDateTime()
        bootCheckProc.running = true
    }
}
