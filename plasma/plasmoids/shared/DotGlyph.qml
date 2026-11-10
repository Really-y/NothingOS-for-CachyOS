import QtQuick
import "doticons.js" as DotIcons

// Pictogram drawn on a dot grid. Use `icon` (see doticons.js) or raw `rows`.
// The grid is centred and scaled to fit; unlit grid dots stay faintly visible.
Canvas {
    id: root
    property string icon: ""
    property var rows: DotIcons.icons[icon] || []
    // Drop leading rows without lit dots so the first lit row sits at the top
    // (for aligning with a caption's cap height).
    property bool trimTop: false
    property bool trimBottom: false
    readonly property var shown: {
        let r = rows || [], i = 0, j = r.length;
        if (trimTop) while (i < j - 1 && !/[#+r]/.test(r[i])) i++;
        if (trimBottom) while (j > i + 1 && !/[#+r]/.test(r[j - 1])) j--;
        return r.slice(i, j);
    }
    // natural height for a given width (keeps square cells)
    function heightForWidth(w) { return nCols ? w / nCols * nRows : 0; }
    property color litColor: Theme.fg
    property color halfColor: Theme.fg2
    property color redColor: Theme.red
    property color dimColor: Theme.dotDim
    property real dotRatio: Theme.dotRatio
    property bool alignTop: false      // pin the grid to the top edge instead of centring
    // snap: whole-pixel pitch, dot centres on pixel centres, dots ≥ minDot px —
    // for small glyphs that would otherwise blur into a grey grille.
    property bool snap: false
    property real minDot: 3
    smooth: !snap          // snapped glyphs: nearest sampling, no halo at fractional positions
    readonly property int nRows: shown.length
    readonly property int nCols: nRows ? shown[0].length : 0
    readonly property real pitch: nRows ? (snap ? Math.max(1, Math.floor(Math.min(width / nCols, height / nRows)))
                                                 : Math.min(width / nCols, height / nRows)) : 0

    implicitWidth: 110
    implicitHeight: 110

    onShownChanged: requestPaint()
    onRedColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onHalfColorChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        if (!nRows) return;
        const p = pitch, r = snap ? Math.max(minDot, p * dotRatio) / 2 : p * dotRatio / 2;
        if (!(r > 0)) return;
        let ox = (width - p * nCols) / 2, oy = alignTop ? 0 : (height - p * nRows) / 2;
        if (snap) { ox = Math.round(ox); oy = Math.round(oy); }
        const cxOf = (x) => snap ? Math.floor(ox + (x + 0.5) * p) + 0.5 : ox + (x + 0.5) * p;
        const cyOf = (y) => snap ? Math.floor(oy + (y + 0.5) * p) + 0.5 : oy + (y + 0.5) * p;
        const col = { "#": litColor, "+": halfColor, "r": redColor, ".": dimColor };
        for (let y = 0; y < nRows; y++)
            for (let x = 0; x < nCols; x++) {
                const f = col[shown[y][x]];
                if (!f || f.a === 0) continue;
                if (snap && r * 2 <= 4) {
                    // whole-pixel 3×3 disc stamp: no antialias fringe between dots
                    const x0 = Math.floor(cxOf(x)) - 1, y0 = Math.floor(cyOf(y)) - 1;
                    c.fillStyle = f;
                    c.fillRect(x0 + 1, y0, 1, 3);
                    c.fillRect(x0, y0 + 1, 3, 1);
                    c.fillStyle = Qt.rgba(f.r, f.g, f.b, f.a * 0.85);
                    c.fillRect(x0, y0, 1, 1); c.fillRect(x0 + 2, y0, 1, 1);
                    c.fillRect(x0, y0 + 2, 1, 1); c.fillRect(x0 + 2, y0 + 2, 1, 1);
                    continue;
                }
                c.beginPath();
                c.arc(cxOf(x), cyOf(y), r, 0, Math.PI * 2);
                c.fillStyle = f;
                c.fill();
            }
    }
}
