pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property string icon: muted || volume <= 0.001 ? "volume_off"
                                 : volume < 0.34 ? "volume_mute"
                                 : volume < 0.67 ? "volume_down" : "volume_up"
    signal changedByUser()

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    function setVolume(v) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
}
