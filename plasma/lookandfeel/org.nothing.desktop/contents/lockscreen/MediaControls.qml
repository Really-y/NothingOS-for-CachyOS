/*
    MPRIS media controls for the lock screen (Plasma's multiplexer = the "current" player).
    Based on Plasma's lockscreen MediaControls.qml; visuals in MediaCard.qml.

    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.plasma.private.mpris as Mpris

Item {
    id: media
    // Called when a control is used, so the prompt does not fade out mid-interaction.
    signal interacted()

    readonly property bool hasMedia: instantiator.count > 0
    visible: hasMedia
    implicitHeight: 64
    implicitWidth: 380

    Repeater {
        id: instantiator
        model: Mpris.MultiplexerModel { }

        MediaCard {
            anchors.fill: parent
            canControl: model.canControl
            track: model.track.length > 0
                ? model.track
                : (model.playbackStatus > Mpris.PlaybackStatus.Stopped
                    ? i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "No title")
                    : i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "No media playing"))
            // if no artist is given, show player name instead
            artist: model.artist || model.identity
            artUrl: model.artUrl
            playing: model.playbackStatus === Mpris.PlaybackStatus.Playing
            canGoPrevious: model.canGoPrevious
            canGoNext: model.canGoNext
            onPrevious: { media.interacted(); model.container.Previous() }
            onPlayPause: { media.interacted(); model.container.PlayPause() }
            onNext: { media.interacted(); model.container.Next() }
        }
    }
}
