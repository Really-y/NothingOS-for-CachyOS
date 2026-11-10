import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mpris as Mpris
import "nothing"

// Nothing now-playing card driven by Plasma's MPRIS model (current player).
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property bool hasMedia: !!player && ((player.track || "") !== "" || (player.artist || "") !== "")
    readonly property bool playing: !!player && player.playbackStatus === Mpris.PlaybackStatus.Playing

    toolTipMainText: hasMedia ? player.track : i18n("No media playing")
    toolTipSubText: hasMedia ? player.artist : ""

    fullRepresentation: MediaFace {
        Layout.minimumWidth: 280
        Layout.minimumHeight: 140
        Layout.preferredWidth: 360
        Layout.preferredHeight: 180
        hasMedia: root.hasMedia
        playing: root.playing
        title: root.player ? (root.player.track || "") : ""
        artist: root.player ? (root.player.artist || "") : ""
        artUrl: root.player && root.player.artUrl ? root.player.artUrl.toString() : ""
        canPrevious: !!root.player && root.player.canGoPrevious
        canNext: !!root.player && root.player.canGoNext
        canPlayPause: !!root.player && (root.playing ? root.player.canPause : root.player.canPlay)
        onPrevious: root.player.Previous()
        onNext: root.player.Next()
        onPlayPause: root.player.PlayPause()
    }
}
