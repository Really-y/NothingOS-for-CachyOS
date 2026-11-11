import QtQuick
import "nothing"
import "nothing/dotfont.js" as DotFont

// Fallback mark for apps without a Nothing icon: one 5×7 dot-matrix letter, antialiased
// round dots (≥ 3px) at ~22px cap height. Uses the house dot font, with a few glyphs
// redrawn so they read at this small size.
Canvas {
    id: root
    property string letter: "?"
    property real pitch: 3.5
    property real dot: 3
    property color color: Theme.fg
    readonly property var overrides: ({
        "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", ".#.#."],
        "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"]
    })
    readonly property var cells: overrides[letter] || DotFont.glyph(letter)
    implicitWidth: (cells[0].length - 1) * pitch + dot
    implicitHeight: 6 * pitch + dot
    width: implicitWidth
    height: implicitHeight
    antialiasing: true
    onCellsChanged: requestPaint()
    onColorChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.fillStyle = root.color;
        const r = dot / 2;
        for (let row = 0; row < cells.length; row++)
            for (let col = 0; col < cells[row].length; col++) {
                if (cells[row][col] !== "#") continue;
                c.beginPath();
                c.arc(col * pitch + r, row * pitch + r, r, 0, Math.PI * 2);
                c.fill();
            }
    }
}
