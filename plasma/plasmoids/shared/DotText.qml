import QtQuick

// Dot-matrix display type (Doto with round dots), Nothing's signature look.
Text {
    renderType: Text.QtRendering
    property int size: 32
    property int weight: 700
    color: Theme.fg
    font.family: Theme.dot
    font.pixelSize: size
    font.variableAxes: ({ "ROND": 100, "wght": weight })
    font.letterSpacing: size * 0.02
}
