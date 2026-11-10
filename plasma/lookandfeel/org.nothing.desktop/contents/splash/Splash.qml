/*
    Nothing OS style KSplash.

    Black screen, a dot-matrix wordmark drawn dot by dot (5×7 Doto grid, same
    bitmaps as the shared kit's DotString) that reveals left → right, and a
    row of larger progress dots sitting on the same grid. Progress dots fill
    white as Plasma reports start-up stages; the last one turns red when the
    desktop is ready, then everything fades to black.

    ksplashqml sets `stage` (1 = initial ... ~6 = ready). Like the Breeze splash,
    nothing here depends on the number of stages being exact.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import "dotfont.js" as DotFont

Rectangle {
    id: root
    color: "#000000"

    property int stage: 0

    // Wordmark: our own dot-matrix word, not a brand logo (dotfont has A–Z, 0–9).
    property string wordmark: "HELLO"

    // Design tokens (kept local: the splash runs before anything else exists).
    readonly property color fg: "#ffffff"
    readonly property color fg3: "#5e5e5e"
    readonly property color off: "#262626"
    readonly property color red: "#d71921"
    readonly property var emphasized: [0.05, 0.7, 0.1, 1.0, 1, 1]
    readonly property var accelerate: [0.3, 0.0, 0.8, 0.15, 1, 1]

    // ── grid ────────────────────────────────────────────────────────────────
    readonly property real pitch: Math.round(Math.max(6, Math.min(width, height) * 0.0145))
    readonly property real dot: pitch * 0.75                 // wordmark dot
    readonly property real bigDot: dot * 2                   // progress dot = 2× wordmark dot
    readonly property real bigPitch: pitch * 4                // progress dots sit on wordmark columns 2 + 4·i

    // Wordmark dot positions in grid units: [{c, r}], plus total columns.
    readonly property var cells: {
        const out = [];
        let x0 = 0;
        const s = String(wordmark);
        for (let i = 0; i < s.length; i++) {
            const g = DotFont.glyph(s[i]);
            const w = g[0].length;
            for (let r = 0; r < 7; r++)
                for (let c = 0; c < w; c++)
                    if (g[r][c] === "#") out.push({ c: x0 + c, r: r });
            x0 += w + 1;
        }
        return out;
    }
    readonly property int columns: {
        let n = 0;
        const s = String(wordmark);
        for (let i = 0; i < s.length; i++) n += DotFont.glyph(s[i])[0].length + (i ? 1 : 0);
        return n;
    }

    // ── progress ────────────────────────────────────────────────────────────
    readonly property int dotCount: 7
    readonly property bool done: stage >= 5
    // Dots 0..dotCount-2 are white progress; the last dot is the red "ready" dot.
    readonly property int lit: done ? dotCount - 1
                                    : Math.max(0, Math.min(dotCount - 2, Math.round((stage - 1) / 4 * (dotCount - 1))))

    // 0 → 1 drives the left-to-right dot-in reveal of the wordmark.
    property real reveal: 0

    onDoneChanged: if (done) outro.restart()

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        // Grid box: 7 wordmark rows, 4 empty rows, one progress row (centred on grid row 12).
        Item {
            id: grid
            readonly property real progressRow: 12
            width: (root.columns - 1) * root.pitch + root.dot
            height: root.progressRow * root.pitch + root.bigDot / 2 + root.dot / 2
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -Math.round(root.height * 0.02)

            Repeater {
                model: root.cells
                Rectangle {
                    required property var modelData
                    readonly property real xNorm: root.columns > 1 ? modelData.c / (root.columns - 1) : 0
                    x: modelData.c * root.pitch
                    y: modelData.r * root.pitch
                    width: root.dot; height: width; radius: width / 2
                    color: root.fg
                    // Each dot fades in as the reveal front passes its column.
                    opacity: Math.max(0, Math.min(1, (root.reveal * 1.3 - xNorm) / 0.3))
                }
            }

            Item {
                id: progress
                anchors.fill: parent

                Repeater {
                    model: root.dotCount
                    Rectangle {
                        id: pdot
                        required property int index
                        // centred under wordmark column 2 + 4·i, on grid row `progressRow`
                        x: (2 + index * 4) * root.pitch + root.dot / 2 - root.bigDot / 2
                        y: grid.progressRow * root.pitch + root.dot / 2 - root.bigDot / 2
                        readonly property bool isLast: index === root.dotCount - 1
                        readonly property bool isLit: isLast ? root.done : index < root.lit
                        // The next dot to fill breathes in grey so the screen never looks frozen.
                        readonly property bool isNext: !root.done && index === root.lit

                        width: root.bigDot; height: width; radius: width / 2
                        color: isLit ? (isLast ? root.red : root.fg) : (isNext ? pulseColor : root.off)
                        property color pulseColor: root.off
                        Behavior on color { enabled: !pdot.isNext; ColorAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasized } }

                        SequentialAnimation on pulseColor {
                            running: pdot.isNext
                            loops: Animation.Infinite
                            ColorAnimation { from: root.off; to: "#8e8e8e"; duration: 520; easing.type: Easing.InOutSine }
                            ColorAnimation { from: "#8e8e8e"; to: root.off; duration: 520; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            text: "PLASMA  ·  CACHYOS"
            color: root.fg3
            font.family: "Space Mono"
            font.pixelSize: 11
            font.letterSpacing: 2.4
        }
    }

    // Entry: fade in, then the wordmark's dots reveal left → right (~600 ms).
    ParallelAnimation {
        id: intro
        running: true
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasized }
        SequentialAnimation {
            PauseAnimation { duration: 80 }
            NumberAnimation { target: root; property: "reveal"; from: 0; to: 1; duration: 600; easing.type: Easing.Linear }
        }
    }

    // Exit: hold the completed row for a beat, then fade to black.
    SequentialAnimation {
        id: outro
        PauseAnimation { duration: 650 }
        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.accelerate }
    }
}
