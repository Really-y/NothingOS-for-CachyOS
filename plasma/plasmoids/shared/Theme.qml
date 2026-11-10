pragma Singleton
import QtQuick


// Nothing OS design tokens: monochrome + one red, dot-matrix display type.
QtObject {
    readonly property color bg: "#000000"
    readonly property color card: "#111111"
    readonly property color card2: "#1c1c1c"
    readonly property color card3: "#262626"
    readonly property color line: "#2a2a2a"
    readonly property color fg: "#ffffff"
    readonly property color fg2: "#8e8e8e"
    readonly property color fg3: "#5e5e5e"
    readonly property color red: "#d71921"

    readonly property string dot: "Doto"
    readonly property string sans: "Space Grotesk"
    readonly property string mono: "Space Mono"
    readonly property string icons: "Material Symbols Rounded"

    readonly property int r: 24      // card radius
    readonly property int rSmall: 14
    readonly property int gap: 10

    // Motion: quick, decisive entry; soft settle. Exits are faster than entries.
    readonly property int fast: 140
    readonly property int normal: 260
    readonly property int slow: 420
    readonly property var emphasized: [0.05, 0.7, 0.1, 1.0, 1, 1]   // enter
    readonly property var accelerate: [0.3, 0.0, 0.8, 0.15, 1, 1]   // exit
    readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1, 1]

}
