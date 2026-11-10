import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.system/contents/ui" as S

// System card: normal load, hot CPU (red ring), no temperature sensor, daemon absent.
Rectangle {
    color: Theme.bg
    Row {
        x: 24; y: 24; spacing: 16
        S.SystemFace { width: 200; height: 200; cpu: 0.23; mem: 0.41; memUsedGb: 6.5; memTotalGb: 15.6; tempC: 48 }
        S.SystemFace { width: 200; height: 200; cpu: 0.93; mem: 0.67; memUsedGb: 10.4; memTotalGb: 15.6; tempC: 87.2 }
        S.SystemFace { width: 160; height: 160; cpu: 0.05; mem: 0.3; memUsedGb: 4.7; memTotalGb: 15.6 }
        S.SystemFace { width: 200; height: 200 }
    }
}
