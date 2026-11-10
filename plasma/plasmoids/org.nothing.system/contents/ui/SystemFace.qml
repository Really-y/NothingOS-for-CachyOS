import QtQuick
import "nothing"

// Nothing system card. Pure view; null values render "--".
//  square: one hero CPU dot ring (like Nothing's battery widget), RAM as caption
//  wide:   CPU and RAM rings side by side
// Red only for warnings: ring above 85 %, temperature above 80 °C.
Card {
    id: root
    property var cpu: null        // 0..1
    property var mem: null        // 0..1
    property var memUsedGb: null
    property var memTotalGb: null
    property var tempC: null      // optional
    property string variant: "auto"   // "auto" | "square" | "wide"

    readonly property bool wide: variant === "wide" || (variant === "auto" && width / Math.max(1, height) >= 1.5)
    readonly property real u: wide ? Math.min(width / 360, height / 180) : Math.min(width, height) / 180
    readonly property bool live: ok(cpu) && ok(mem)
    readonly property bool hasTemp: ok(tempC)
    readonly property bool hot: hasTemp && tempC > 80
    function ok(v) { return v !== null && v !== undefined && !isNaN(v); }
    function pct(v) { return ok(v) ? String(Math.round(v * 100)) : "--"; }

    padding: 20
    implicitWidth: 180
    implicitHeight: 180

    component Caption: Text {
        color: Theme.fg2
        font.family: Theme.mono
        font.pixelSize: Math.max(10, Math.round(10 * root.u))
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
    }

    component Gauge: Item {
        id: g
        property var value: null
        property real numberSize: 44
        DotRing {
            anchors.fill: parent
            value: root.ok(g.value) ? g.value : 0
            dots: 40
            dotSize: Math.max(3, 4 * root.u)
        }
        // fitColumns > 0: size for that many dot columns (17 = "100") so
        // neighbouring gauges share one number size.
        property int fitColumns: 0
        property real numberOffset: 0
        Row {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: pctSign.visible ? (pctSign.width + spacing) / 2 : 0
            anchors.verticalCenterOffset: g.numberOffset
            spacing: Math.round(3 * root.u)
            DotString {
                id: num
                text: root.pct(g.value)
                size: Math.min(g.numberSize, g.width * 0.58 * 10 / (Math.max(g.fitColumns || columns, 2) - 1 + dotRatio))
                color: root.ok(g.value) ? Theme.fg : Theme.fg3
                width: implicitWidth; height: implicitHeight
            }
            Text {
                id: pctSign
                visible: root.ok(g.value)
                text: "%"
                color: Theme.fg2
                font.family: Theme.mono
                font.pixelSize: Math.max(10, Math.round(num.size * 0.16))
                topPadding: -Math.round(font.pixelSize * 0.25)
            }
        }
    }

    // ── Square: hero CPU ring ─────────────────────────────────────────────
    Item {
        visible: !root.wide
        anchors.fill: parent
        anchors.margins: root.padding

        Gauge {
            id: hero
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height); height: width
            value: root.cpu
            numberSize: Math.max(40, Math.round(84 * root.u))
        }
        Row {
            anchors.horizontalCenter: hero.horizontalCenter
            anchors.verticalCenter: hero.verticalCenter
            anchors.verticalCenterOffset: -Math.round(48 * root.u)
            spacing: Math.round(6 * root.u)
            Caption { text: "CPU" }
            Caption {
                visible: root.hasTemp
                text: root.hasTemp ? Math.round(root.tempC) + "°C" : ""
                color: root.hot ? Theme.red : Theme.fg3
            }
        }
        Caption {
            anchors.horizontalCenter: hero.horizontalCenter
            anchors.verticalCenter: hero.verticalCenter
            anchors.verticalCenterOffset: Math.round(48 * root.u)
            text: root.live ? ("RAM " + root.pct(root.mem) + "%") : "Offline"
            color: root.live ? Theme.fg2 : Theme.fg3
        }
    }

    // ── Wide: CPU + RAM (captions inside the rings) ───────────────────────
    Row {
        id: wideRow
        visible: root.wide
        anchors.centerIn: parent
        spacing: Math.round(28 * root.u)
        readonly property real d: Math.min((root.width - 2 * root.padding - spacing) / 2,
                                           root.height - 2 * root.padding)

        Repeater {
            model: [
                { k: "CPU", v: root.cpu, extra: root.hasTemp ? Math.round(root.tempC) + "°C" : "" },
                { k: "RAM", v: root.mem, extra: root.ok(root.memUsedGb) ? Number(root.memUsedGb).toFixed(1) + " GB" : "" }
            ]
            Gauge {
                id: wg
                width: wideRow.d; height: width
                value: modelData.v
                numberSize: Math.max(40, Math.round(60 * root.u))
                fitColumns: 17
                numberOffset: -Math.round(8 * root.u)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Math.round(34 * root.u)
                    spacing: Math.round(6 * root.u)
                    Caption { text: modelData.k; color: Theme.fg }
                    Caption {
                        visible: text !== ""
                        text: modelData.extra
                        color: modelData.k === "CPU" && root.hot ? Theme.red : Theme.fg2
                    }
                }
            }
        }
    }
}
