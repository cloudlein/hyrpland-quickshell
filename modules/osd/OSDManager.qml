pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    property bool osdVisible: false
    property string icon: "󰕾"
    property string label: "Volume"
    property real value: 0.5
    property bool isMuted: false
    property bool initialized: false

    readonly property PwNode sink: Pipewire.defaultAudioSink

    function show(newIcon, newLabel, newValue, muted) {
        root.icon = newIcon
        root.label = newLabel
        root.value = Math.max(0.0, Math.min(1.0, newValue))
        root.isMuted = (muted === true)
        root.osdVisible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: root.osdVisible = false
    }

    // Ignore initial connection volume triggers on startup
    Timer {
        interval: 1200
        running: true
        repeat: false
        onTriggered: root.initialized = true
    }

    // Reactively trigger OSD on Pipewire Volume / Mute changes
    Connections {
        target: (root.sink && root.sink.audio) ? root.sink.audio : null
        function onVolumeChanged() {
            if (root.initialized) {
                let v = root.sink.audio.volume
                let m = root.sink.audio.muted
                let ic = m ? "󰝟" : (v <= 0.01 ? "󰕿" : (v < 0.5 ? "󰖀" : "󰕾"))
                root.show(ic, "Volume", v, m)
            }
        }
        function onMutedChanged() {
            if (root.initialized) {
                let v = root.sink.audio.volume
                let m = root.sink.audio.muted
                let ic = m ? "󰝟" : "󰕾"
                root.show(ic, "Volume", v, m)
            }
        }
    }

    // Process to read current brightness
    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl get && brightnessctl max"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n")
                if (lines.length >= 2) {
                    let cur = parseFloat(lines[0])
                    let max = parseFloat(lines[1])
                    if (max > 0) {
                        let pct = cur / max
                        root.show("󰃠", "Brightness", pct, false)
                    }
                }
            }
        }
    }

    function changeBrightness(cmd) {
        Quickshell.execDetached(["brightnessctl", "-e4", "-n2", "set", cmd])
        brightProc.running = true
    }

    function brightnessUp() {
        changeBrightness("5%+")
    }

    function brightnessDown() {
        changeBrightness("5%-")
    }
}
