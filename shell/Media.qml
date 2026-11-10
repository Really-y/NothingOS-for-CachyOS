pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    readonly property var players: Mpris.players.values
    // prefer the one that is playing
    readonly property var player: {
        const ps = players;
        for (const p of ps) if (p.isPlaying) return p;
        return ps.length ? ps[0] : null;
    }
    readonly property bool active: player !== null && (player.trackTitle || "") !== ""
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""
    readonly property bool playing: player ? player.isPlaying : false
}
