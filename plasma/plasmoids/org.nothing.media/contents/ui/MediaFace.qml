import QtQuick
import "nothing"

// Wide now-playing card. Pure view: feed it track data, listen to the signals.
Card {
    id: root
    property bool hasMedia: false
    property bool playing: false
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property bool canPrevious: true
    property bool canNext: true
    property bool canPlayPause: true
    signal previous()
    signal playPause()
    signal next()

    readonly property real u: Math.max(0.5, Math.min(width / 360, height / 180))
    readonly property int pad: Math.round(20 * u)
    readonly property int art: height - 2 * pad

    implicitWidth: 360
    implicitHeight: 180

    // ── Left: album art, or a dot-matrix note when idle / no art ──────────
    Rectangle {
        id: artBox
        x: root.pad; y: root.pad
        width: root.art; height: root.art
        radius: Math.round(20 * root.u)
        color: Theme.card2

        DotGlyph {
            anchors.centerIn: parent
            width: parent.width * 0.62; height: width
            visible: !cover.ready
            lit: root.hasMedia ? Theme.fg2 : Theme.fg3
        }
        RoundedImage {
            id: cover
            anchors.fill: parent
            radius: parent.radius
            visible: root.hasMedia && root.artUrl !== ""
            source: visible ? root.artUrl : ""
        }
    }

    // ── Right: status, text, transport ────────────────────────────────────
    Item {
        id: info
        anchors.left: artBox.right; anchors.leftMargin: Math.round(18 * root.u)
        anchors.right: parent.right; anchors.rightMargin: root.pad
        anchors.top: artBox.top; anchors.bottom: artBox.bottom

        Row {
            id: status
            y: Math.round(2 * root.u)
            spacing: Math.round(6 * root.u)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(6 * root.u); height: width; radius: width / 2
                color: root.playing ? Theme.red : Theme.fg3
            }
            Label {
                size: Math.max(9, Math.round(10 * root.u))
                color: root.playing ? Theme.red : Theme.fg2
                text: !root.hasMedia ? "Idle" : root.playing ? "Now playing" : "Paused"
            }
        }

        // Track text
        Column {
            visible: root.hasMedia
            anchors.top: status.bottom; anchors.topMargin: Math.round(12 * root.u)
            width: parent.width
            spacing: Math.round(4 * root.u)
            Text {
                width: parent.width
                text: root.title || "Unknown track"
                color: Theme.fg
                font.family: Theme.sans
                font.pixelSize: Math.round(19 * root.u)
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.artist
                visible: text !== ""
                color: Theme.fg2
                font.family: Theme.mono
                font.pixelSize: Math.max(10, Math.round(11 * root.u))
                elide: Text.ElideRight
            }
        }

        // Idle: dot-matrix message instead of an empty box.
        Column {
            visible: !root.hasMedia
            anchors.top: status.bottom; anchors.topMargin: Math.round(10 * root.u)
            spacing: Math.round(-6 * root.u)
            DotText { text: "NO"; size: Math.round(36 * root.u); weight: 900 }
            DotText { text: "MEDIA"; size: Math.round(36 * root.u); weight: 900 }
        }

        Row {
            id: transport
            visible: root.hasMedia
            anchors.bottom: parent.bottom
            spacing: Math.round(10 * root.u)
            readonly property int small: Math.round(40 * root.u)
            readonly property int big: Math.round(48 * root.u)

            Pressable {
                width: transport.small; height: width
                anchors.verticalCenter: parent.verticalCenter
                enabled: root.canPrevious
                opacity: enabled ? 1 : 0.35
                onClicked: root.previous()
                Rectangle { anchors.fill: parent; radius: width / 2; color: parent.containsMouse ? Theme.card3 : Theme.card2 }
                Icon { anchors.centerIn: parent; name: "skip_previous"; size: Math.round(22 * root.u); fill: 1 }
            }
            Pressable {
                width: transport.big; height: width
                enabled: root.canPlayPause
                onClicked: root.playPause()
                Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.fg }
                Icon { anchors.centerIn: parent; name: root.playing ? "pause" : "play_arrow"; size: Math.round(26 * root.u); fill: 1; color: Theme.bg }
            }
            Pressable {
                width: transport.small; height: width
                anchors.verticalCenter: parent.verticalCenter
                enabled: root.canNext
                opacity: enabled ? 1 : 0.35
                onClicked: root.next()
                Rectangle { anchors.fill: parent; radius: width / 2; color: parent.containsMouse ? Theme.card3 : Theme.card2 }
                Icon { anchors.centerIn: parent; name: "skip_next"; size: Math.round(22 * root.u); fill: 1 }
            }
        }

        Label {
            visible: !root.hasMedia
            anchors.bottom: parent.bottom
            size: Math.max(9, Math.round(10 * root.u))
            color: Theme.fg3
            text: "Play something"
        }
    }
}
