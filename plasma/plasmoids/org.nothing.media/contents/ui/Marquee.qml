import QtQuick
import "nothing"

// Single line of text that scrolls back and forth when it does not fit —
// never an ellipsis. At rest an overflowing line is cut on a whole-glyph
// boundary and fades out over the last `fade` px (no half-glyph ticks).
Item {
    id: root
    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    property color fadeColor: Theme.widget   // background the edges fade into
    property int fade: 24
    readonly property bool overflow: label.implicitWidth > width + 1
    readonly property bool atRest: label.x > -0.5
    // x where the last glyph that fits completely ends
    readonly property real glyphEdge: {
        if (!overflow) return width;
        const t = label.text;
        let lo = 0, hi = t.length;           // longest prefix that fits
        while (lo < hi) {
            const mid = Math.ceil((lo + hi) / 2);
            if (fm.advanceWidth(t.slice(0, mid)) <= width) lo = mid; else hi = mid - 1;
        }
        // don't end on a space: the fade should land on a glyph
        let n = lo;
        while (n > 1 && t[n - 1] === " ") n--;
        return Math.max(0, Math.min(width, fm.advanceWidth(t.slice(0, n))));
    }
    implicitHeight: label.implicitHeight
    FontMetrics { id: fm; font: label.font }

    Item {
        id: clipper
        width: root.overflow && root.atRest ? root.glyphEdge : root.width
        height: parent.height
        clip: true
        Text {
            id: label
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            onTextChanged: { anim.restart(); }
        }
    }
    Rectangle {
        anchors.left: parent.left
        width: root.fade; height: parent.height
        visible: !root.atRest
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.fadeColor }
            GradientStop { position: 1; color: Qt.rgba(root.fadeColor.r, root.fadeColor.g, root.fadeColor.b, 0) }
        }
    }
    Rectangle {
        x: clipper.width - width
        width: root.fade; height: parent.height
        visible: label.x + label.implicitWidth > clipper.width + 0.5
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(root.fadeColor.r, root.fadeColor.g, root.fadeColor.b, 0) }
            GradientStop { position: 1; color: root.fadeColor }
        }
    }
    SequentialAnimation {
        id: anim
        running: root.overflow && root.visible
        loops: Animation.Infinite
        onStopped: label.x = 0
        PauseAnimation { duration: 2200 }
        NumberAnimation {
            target: label; property: "x"; to: -(label.implicitWidth - root.width)
            duration: Math.max(1200, (label.implicitWidth - root.width) * 28)
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 1600 }
        NumberAnimation {
            target: label; property: "x"; to: 0
            duration: Math.max(800, (label.implicitWidth - root.width) * 14)
            easing.type: Easing.InOutSine
        }
    }
}
