import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.milou as Milou

// KRunner (Alt+Space) mock built from the real Plasma pieces it uses, so it shows exactly what
// the Nothing desktop theme gives it: dialogs/background frame, PlasmaComponents3.TextField
// (widgets/lineedit), Milou.ResultDelegate rows + PlasmaExtras.Highlight (widgets/viewitem;
// the current row is the "hover" prefix, a pressed row "selected+hover") and
// PlasmaComponents3.ScrollBar (widgets/scrollbar). Layout mirrors krunner's RunCommand.qml.
// render: QT_QPA_PLATFORMTHEME=kde tools/render.sh previews/KRunnerPreview.qml previews/krunner.png 900 560
Rectangle {
    id: root
    color: "#000000"

    // wallpaper-ish backdrop so the dialog edge is visible
    Grid {
        anchors.centerIn: parent
        columns: 60; spacing: 13
        Repeater { model: 60 * 40; Rectangle { width: 2; height: 2; radius: 1; color: "#1a1a1a" } }
    }

    KSvg.FrameSvgItem {
        id: dialog
        imagePath: "dialogs/background"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 48
        width: 680
        height: column.implicitHeight + margins.top + margins.bottom

        ColumnLayout {
            id: column
            x: dialog.margins.left; y: dialog.margins.top
            width: dialog.width - dialog.margins.left - dialog.margins.right
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents3.ToolButton { icon.name: "configure"; display: PlasmaComponents3.AbstractButton.IconOnly }
                PlasmaComponents3.TextField {
                    id: query
                    Layout.fillWidth: true
                    text: "fi"
                    placeholderText: "Search…"
                    Component.onCompleted: { forceActiveFocus(); cursorPosition = text.length }
                }
                PlasmaComponents3.ToolButton { icon.name: "view-history"; display: PlasmaComponents3.AbstractButton.IconOnly }
                PlasmaComponents3.ToolButton { icon.name: "window-pin"; display: PlasmaComponents3.AbstractButton.IconOnly }
            }

            PlasmaComponents3.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                PlasmaComponents3.ScrollBar.vertical.policy: PlasmaComponents3.ScrollBar.AlwaysOn

                ListView {
                    id: list
                    clip: true
                    currentIndex: 0
                    highlightMoveDuration: 0
                    highlight: PlasmaExtras.Highlight {}
                    section.property: "category"
                    section.criteria: ViewSection.FullString
                    model: ListModel {
                        ListElement { display: "Firefox"; subtext: "Web Browser"; decoration: "firefox"; category: "Applications"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "Files"; subtext: "File Manager"; decoration: "org.kde.dolphin"; category: "Applications"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "Filelight"; subtext: "Disk usage"; decoration: "filelight"; category: "Applications"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "Find in files"; subtext: "Kate"; decoration: "kate"; category: "Applications"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "Firewall"; subtext: "System Settings"; decoration: "preferences-system"; category: "System Settings"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "finances.ods"; subtext: "~/Documents"; decoration: "x-office-spreadsheet"; category: "Files"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "fish"; subtext: "Run in terminal"; decoration: "utilities-terminal"; category: "Command Line"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "fi.wikipedia.org"; subtext: "Open URL"; decoration: "internet-web-browser"; category: "Web"; multiLine: false; isDuplicate: false; actions: [] }
                        ListElement { display: "Fira Code"; subtext: "Font"; decoration: "preferences-desktop-font"; category: "Fonts"; multiLine: false; isDuplicate: false; actions: [] }
                    }
                    delegate: Milou.ResultDelegate {
                        width: list.width
                        // row 2 shows the pressed state (selected+hover: white pill, black text)
                        down: index === 2
                        background: Item {
                            PlasmaExtras.Highlight {
                                anchors.fill: parent
                                visible: index === 2
                                pressed: true
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 }
        text: "KRUNNER · CURRENT ROW = VIEWITEM HOVER · PRESSED ROW = SELECTED+HOVER"
        font.family: "Space Mono"; font.pixelSize: 11; font.letterSpacing: 1.5
        color: "#5e5e5e"
    }
}
