import QtQuick
import "nothing"

// Hover label: Space Mono caps in a small flat pill. Used inline by the previews and
// inside a background-less PlasmaCore.Dialog by the plasmoid (it has to leave the panel).
Rectangle {
    id: root
    property string text: ""
    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight
    radius: height / 2
    color: Theme.widget

    Text {
        id: label
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: font.letterSpacing / 2   // trailing tracking
        text: root.text
        color: Theme.fg
        font.family: Theme.mono
        font.pixelSize: 11
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 260)
    }
}
