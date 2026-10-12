import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".."
import "../components"

Pill {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool isMuted: (sink && sink.audio) ? sink.audio.muted : false

    text: isMuted ? "󰝟" : (volume <= 0.01 ? "󰕿" : (volume < 0.5 ? "󰖀" : "󰕾"))
    tooltipText: {
        let percent = Math.round(volume * 100)
        let desc = sink ? (sink.description || "Audio") : "Audio"
        return `${desc}: ${percent}%${isMuted ? " (Muted)" : ""}`
    }

    onClicked: Quickshell.execDetached(["pavucontrol"])

    onRightClicked: {
        if (sink && sink.audio) {
            sink.audio.muted = !sink.audio.muted
        }
    }

    onScrollUp: {
        if (sink && sink.audio) {
            sink.audio.volume = Math.min(1.0, sink.audio.volume + 0.05)
        }
    }

    onScrollDown: {
        if (sink && sink.audio) {
            sink.audio.volume = Math.max(0.0, sink.audio.volume - 0.05)
        }
    }
}
