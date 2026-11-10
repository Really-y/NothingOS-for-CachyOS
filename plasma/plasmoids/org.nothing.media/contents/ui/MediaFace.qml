import QtQuick
import "nothing"

// Nothing now-playing card. Pure view: feed it track data, listen to the signals.
//  square: full-bleed halftone art, status top-left, title/artist lower-left,
//          small white play/pause bottom-right
//  wide:   desaturated art (concentric radius), status, marquee title/artist,
//          bare prev/next glyphs around a white play circle
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
    property string variant: "auto"     // "auto" | "square" | "wide"
    signal previous()
    signal playPause()
    signal next()

    readonly property bool wide: variant === "wide" || (variant === "auto" && width / Math.max(1, height) >= 1.5)
    readonly property real u: wide ? Math.min(width / 360, height / 180) : Math.min(width, height) / 180
    readonly property bool hasArt: hasMedia && artUrl !== ""

    padding: Math.round(18 * u)
    implicitWidth: 180
    implicitHeight: 180

    component Status: Row {
        spacing: Math.round(6 * root.u)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(6 * root.u); height: width; radius: width / 2
            color: root.playing ? Theme.red : Theme.fg3
        }
        Label {
            size: Math.max(10, Math.round(10 * root.u))
            color: root.playing ? Theme.red : Theme.fg2
            text: !root.hasMedia ? "No media" : root.playing ? "Now playing" : "Paused"
        }
    }

    component PlayButton: Pressable {
        property int diameter: 44
        width: diameter; height: diameter
        enabled: root.canPlayPause
        onClicked: root.playPause()
        Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.fg }
        Icon {
            anchors.centerIn: parent
            name: root.playing ? "pause" : "play_arrow"
            size: Math.round(parent.diameter * 0.55)
            fill: 1
            color: Theme.bg
        }
    }

    component SkipButton: Pressable {
        property string glyph
        property bool can: true
        width: Math.round(36 * root.u); height: width
        enabled: can
        Icon {
            anchors.centerIn: parent
            name: parent.glyph
            size: Math.round(22 * root.u)
            fill: 1
            color: !parent.can ? Theme.fg3 : parent.containsMouse ? Theme.fg : Theme.fg2
        }
    }

    // ══ Square ═══════════════════════════════════════════════════════════════
    Item {
        visible: !root.wide
        anchors.fill: parent

        ArtCanvas {
            anchors.fill: parent
            visible: root.hasArt
            source: root.hasArt && !root.wide ? root.artUrl : ""
            mode: "halftone"
            radius: root.radius
            pitch: Math.max(4, Math.round(6 * root.u))
        }

        Item {
            anchors.fill: parent
            anchors.margins: root.padding

            Status { id: sqStatus }

            // playing / paused
            Column {
                visible: root.hasMedia
                anchors.left: parent.left
                anchors.right: sqPlay.left; anchors.rightMargin: Math.round(10 * root.u)
                anchors.bottom: parent.bottom
                spacing: Math.round(2 * root.u)
                Marquee {
                    width: parent.width
                    text: root.title || "Unknown track"
                    color: Theme.fg
                    font.family: Theme.sans
                    font.pixelSize: Math.round(16 * root.u)
                    font.weight: Font.Medium
                }
                Marquee {
                    width: parent.width
                    visible: root.artist !== ""
                    text: root.artist
                    color: Theme.fg2
                    font.family: Theme.mono
                    font.pixelSize: Math.max(10, Math.round(10 * root.u))
                }
            }
            PlayButton {
                id: sqPlay
                visible: root.hasMedia
                anchors.right: parent.right; anchors.bottom: parent.bottom
                diameter: Math.round(38 * root.u)
            }

            // idle, or playing without cover art
            DotGlyph {
                visible: !root.hasArt
                anchors.right: parent.right; anchors.top: parent.top
                width: Math.round(66 * root.u); height: width
                icon: root.hasMedia ? "note" : "vinyl"
                dimColor: "transparent"
                litColor: Theme.fg2
            }
            Column {
                visible: !root.hasMedia
                anchors.left: parent.left; anchors.bottom: parent.bottom
                spacing: Math.round(10 * root.u)
                DotString { text: "IDLE"; size: Math.max(40, Math.round(44 * root.u)); width: implicitWidth; height: implicitHeight }
                Label { size: Math.max(10, Math.round(10 * root.u)); color: Theme.fg3; text: "Nothing playing" }
            }
        }
    }

    // ══ Wide ═════════════════════════════════════════════════════════════════
    Item {
        visible: root.wide
        anchors.fill: parent
        anchors.margins: root.padding

        Rectangle {
            id: artBox
            width: parent.height; height: width
            radius: root.innerRadius
            color: Theme.widget2
            visible: !artWide.ready
            DotGlyph {
                anchors.centerIn: parent
                width: parent.width * 0.66; height: width
                icon: root.hasMedia ? "note" : "vinyl"
                litColor: root.hasMedia ? Theme.fg2 : Theme.fg3
                dimColor: "transparent"
            }
        }
        ArtCanvas {
            id: artWide
            anchors.fill: artBox
            visible: root.hasArt
            source: root.hasArt && root.wide ? root.artUrl : ""
            mode: "mono"
            radius: root.innerRadius
        }

        Item {
            anchors.left: artBox.right; anchors.leftMargin: Math.round(18 * root.u)
            anchors.right: parent.right
            anchors.top: parent.top; anchors.bottom: parent.bottom

            Status { id: wStatus; y: Math.round(2 * root.u) }

            Column {
                visible: root.hasMedia
                anchors.top: wStatus.bottom; anchors.topMargin: Math.round(12 * root.u)
                width: parent.width
                spacing: Math.round(4 * root.u)
                Marquee {
                    width: parent.width
                    text: root.title || "Unknown track"
                    color: Theme.fg
                    font.family: Theme.sans
                    font.pixelSize: Math.round(18 * root.u)
                    font.weight: Font.Medium
                }
                Marquee {
                    width: parent.width
                    visible: root.artist !== ""
                    text: root.artist
                    color: Theme.fg2
                    font.family: Theme.mono
                    font.pixelSize: Math.max(10, Math.round(11 * root.u))
                }
            }

            Row {
                visible: root.hasMedia
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.leftMargin: -Math.round(8 * root.u)
                spacing: Math.round(8 * root.u)
                SkipButton { anchors.verticalCenter: parent.verticalCenter; glyph: "skip_previous"; can: root.canPrevious; onClicked: root.previous() }
                PlayButton { diameter: Math.round(46 * root.u) }
                SkipButton { anchors.verticalCenter: parent.verticalCenter; glyph: "skip_next"; can: root.canNext; onClicked: root.next() }
            }

            // idle
            DotString {
                visible: !root.hasMedia
                anchors.verticalCenter: parent.verticalCenter
                text: "IDLE"
                size: Math.max(40, Math.round(52 * root.u))
                width: implicitWidth; height: implicitHeight
            }
            Label {
                visible: !root.hasMedia
                anchors.bottom: parent.bottom
                size: Math.max(10, Math.round(10 * root.u))
                color: Theme.fg3
                text: "Play something"
            }
        }
    }
}
