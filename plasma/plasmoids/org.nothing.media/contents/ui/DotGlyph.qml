import QtQuick
import "nothing"

// 9×9 dot-matrix music note; unlit dots stay faintly visible as a grid.
Canvas {
    id: root
    property color lit: Theme.fg2
    property color unlit: Theme.card3
    readonly property var pattern: [
        ".........",
        "...XXXXX.",
        "...X...X.",
        "...X...X.",
        "...X...X.",
        ".XXX.XXX.",
        ".XXX.XXX.",
        ".........",
        "........."
    ]
    onLitChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        const n = 9, step = Math.min(width, height) / n, r = step * 0.32;
        const ox = (width - step * n) / 2, oy = (height - step * n) / 2 + step / 2;
        for (let y = 0; y < n; y++)
            for (let x = 0; x < n; x++) {
                c.beginPath();
                c.arc(ox + (x + 0.5) * step, oy + (y + 0.5) * step - step / 2, r, 0, Math.PI * 2);
                c.fillStyle = pattern[y][x] === "X" ? lit : unlit;
                c.fill();
            }
    }
}
