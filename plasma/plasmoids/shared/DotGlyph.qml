import QtQuick
import "doticons.js" as DotIcons

// Pictogram drawn on a dot grid. Use `icon` (see doticons.js) or raw `rows`.
// The grid is centred and scaled to fit; unlit grid dots stay faintly visible.
Canvas {
    id: root
    property string icon: ""
    property var rows: DotIcons.icons[icon] || []
    property color litColor: Theme.fg
    property color halfColor: Theme.fg2
    property color redColor: Theme.red
    property color dimColor: Theme.dotDim
    property real dotRatio: 0.72
    readonly property int nRows: rows.length
    readonly property int nCols: nRows ? rows[0].length : 0
    readonly property real pitch: nRows ? Math.min(width / nCols, height / nRows) : 0

    implicitWidth: 110
    implicitHeight: 110

    onRowsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onHalfColorChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        if (!nRows) return;
        const p = pitch, r = p * dotRatio / 2;
        const ox = (width - p * nCols) / 2, oy = (height - p * nRows) / 2;
        const col = { "#": litColor, "+": halfColor, "r": redColor, ".": dimColor };
        for (let y = 0; y < nRows; y++)
            for (let x = 0; x < nCols; x++) {
                const f = col[rows[y][x]];
                if (!f || f.a === 0) continue;
                c.beginPath();
                c.arc(ox + (x + 0.5) * p, oy + (y + 0.5) * p, r, 0, Math.PI * 2);
                c.fillStyle = f;
                c.fill();
            }
    }
}
