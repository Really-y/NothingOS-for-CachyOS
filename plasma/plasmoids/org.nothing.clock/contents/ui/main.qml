import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "nothing"

// Nothing clock. Desktop: big dot-matrix card. Panel: HH:mm in Doto, popup
// with the big clock and a month grid.
PlasmoidItem {
    id: root

    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                    || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool use24h: Plasmoid.configuration.use24h
    property var now: new Date()

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    toolTipMainText: Qt.formatDate(now, Qt.locale().dateFormat(Locale.LongFormat))
    toolTipSubText: ""

    Timer {
        // Tick on the second boundary so the dot row and minute flip stay in sync.
        interval: 1000 - (new Date()).getMilliseconds() % 1000 + 5
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: { root.now = new Date(); interval = 1000 - root.now.getMilliseconds() + 5; }
    }

    compactRepresentation: MouseArea {
        id: compact
        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        // Plain dots on the panel, no box: digit height ≈ 55% of panel thickness,
        // pitch snapped to whole pixels so the dots stay crisp.
        readonly property real thickness: vertical ? width / 2.2 : height
        Layout.minimumWidth: vertical ? -1 : label.implicitWidth + 16
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: vertical ? label.implicitHeight + 10 : -1
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        // Dot type below 40px turns to mush; the panel uses Space Mono.
        Text {
            id: label
            anchors.centerIn: parent
            text: root.use24h ? Qt.formatTime(root.now, "HH:mm") : Qt.formatTime(root.now, "h:mm")
            color: Theme.fg
            font.family: Theme.mono
            font.bold: true
            font.pixelSize: Math.max(11, Math.round(compact.thickness * 0.42))
            font.letterSpacing: 0.5
            opacity: compact.containsMouse || root.expanded ? 1 : 0.92
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: root.inPanel ? 360 : 150
        Layout.minimumHeight: root.inPanel ? 520 : 75
        Layout.preferredWidth: 360
        Layout.preferredHeight: root.inPanel ? 520 : 180

        ClockFace {
            id: face
            width: parent.width
            height: root.inPanel ? 180 : parent.height
            now: root.now
            use24h: root.use24h
            showSeconds: Plasmoid.configuration.showSeconds
            variant: root.inPanel ? "wide" : "auto"
        }
        Loader {
            active: root.inPanel
            anchors.top: face.bottom; anchors.topMargin: Theme.gap
            width: parent.width
            height: parent.height - face.height - Theme.gap
            sourceComponent: DotCalendar {
                id: cal
                today: root.now
                Connections {
                    target: root
                    function onExpandedChanged() { if (root.expanded) cal.reset(); }
                }
            }
        }
    }
}
