import QtQuick

// Material Symbols ligature icon, thin weight to match Nothing's line glyphs.
Text {
    property string name: ""
    property int size: 20
    property real fill: 0
    property int weight: 300
    text: name
    color: Theme.fg
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": weight, "opsz": Math.max(20, Math.min(48, size)), "GRAD": 0 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: Theme.fast } }
}
