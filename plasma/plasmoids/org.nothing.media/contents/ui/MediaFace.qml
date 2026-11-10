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
    // small card: one art-tile size for playing, paused and idle
    readonly property real smallTile: Math.round(70 * u)

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
            color: Theme.fg2
            text: !root.hasMedia ? "No media" : root.playing ? "Now playing" : "Paused"
        }
    }

    // White circle, black dot glyph.
    component PlayButton: Pressable {
        id: pb
        property int diameter: 44
        property bool snapped: false     // small disk: fixed 4px dot grid
        width: diameter; height: diameter
        enabled: root.canPlayPause
        onClicked: root.playPause()
        Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.fg }
        // Small disk: play = 5×5 triangle, pause = two 5-dot bars, on an integer
        // 4px pitch (3px dots, 1px gaps) ≈ 55 % of the disk — dots never merge.
        DotGlyph {
            // play ends in one centred apex dot
            readonly property var grid: root.playing ? ["#...#", "#...#", "#...#", "#...#", "#...#"]
                                                    : ["#..", "##.", "###", "##.", "#.."]
            visible: pb.snapped
            rows: grid
            dimColor: "transparent"
            litColor: Theme.bg
            dotRatio: 0.75
            width: grid[0].length * 4; height: 20
            x: Math.round((pb.diameter - width) / 2) + (root.playing ? 0 : 1)
            y: Math.round((pb.diameter - height) / 2)
        }
        DotGlyph {
            visible: !pb.snapped
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.playing ? 0 : 1
            width: Math.min(16, Math.round(parent.diameter * 0.4)); height: width
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
            width: root.smallTile; height: width
            source: root.hasArt && !root.wide ? root.artUrl : ""
            mode: "halftone"
            radius: root.innerRadius
            // small tile: coarse cells, round dots that never touch
            pitch: 5
            maxDot: 0.7
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
                // 7×7 note at a whole-pixel pitch (≥ 5px), dots on pixel centres
                width: Math.max(35, Math.floor(parent.width * 0.62 / 7) * 7); height: width
                icon: "note_s"
                snap: true
                dimColor: "transparent"
                litColor: Theme.fg2
            }
        }
        // small play/pause disk, aligned to the tile's bottom edge
        PlayButton {
            visible: root.hasMedia
            anchors.right: parent.right
            y: portrait.height - height
            diameter: 36
            snapped: true
        }
        Column {
            id: band
            visible: root.hasMedia
            anchors.left: parent.left; anchors.right: parent.right
            // fixed line positions shared with the idle layout
            y: root.smallTile + Math.round(14 * root.u)
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

        // idle mirrors the playing layout: same tile, label row, IDLE on the title line
        Rectangle {
            visible: !root.hasMedia
            width: root.smallTile; height: width
            radius: root.innerRadius
            color: Theme.bg
            DotGlyph {
                anchors.centerIn: parent
                width: parent.width * 0.72; height: width
                icon: "vinyl"
                dimColor: "transparent"
                litColor: Theme.fg2
                halfColor: Theme.fg2
                redColor: Theme.fg2              // no red while idle
            }
        }
        Column {
            visible: !root.hasMedia
            y: band.y
            spacing: band.spacing
            Status { bottomPadding: Math.round(2 * root.u) }
            DotString {
                text: "IDLE"
                pitch: 5
                width: implicitWidth; height: implicitHeight
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
            color: Theme.bg
            DotGlyph {
                anchors.centerIn: parent
                width: parent.width * 0.62; height: width
                visible: !artWide.ready
                icon: root.hasMedia ? "note" : "vinyl"
                redColor: Theme.fg2
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
            // round dots with clear gaps: 7px cells, dots ≤ 0.7 of a cell
            pitch: 7
            maxDot: 0.7
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

            // idle: "● NO MEDIA" on the label line, IDLE centred on the play-button line
            Status {
                id: idleStatus
                visible: !root.hasMedia
                y: Math.round(2 * root.u)
            }
            DotString {
                visible: !root.hasMedia
                anchors.verticalCenter: parent.bottom
                anchors.verticalCenterOffset: -Math.round(46 * root.u) / 2
                text: "IDLE"
                pitch: 5
                width: implicitWidth; height: implicitHeight
            }
        }
    }
}
