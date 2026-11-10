import QtQuick
import "nothing"

// Image with rounded corners that works on every scene-graph backend:
// the corners are painted over in the card colour instead of using a shader mask.
Item {
    id: root
    property alias source: img.source
    property real radius: 20
    property color matte: Theme.card
    readonly property bool ready: img.status === Image.Ready

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: Math.max(64, root.width * 2)
        sourceSize.height: Math.max(64, root.height * 2)
        opacity: root.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }
    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"), w = width, h = height, r = Math.min(root.radius, w / 2, h / 2);
            c.reset();
            c.fillStyle = root.matte;
            c.beginPath();
            c.rect(0, 0, w, h);
            // inner rounded rect, wound the other way → evenodd hole
            c.moveTo(r, 0);
            c.arcTo(0, 0, 0, r, r);
            c.lineTo(0, h - r);
            c.arcTo(0, h, r, h, r);
            c.lineTo(w - r, h);
            c.arcTo(w, h, w, h - r, r);
            c.lineTo(w, r);
            c.arcTo(w, 0, w - r, 0, r);
            c.closePath();
            c.fill("evenodd");
        }
    }
}
