/*
    Nothing OS style KSplash.

    Black screen, a dot-matrix wordmark and a row of dots that fill in as
    Plasma reports start-up stages. The last dot turns red when the desktop is
    ready, then everything fades out to black.

    ksplashqml sets `stage` (1 = initial ... ~6 = ready). Like the Breeze splash,
    nothing here depends on the number of stages being exact.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Rectangle {
    id: root
    color: "#000000"

    property int stage: 0

    // Wordmark: our own dot-matrix word, not a brand logo.
    property string wordmark: "hello"

    // Design tokens (kept local: the splash runs before anything else exists).
    readonly property color fg: "#ffffff"
    readonly property color fg3: "#5e5e5e"
    readonly property color off: "#262626"
    readonly property color red: "#d71921"
    readonly property var emphasized: [0.05, 0.7, 0.1, 1.0, 1, 1]
    readonly property var accelerate: [0.3, 0.0, 0.8, 0.15, 1, 1]

    readonly property int dotCount: 7
    readonly property int dotSize: Math.round(Math.max(10, Math.min(width, height) * 0.014))
    readonly property bool done: stage >= 5
    // Dots 0..dotCount-2 are white progress; the last dot is the red "ready" dot.
    readonly property int lit: done ? dotCount - 1
                                    : Math.max(0, Math.min(dotCount - 2, Math.round((stage - 1) / 4 * (dotCount - 1))))

    onDoneChanged: if (done) outro.restart()

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Column {
            id: centre
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -root.height * 0.02
            spacing: root.dotSize * 4

            Text {
                id: mark
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.wordmark
                color: root.fg
                renderType: Text.QtRendering
                font.family: "Doto"
                readonly property int px: Math.round(Math.min(root.width, root.height) * 0.11)
                font.pixelSize: px
                font.variableAxes: ({ "ROND": 100, "wght": 800 })
                font.letterSpacing: px * 0.04
                transform: Translate { id: markShift; y: 14 }
            }

            Row {
                id: dots
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.dotSize * 1.4

                Repeater {
                    model: root.dotCount
                    Rectangle {
                        id: dot
                        required property int index
                        readonly property bool isLast: index === root.dotCount - 1
                        readonly property bool isLit: isLast ? root.done : index < root.lit
                        // The next dot to fill "breathes" so the screen never looks frozen.
                        readonly property bool isNext: !root.done && index === root.lit

                        width: root.dotSize; height: width; radius: width / 2
                        color: isLit ? (isLast ? root.red : root.fg) : root.off
                        scale: isLast && root.done ? 1.0 : (isLast ? 0.8 : 1.0)
                        Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasized } }
                        Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; epsilon: 0.005 } }

                        onIsNextChanged: if (!isNext) opacity = 1
                        SequentialAnimation on opacity {
                            running: dot.isNext
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.35; duration: 520; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.35; to: 1; duration: 520; easing.type: Easing.InOutSine }
                        }
                        // While waiting, the "next" dot is drawn in grey-white so it reads as "loading".
                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: "#8e8e8e"
                            visible: dot.isNext
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(root.height * 0.06)
            text: "PLASMA  ·  CACHYOS"
            color: root.fg3
            font.family: "Space Mono"
            font.pixelSize: Math.max(11, Math.round(root.height * 0.013))
            font.letterSpacing: 2.4
        }
    }

    // Entry: soft fade + the wordmark settling up into place.
    ParallelAnimation {
        id: intro
        running: true
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasized }
        NumberAnimation { target: markShift; property: "y"; from: 14; to: 0; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasized }
    }

    // Exit: hold the completed row for a beat, then fade to black.
    SequentialAnimation {
        id: outro
        PauseAnimation { duration: 650 }
        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.accelerate }
    }
}
