import QtQuick

// HH:mm in dot matrix. Inline: two real colon dots (white by default).
// Size with `pitch` (house steps via Theme.dotPitch) or legacy `size` (= pitch × 10).
// Stacked: hours above minutes, no colon — Nothing's square clock.
Item {
    id: root
    property string hours: "00"
    property string minutes: "00"
    property real size: 80
    property bool stacked: false
    property color color: Theme.fg
    property color colonColor: color
    property real dotRatio: Theme.dotRatio
    property real pitch: size / 10
    // empty dot rows between stacked hours and minutes
    property int gapRows: 1
    readonly property real rowGap: gapRows * pitch + (pitch - pitch * dotRatio)

    implicitWidth: stacked ? Math.max(h.implicitWidth, m.implicitWidth) : line.implicitWidth
    implicitHeight: stacked ? h.implicitHeight + rowGap + m.implicitHeight : line.implicitHeight

    // Widths for fitting before layout (hh:mm = 25 columns, stacked hh = 11).
    function inlineWidthFor(sz) { return line.widthFor(sz); }
    function stackedHeightFor(sz) { return ((6 + dotRatio) * 2 + gapRows + 1 - dotRatio) * sz / 10; }
    function inlineWidthAtPitch(p) { return line.widthAtPitch(p); }
    function stackedWidthAtPitch(p) { return Math.max(h.widthAtPitch(p), m.widthAtPitch(p)); }
    function stackedHeightAtPitch(p) { return ((6 + dotRatio) * 2 + gapRows + 1 - dotRatio) * p; }

    DotString {
        id: line
        visible: !root.stacked
        text: root.hours + ":" + root.minutes
        pitch: root.pitch; color: root.color; colonColor: root.colonColor; dotRatio: root.dotRatio
        width: implicitWidth; height: implicitHeight
    }
    DotString {
        id: h
        visible: root.stacked
        text: root.hours
        pitch: root.pitch; color: root.color; dotRatio: root.dotRatio
        width: implicitWidth; height: implicitHeight
    }
    DotString {
        id: m
        visible: root.stacked
        y: h.implicitHeight + root.rowGap
        text: root.minutes
        pitch: root.pitch; color: root.color; dotRatio: root.dotRatio
        width: implicitWidth; height: implicitHeight
    }
}
