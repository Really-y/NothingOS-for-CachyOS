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
        Layout.minimumWidth: vertical ? -1 : label.implicitWidth + 12
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: vertical ? label.implicitHeight + 8 : -1
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        DotText {
            id: label
            anchors.centerIn: parent
            weight: 900
            // Fit the panel thickness (36px panel → 24px digits).
            size: Math.max(12, Math.round((compact.vertical ? compact.width / 3 : compact.height) * 0.66))
            text: (root.use24h ? Qt.formatTime(root.now, "HH:mm") : Qt.formatTime(root.now, "h:mm"))
            opacity: compact.containsMouse || root.expanded ? 1 : 0.92
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: root.inPanel ? 360 : 200
        Layout.minimumHeight: root.inPanel ? 510 : 100
        Layout.preferredWidth: 360
        Layout.preferredHeight: root.inPanel ? 510 : 180

        ClockFace {
            id: face
            width: parent.width
            height: root.inPanel ? 180 : parent.height
            now: root.now
            use24h: root.use24h
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
