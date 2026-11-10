import QtQuick
import "dotfont.js" as DotFont

// Dot-matrix text drawn dot by dot from Doto's 5×7 grid: crisp at any size,
// tabular digits, a real two-dot colon, 3-dot minus and a dot-ring degree.
// `size` matches Doto's font px (dot pitch = size / 10); the item's box is
// tight to the dots (no ascender/descender padding).
Canvas {
    id: root
    property string text: ""
    property real size: 60
    property real dotRatio: 0.75             // dot diameter / pitch (Doto ≈ 0.75)
    property color color: Theme.fg
    property color colonColor: color         // e.g. Theme.red for a red clock colon
    property color dimColor: "transparent"   // unlit dots inside each glyph cell
    readonly property real pitch: size / 10
    readonly property real dot: pitch * dotRatio
    readonly property var cells: {
        const out = [];
        const s = String(text);
        for (let i = 0; i < s.length; i++) out.push(DotFont.glyph(s[i]));
        return out;
    }
    // Total dot columns including one gap column between glyphs.
    readonly property int columns: {
        let n = 0;
        for (let i = 0; i < cells.length; i++) n += cells[i][0].length + (i ? 1 : 0);
        return n;
    }
    // Width of the dot box for a given size (useful for fitting): (cols-1)·pitch + dot
    function widthFor(sz) { return columns > 0 ? ((columns - 1) + dotRatio) * sz / 10 : 0; }
    function heightFor(sz) { return (6 + dotRatio) * sz / 10; }

    implicitWidth: widthFor(size)
    implicitHeight: heightFor(size)

    onCellsChanged: requestPaint()
    onSizeChanged: requestPaint()
    onColorChanged: requestPaint()
    onColonColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const p = pitch, r = dot / 2;
        if (!(r > 0)) return;
        const s = String(text);
        let x0 = 0;
        for (let i = 0; i < cells.length; i++) {
            const g = cells[i], w = g[0].length;
            const lit = s[i] === ":" ? root.colonColor : root.color;
            for (let row = 0; row < 7; row++) {
                for (let col = 0; col < w; col++) {
                    const on = g[row][col] === "#";
                    if (!on && root.dimColor.a === 0) continue;
                    c.beginPath();
                    c.arc(x0 + col * p + r, row * p + r, r, 0, Math.PI * 2);
                    c.fillStyle = on ? lit : root.dimColor;
                    c.fill();
                }
            }
            x0 += (w + 1) * p;
        }
    }
}
