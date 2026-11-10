import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "nothing"

// Nothing system card: CPU / RAM dot gauges from nothingd Stats() every 2 s.
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    NothingDaemon {
        id: stats
        member: "Stats"
        interval: 2000
        retryInterval: 5000
    }
    readonly property var s: stats.result

    toolTipMainText: i18n("System")
    toolTipSubText: s ? ("CPU " + Math.round(s.cpu * 100) + "%  ·  RAM " + Math.round(s.mem * 100) + "%")
                      : i18n("Waiting for nothingd…")

    fullRepresentation: SystemFace {
        Layout.minimumWidth: 150
        Layout.minimumHeight: 150
        Layout.preferredWidth: 180
        Layout.preferredHeight: 180
        cpu: root.s ? root.s.cpu : null
        mem: root.s ? root.s.mem : null
        memUsedGb: root.s ? root.s.memUsedGb : null
        memTotalGb: root.s ? root.s.memTotalGb : null
        tempC: root.s && root.s.tempC !== undefined ? root.s.tempC : null
    }
}
