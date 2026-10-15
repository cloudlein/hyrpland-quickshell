pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool pickerOpen: false
    property var wallpapers: []
    property int currentIndex: 0
    property string originalWallpaper: ""

    // Wallpaper Background State & Transitions
    property string sourceWallpaper: ""
    property string targetWallpaper: ""
    property bool isTransitioning: false
    property real transitionProgress: 1.0
    property int currentTransitionType: 0

    readonly property var transitionNames: [
        "Circle Expand", "Circle Contract", "Diamond Expand", "Clock Wipe", "Spiral",
        "Wipe Left", "Wipe Right", "Wipe Up", "Wipe Down",
        "Diagonal TL-BR", "Diagonal TR-BL", "Diagonal BL-TR", "Diagonal BR-TL",
        "Split Horizontal", "Split Vertical", "Venetian Blinds (H)", "Venetian Blinds (V)",
        "Wave Ripple", "Checkerboard", "Noise Dissolve", "Cross Zoom", "Soft Dissolve"
    ]

    readonly property var currentWallpaper: (wallpapers.length > 0 && currentIndex >= 0 && currentIndex < wallpapers.length)
        ? wallpapers[currentIndex]
        : null

    NumberAnimation {
        id: transAnim
        target: root
        property: "transitionProgress"
        from: 0.0
        to: 1.0
        duration: 1200
        easing.type: Easing.InOutCubic

        onFinished: {
            root.sourceWallpaper = root.targetWallpaper
            root.isTransitioning = false
            root.transitionProgress = 1.0
        }
    }

    function triggerTransition(targetPath, forcedType, duration) {
        if (!targetPath || targetPath.length === 0) return
        if (targetPath === root.sourceWallpaper && !root.isTransitioning) return

        let type = (forcedType !== undefined && forcedType !== null) ? forcedType : -1
        let dur = (duration !== undefined && duration !== null) ? duration : 1200

        if (type < 0 || type >= root.transitionNames.length) {
            type = Math.floor(Math.random() * root.transitionNames.length)
        }

        console.log("Playing wallpaper transition [" + type + "]:", root.transitionNames[type], "->", targetPath)

        root.currentTransitionType = type
        root.targetWallpaper = targetPath
        if (!root.sourceWallpaper) {
            root.sourceWallpaper = targetPath
        }

        root.isTransitioning = true
        root.transitionProgress = 0.0
        transAnim.duration = dur
        transAnim.restart()
    }

    function toggle() {
        if (root.pickerOpen) {
            cancelPicker()
        } else {
            openPicker()
        }
    }

    property string previewInitialWallpaper: ""

    function openPicker() {
        scanProc.running = true
        currentWallProc.running = true
        root.previewInitialWallpaper = root.sourceWallpaper || root.originalWallpaper
        root.pickerOpen = true
    }

    function closePicker() {
        root.pickerOpen = false
    }

    function cancelPicker() {
        root.pickerOpen = false
        // Revert background to original wallpaper
        if (root.previewInitialWallpaper && root.previewInitialWallpaper.length > 0) {
            root.sourceWallpaper = root.previewInitialWallpaper
            root.targetWallpaper = root.previewInitialWallpaper
            root.isTransitioning = false
            if (root.wallpapers.length > 0) {
                let idx = root.wallpapers.findIndex(w => w.path === root.previewInitialWallpaper)
                if (idx !== -1) {
                    root.currentIndex = idx
                }
            }
        }
    }

    function next() {
        if (root.wallpapers.length > 0) {
            root.currentIndex = (root.currentIndex + 1) % root.wallpapers.length
            if (root.pickerOpen) {
                root.previewCurrent()
            } else {
                root.applyCurrent()
            }
        }
    }

    function prev() {
        if (root.wallpapers.length > 0) {
            root.currentIndex = (root.currentIndex - 1 + root.wallpapers.length) % root.wallpapers.length
            if (root.pickerOpen) {
                root.previewCurrent()
            } else {
                root.applyCurrent()
            }
        }
    }

    function previewCurrent() {
        if (root.currentWallpaper && root.currentWallpaper.path) {
            let target = root.currentWallpaper.path
            if (target !== root.sourceWallpaper) {
                root.isTransitioning = false
                root.sourceWallpaper = target
                root.targetWallpaper = target
            }
        }
    }

    function applyCurrent() {
        if (root.currentWallpaper && root.currentWallpaper.path) {
            let target = root.currentWallpaper.path
            let prev = root.sourceWallpaper || root.originalWallpaper
            root.originalWallpaper = target
            root.closePicker()

            // Trigger full random dynamic transition across all screens
            root.triggerTransition(target, -1, 1200)

            // Trigger Matugen colors and system synchronization
            Quickshell.execDetached([
                Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh",
                target,
                prev
            ])
        }
    }

    function formatTitle(filename) {
        let base = filename.replace(/\.[^/.]+$/, "")
        base = base.replace(/[-_]+/g, " ")
        return base.replace(/\b\w/g, l => l.toUpperCase())
    }

    // Process to scan wallpapers
    Process {
        id: scanProc
        command: ["sh", "-c", "find \"$HOME/wallpapers\" -maxdepth 1 -type f \\( -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.webp\" \\) | sort"]
        stdout: StdioCollector {
            onDataChanged: {
                let lines = text.trim().split("\n").filter(l => l.length > 0)
                let list = []
                for (let i = 0; i < lines.length; i++) {
                    let p = lines[i]
                    let filename = p.split("/").pop()
                    let ext = filename.split(".").pop().toUpperCase()
                    list.push({
                        path: p,
                        filename: filename,
                        title: root.formatTitle(filename),
                        extension: ext
                    })
                }
                root.wallpapers = list
                currentWallProc.running = true
            }
        }
    }

    // Process to read current wallpaper from ~/.cache/current-wallpaper
    Process {
        id: currentWallProc
        command: ["sh", "-c", "cat \"$HOME/.cache/current-wallpaper\" 2>/dev/null || true"]
        stdout: StdioCollector {
            onDataChanged: {
                let activePath = text.trim()
                if (activePath) {
                    root.originalWallpaper = activePath
                    if (!root.sourceWallpaper) {
                        root.sourceWallpaper = activePath
                        root.targetWallpaper = activePath
                    }
                    if (root.wallpapers.length > 0) {
                        let idx = root.wallpapers.findIndex(w => w.path === activePath)
                        if (idx !== -1) {
                            root.currentIndex = idx
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        scanProc.running = true
    }
}
