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
    signal previous()
    signal playPause()
    signal next()

    implicitWidth: 380
    implicitHeight: 76
    radius: Theme.r
    color: Theme.card
    border.width: 1
    border.color: Theme.line

    // Artwork, or a dot-matrix note when there is none.
    Item {
        id: artBox
        x: 14; width: 48; height: 48
        anchors.verticalCenter: parent.verticalCenter
        Rectangle { anchors.fill: parent; radius: 14; color: Theme.card2 }
        Icon { anchors.centerIn: parent; name: "music_note"; size: 22; color: Theme.fg2; visible: art.status !== Image.Ready }
        Image {
            id: art
            anchors.fill: parent
            source: card.artUrl
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width * 2; sourceSize.height: height * 2
            visible: status === Image.Ready
        }
        // Rounds the artwork corners without layer effects (works with software rendering).
        Rectangle {
            anchors.fill: parent; anchors.margins: -8
            radius: 22; color: "transparent"
            border.width: 8; border.color: card.color
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
        Label {
            width: parent.width
            text: card.artist
            elide: Text.ElideRight
            textFormat: Text.PlainText
            visible: text !== ""
        }
    }

    Row {
        id: controls
        anchors.right: parent.right; anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        enabled: card.canControl

        Pressable {
            width: 36; height: 36
            anchors.verticalCenter: parent.verticalCenter
            enabled: card.canGoPrevious
            opacity: enabled ? 1 : 0.35
            onClicked: card.previous()
            Icon { anchors.centerIn: parent; name: "skip_previous"; size: 22 }
            Accessible.role: Accessible.Button
            Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Accessible only", "Previous track")
        }
        Pressable {
            width: 44; height: 44
            onClicked: card.playPause()
            Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.fg }
            Icon { anchors.centerIn: parent; name: card.playing ? "pause" : "play_arrow"; size: 24; fill: 1; color: Theme.bg }
            Accessible.role: Accessible.Button
            Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Accessible only", "Play or Pause media")
        }
        Pressable {
            width: 36; height: 36
            anchors.verticalCenter: parent.verticalCenter
            enabled: card.canGoNext
            opacity: enabled ? 1 : 0.35
            onClicked: card.next()
            Icon { anchors.centerIn: parent; name: "skip_next"; size: 22 }
            Accessible.role: Accessible.Button
            Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Accessible only", "Next track")
        }
    }
}
