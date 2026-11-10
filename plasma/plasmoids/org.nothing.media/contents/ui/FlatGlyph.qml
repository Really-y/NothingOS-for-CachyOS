import QtQuick
import "nothing"

// Flat, drawn transport glyphs (no icon font): play, pause, prev, next.
Canvas {
    id: root
    property string glyph: "play"
    property color color: Theme.fg
    implicitWidth: 20
    implicitHeight: 20
    onGlyphChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const s = Math.min(width, height), ox = (width - s) / 2, oy = (height - s) / 2;
        c.fillStyle = root.color;
        c.strokeStyle = root.color;
        c.lineJoin = "round";
        c.lineWidth = s * 0.08;
        const tri = (x0, xTip, h) => {          // triangle from base x0 to tip xTip
            c.beginPath();
            c.moveTo(ox + x0 * s, oy + (0.5 - h / 2) * s);
            c.lineTo(ox + xTip * s, oy + 0.5 * s);
            c.lineTo(ox + x0 * s, oy + (0.5 + h / 2) * s);
            c.closePath();
            c.fill(); c.stroke();
        };
        const bar = (x, w, h) => {
            const r = w * s / 2;
            c.beginPath();
            c.roundedRect(ox + x * s, oy + (0.5 - h / 2) * s, w * s, h * s, r, r);
            c.fill();
        };
        switch (glyph) {
        case "play":  tri(0.2, 0.86, 0.72); break;
        case "pause": bar(0.2, 0.2, 0.72); bar(0.6, 0.2, 0.72); break;
        case "next":  tri(0.12, 0.7, 0.66); bar(0.72, 0.13, 0.66); break;
        case "prev":  tri(0.88, 0.3, 0.66); bar(0.15, 0.13, 0.66); break;
        }
    }
}
