/*
    Now-playing card: art, title/artist, previous / play-pause / next.
    Pure visual component; MediaControls.qml feeds it from MPRIS.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import "nothing"

Rectangle {
    id: card
    property string track
    property string artist
    property url artUrl
    property bool playing: false
    property bool canControl: true
    property bool canGoPrevious: true
    property bool canGoNext: true
    readonly property bool hasMedia: true
    signal previous()
    signal playPause()
    signal next()

    implicitWidth: 380
    implicitHeight: 72
    radius: 24
    color: "#1a1a1a"

    // Artwork as a halftone dot dither on a black tile, or a dot-matrix note when there is none.
    Rectangle {
        id: artBox
        x: 10; width: 52; height: 52
        anchors.verticalCenter: parent.verticalCenter
        radius: 12
        color: "#000000"
        DotGlyph {
            anchors.centerIn: parent
            width: 30; height: 30
            visible: !art.ready
            icon: "note"
            dimColor: "transparent"
            litColor: Theme.fg2
            halfColor: Theme.fg2
        }
        ArtCanvas {
            id: art
            anchors.fill: parent
            visible: ready
            source: card.artUrl
            mode: "halftone"
            radius: 12
            pitch: 4; maxDot: 0.7
            fadeTop: 0
            fadeBottom: 0
        }
    }

    Column {
        anchors.left: artBox.right; anchors.leftMargin: 14
        anchors.right: controls.left; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Text {
            width: parent.width
            text: card.track
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.sans; font.pixelSize: 15; font.weight: Font.Medium
            textFormat: Text.PlainText
        }
        // sentence case as delivered by MPRIS, like the control center
        Text {
            width: parent.width
            text: card.artist
            elide: Text.ElideRight
            textFormat: Text.PlainText
            visible: text !== ""
            color: Theme.fg2
            font.family: Theme.sans; font.pixelSize: 13; font.weight: Font.Normal
        }
    }

    Row {
        id: controls
        anchors.right: parent.right; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        enabled: card.canControl

        Pressable {
            width: 36; height: 36
            anchors.verticalCenter: parent.verticalCenter
            enabled: card.canGoPrevious
            opacity: enabled ? 1 : 0.35
            onClicked: card.previous()
            DotGlyph { anchors.centerIn: parent; width: 16; height: 16; icon: "prev"; dimColor: "transparent"; dotRatio: 0.9; litColor: Theme.fg }
            Accessible.role: Accessible.Button
            Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Accessible only", "Previous track")
        }
        Pressable {
            width: 40; height: 40
            onClicked: card.playPause()
            Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.fg }
            DotGlyph {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: card.playing ? 0 : 1
                width: 16; height: 16
                icon: card.playing ? "pause" : "play"
                dimColor: "transparent"; dotRatio: 0.9; litColor: Theme.bg
            }
            Accessible.role: Accessible.Button
            Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Accessible only", "Play or Pause media")
        }
        Pressable {
            width: 36; height: 36
            anchors.verticalCenter: parent.verticalCenter
            enabled: card.canGoNext
            opacity: enabled ? 1 : 0.35
            onClicked: card.next()
            DotGlyph { anchors.centerIn: parent; width: 16; height: 16; icon: "next"; dimColor: "transparent"; dotRatio: 0.9; litColor: Theme.fg }
            Accessible.role: Accessible.Button
            Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Accessible only", "Next track")
        }
    }
}
