import QtQuick
import "nothing"

// Nothing now-playing card. Pure view: feed it track data, listen to the signals.
//  square: posterised halftone dot portrait inside the content box, white
//          play/pause top-right, status + title + artist in the bottom band
//  wide:   halftone art (4px grid) on black, status, marquee title/artist,
//          dot prev/next glyphs around a white play disk
//  idle:   vinyl pictogram + "IDLE" in dots
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
            text: root.playing ? "Now playing" : "Paused"
        }
    }

    // White circle, black dot glyph.
    component PlayButton: Pressable {
        property int diameter: 44
        width: diameter; height: diameter
        enabled: root.canPlayPause
        onClicked: root.playPause()
        Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.fg }
        DotGlyph {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.playing ? 0 : 1
            width: 16; height: 16
            icon: root.playing ? "pause" : "play"
            dimColor: "transparent"
            litColor: Theme.bg
            dotRatio: 0.9
        }
    }

    component SkipButton: Pressable {
        property string glyph
        property bool can: true
        width: Math.round(36 * root.u); height: width
        enabled: can
        DotGlyph {
            anchors.centerIn: parent
            width: 16; height: 16
            icon: parent.glyph
            dimColor: "transparent"
            dotRatio: 0.9
            litColor: !parent.can ? "#4a4a4a" : Theme.fg
            opacity: parent.can && !parent.containsMouse ? 0.9 : 1
        }
    }

    // ══ Square ═══════════════════════════════════════════════════════════════
    Item {
        id: sq
        visible: !root.wide
        anchors.fill: parent
        anchors.margins: root.padding

        // Contained dot-portrait tile above the text band.
        Rectangle {
            visible: root.hasArt
            anchors.fill: portrait
            radius: root.innerRadius
            color: Theme.bg
        }
        ArtCanvas {
            id: portrait
            visible: root.hasArt
            width: Math.round(sq.height - band.height - 12 * root.u); height: width
            source: root.hasArt && !root.wide ? root.artUrl : ""
            mode: "halftone"
            radius: root.innerRadius
            pitch: 3
            fadeTop: 0
            fadeBottom: 0
        }
        // playing without cover art: the same tile, a dot note on black
        Rectangle {
            visible: root.hasMedia && !root.hasArt
            width: portrait.width; height: width
            radius: root.innerRadius
            color: Theme.bg
            DotGlyph {
                anchors.centerIn: parent
                width: parent.width * 0.62; height: width
                icon: "note"
                dimColor: "transparent"
                litColor: Theme.fg2
            }
        }
        PlayButton {
            visible: root.hasMedia
            anchors.right: parent.right; anchors.top: parent.top
            diameter: Math.round(38 * root.u)
        }
        Column {
            id: band
            visible: root.hasMedia
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Math.round(4 * root.u)
            Status { bottomPadding: Math.round(2 * root.u) }
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

        // idle: vinyl + IDLE, nothing else
        DotGlyph {
            visible: !root.hasMedia
            x: -pitch * 0.14; y: -pitch * 0.14
            width: Math.round(72 * root.u); height: width
            icon: "vinyl"
            dimColor: "transparent"
            litColor: Theme.fg2
            halfColor: Theme.fg2
        }
        DotString {
            visible: !root.hasMedia
            anchors.left: parent.left; anchors.bottom: parent.bottom
            text: "IDLE"
            size: Math.max(40, Math.round(48 * root.u))
            width: implicitWidth; height: implicitHeight
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
            color: Theme.bg
            DotGlyph {
                anchors.centerIn: parent
                width: parent.width * 0.62; height: width
                visible: !artWide.ready
                icon: root.hasMedia ? "note" : "vinyl"
                litColor: Theme.fg2
                halfColor: Theme.fg2
                dimColor: "transparent"
            }
        }
        ArtCanvas {
            id: artWide
            anchors.fill: artBox
            visible: root.hasArt
            source: root.hasArt && root.wide ? root.artUrl : ""
            mode: "halftone"
            pitch: 4
            fadeTop: 0
            fadeBottom: 0
            radius: root.innerRadius
        }

        Item {
            anchors.left: artBox.right; anchors.leftMargin: Math.round(18 * root.u)
            anchors.right: parent.right
            anchors.top: parent.top; anchors.bottom: parent.bottom

            Status { id: wStatus; visible: root.hasMedia; y: Math.round(2 * root.u) }

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
                SkipButton { anchors.verticalCenter: parent.verticalCenter; glyph: "prev"; can: root.canPrevious; onClicked: root.previous() }
                PlayButton { diameter: Math.round(46 * root.u) }
                SkipButton { anchors.verticalCenter: parent.verticalCenter; glyph: "next"; can: root.canNext; onClicked: root.next() }
            }

            // idle: IDLE + one caption
            Column {
                visible: !root.hasMedia
                anchors.left: parent.left; anchors.bottom: parent.bottom
                spacing: Math.round(12 * root.u)
                DotString {
                    text: "IDLE"
                    size: Math.max(40, Math.round(56 * root.u))
                    width: implicitWidth; height: implicitHeight
                }
                Label { size: Math.max(10, Math.round(10 * root.u)); color: Theme.fg3; text: "No media" }
            }
        }
    }
}
