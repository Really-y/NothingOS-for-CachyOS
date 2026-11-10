import QtQuick

// Desktop widget surface. size: 1 = square, 2 = wide.
Rectangle {
    property int span: 1
    readonly property int unit: 168
    width: span === 2 ? unit * 2 + Theme.gap : unit
    height: unit
    radius: 30
    color: Theme.card
    border.color: Theme.line; border.width: 1
}
