import QtQuick

// Nothing widget surface: flat #1a1a1a, no border, big radius.
// Inner elements should use `innerRadius` (outer radius − padding) so corners stay concentric.
Rectangle {
    property int padding: 20
    readonly property real innerRadius: Math.max(0, radius - padding)
    radius: 30
    color: Theme.widget
    border.width: 0
}
