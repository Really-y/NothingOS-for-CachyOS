import QtQuick

// HH:mm in dot matrix. Inline: two real colon dots (optionally red).
// Stacked: hours above minutes, no colon — Nothing's square clock.
Item {
    id: root
    property string hours: "00"
    property string minutes: "00"
    property real size: 80
    property bool stacked: false
    property color color: Theme.fg
    property color colonColor: color
    property real dotRatio: 0.75
    readonly property real pitch: size / 10
    // gap between stacked rows: two empty dot rows
    readonly property real rowGap: 2 * pitch + (pitch - pitch * dotRatio)

    implicitWidth: stacked ? Math.max(h.implicitWidth, m.implicitWidth) : line.implicitWidth
    implicitHeight: stacked ? h.implicitHeight + rowGap + m.implicitHeight : line.implicitHeight

    // Widths for fitting before layout (hh:mm = 25 columns, stacked hh = 11).
    function inlineWidthFor(sz) { return line.widthFor(sz); }
    function stackedHeightFor(sz) { return (6 + dotRatio) * sz / 10 * 2 + (3 - dotRatio) * sz / 10; }

    DotString {
        id: line
        visible: !root.stacked
        text: root.hours + ":" + root.minutes
        size: root.size; color: root.color; colonColor: root.colonColor; dotRatio: root.dotRatio
        width: implicitWidth; height: implicitHeight
    }
    DotString {
        id: h
        visible: root.stacked
        text: root.hours
        size: root.size; color: root.color; dotRatio: root.dotRatio
        width: implicitWidth; height: implicitHeight
    }
    DotString {
        id: m
        visible: root.stacked
        y: h.implicitHeight + root.rowGap
        text: root.minutes
        size: root.size; color: root.color; dotRatio: root.dotRatio
        width: implicitWidth; height: implicitHeight
    }
}
