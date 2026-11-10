import QtQuick
import "dotfont.js" as DotFont

// Dot-matrix text drawn dot by dot from Doto's 5×7 grid: crisp at any size,
// tabular digits, a real two-dot colon, 3-dot minus and a dot-ring degree.
//
// Sizing API (pick one):
//   pitch: 8          — dot pitch in px (centre to centre). Use Theme.dotPitch(max)
//                       to snap to the house steps 5 / 8 / 12 / 15.
//   size: 80          — legacy: Doto font px; pitch defaults to size / 10.
// Dot diameter = pitch × dotRatio (Theme.dotRatio = 0.65). Glyphs are 7 dots
// tall, digits 5 wide, one empty column between glyphs. The item's box is tight
// to the dots: width = (columns − 1 + dotRatio) × pitch, height = (6 + dotRatio) × pitch.
// fitPitch(maxWidth, maxPitch) returns the largest house pitch that fits.
Canvas {
    id: root
    property string text: ""
    property real size: 60
    property real dotRatio: Theme.dotRatio   // dot diameter / pitch
    property color color: Theme.fg
    property color colonColor: color         // e.g. Theme.red for a red clock colon
    property color dimColor: "transparent"   // unlit dots inside each glyph cell
    property real pitch: size / 10
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
    // Box size at a given pitch, and the legacy size-based variants.
    function widthAtPitch(p) { return columns > 0 ? ((columns - 1) + dotRatio) * p : 0; }
    function heightAtPitch(p) { return (6 + dotRatio) * p; }
    function widthFor(sz) { return widthAtPitch(sz / 10); }
    function heightFor(sz) { return heightAtPitch(sz / 10); }
    // Largest house pitch (5/8/12/15) ≤ maxPitch whose width fits maxWidth.
    function fitPitch(maxWidth, maxPitch) {
        const steps = Theme.dotPitches;
        for (let i = steps.length - 1; i >= 0; i--)
            if (steps[i] <= maxPitch + 0.001 && widthAtPitch(steps[i]) <= maxWidth + 0.5) return steps[i];
        return steps[0];
    }

    implicitWidth: widthAtPitch(pitch)
    implicitHeight: heightAtPitch(pitch)

    onCellsChanged: requestPaint()
    onSizeChanged: requestPaint()
    onPitchChanged: requestPaint()
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
