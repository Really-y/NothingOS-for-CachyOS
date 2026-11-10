import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.system/contents/ui" as S

// System: squares (normal, hot CPU + temp warning, no sensor, offline) and wide variants.
Rectangle {
    color: Theme.bg
    Column {
        x: 24; y: 24; spacing: 16
        Row {
            spacing: 16
            S.SystemFace { width: 180; height: 180; cpu: 0.23; mem: 0.41; memUsedGb: 6.5; memTotalGb: 15.6; tempC: 48 }
            S.SystemFace { width: 180; height: 180; cpu: 0.93; mem: 0.67; memUsedGb: 10.4; memTotalGb: 15.6; tempC: 87.2 }
            S.SystemFace { width: 180; height: 180; cpu: 0.05; mem: 0.3; memUsedGb: 4.7; memTotalGb: 15.6 }
            S.SystemFace { width: 180; height: 180 }
        }
        Row {
            spacing: 16
            S.SystemFace { width: 360; height: 180; cpu: 0.23; mem: 0.41; memUsedGb: 6.5; memTotalGb: 15.6; tempC: 48 }
            S.SystemFace { width: 360; height: 180; cpu: 1.0; mem: 0.88; memUsedGb: 13.7; memTotalGb: 15.6; tempC: 91 }
        }
        S.SystemFace { width: 360; height: 180 }
    }
}
