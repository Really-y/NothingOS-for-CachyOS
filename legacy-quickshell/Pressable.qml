import QtQuick

// Base for anything clickable: subtle press-scale with a springy release.
MouseArea {
    id: root
    property real pressScale: 0.94
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    scale: pressed ? pressScale : 1
    Behavior on scale { SpringAnimation { spring: 6; damping: 0.42; epsilon: 0.002 } }
}
