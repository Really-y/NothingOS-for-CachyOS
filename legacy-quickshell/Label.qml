import QtQuick

// Small caps-style mono label (section headers, metadata).
Text {
    property int size: 11
    color: Theme.fg2
    font.family: Theme.mono
    font.pixelSize: size
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.2
}
