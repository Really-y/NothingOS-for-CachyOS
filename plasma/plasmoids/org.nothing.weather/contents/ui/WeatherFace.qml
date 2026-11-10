import QtQuick
import "nothing"

// Square weather card. Pure view; null values render as "--".
Card {
    id: root
    property var temp: null          // number (°C) or null
    property var hi: null
    property var lo: null
    property string icon: "cloud"
    property string desc: ""
    property string city: ""

    readonly property real u: Math.max(0.5, Math.min(width, height) / 180)
    readonly property int pad: Math.round(20 * u)
    function deg(v) { return (v === null || v === undefined || isNaN(v)) ? "--" : Math.round(v) + "°"; }

    implicitWidth: 180
    implicitHeight: 180

    Icon {
        id: glyph
        x: root.pad - Math.round(3 * root.u); y: root.pad - Math.round(3 * root.u)
        name: root.temp === null ? "cloud_off" : (root.icon || "cloud")
        size: Math.round(34 * root.u)
        color: root.temp === null ? Theme.fg3 : Theme.fg
    }
    Label {
        anchors.right: parent.right; anchors.rightMargin: root.pad
        anchors.verticalCenter: glyph.verticalCenter
        width: parent.width - 2 * root.pad - glyph.width - 8
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        size: Math.max(10, Math.round(11 * root.u))
        text: root.city || "--"
    }

    // Big dot-matrix temperature with a small ring as the degree mark.
    Row {
        id: big
        x: root.pad - Math.round(3 * root.u)
        anchors.bottom: footer.top; anchors.bottomMargin: Math.round(4 * root.u)
        spacing: Math.round(4 * root.u)
        DotText {
            id: digits
            size: Math.round(64 * root.u)
            weight: 800
            text: root.temp === null ? "--" : Math.round(root.temp)
            color: root.temp === null ? Theme.fg3 : Theme.fg
        }
        Rectangle {
            visible: root.temp !== null
            y: Math.round(digits.height * 0.22)
            width: Math.round(11 * root.u); height: width; radius: width / 2
            color: "transparent"
            border.color: Theme.fg; border.width: Math.max(2, Math.round(2.5 * root.u))
        }
    }
    Column {
        anchors.right: parent.right; anchors.rightMargin: root.pad
        anchors.bottom: big.bottom; anchors.bottomMargin: Math.round(14 * root.u)
        spacing: Math.round(4 * root.u)
        Label { anchors.right: parent.right; size: Math.max(10, Math.round(11 * root.u)); text: "H " + root.deg(root.hi) }
        Label { anchors.right: parent.right; size: Math.max(10, Math.round(11 * root.u)); color: Theme.fg3; text: "L " + root.deg(root.lo) }
    }

    Label {
        id: footer
        x: root.pad; width: parent.width - 2 * root.pad
        anchors.bottom: parent.bottom; anchors.bottomMargin: root.pad
        elide: Text.ElideRight
        size: Math.max(10, Math.round(11 * root.u))
        color: Theme.fg
        text: root.temp === null ? "NO DATA" : root.desc
    }
}
