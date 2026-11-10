import QtQuick
import "nothing"

// Nothing system card. Pure view; null values render "--".
//  square: one hero CPU dot ring (like Nothing's battery widget), RAM as caption
//  wide:   CPU and RAM rings side by side
// Red only as the warning signal: ring dots past the 80 % mark.
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
        property real maxPitch: 8          // largest house pitch to try
        property real fixedPitch: 0        // > 0: always this pitch (shared by neighbours)
        property real numberOffset: 0
        property bool mayWarn: true        // one red per widget: only the worst metric
        DotRing {
            anchors.fill: parent
            value: root.ok(g.value) ? g.value : 0
            warn: 0.8                      // only dots past 80 % …
            warnTail: 3                    // … and only at the leading end of the fill
            warnEnabled: g.mayWarn
            dots: 40
            dotSize: Math.max(3, 4 * root.u)
        }
        DotString {
            id: num
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: pctSign.visible ? -(pctSign.width + 3) / 2 : 0
            anchors.verticalCenterOffset: g.numberOffset
            text: root.pct(g.value)
            pitch: g.fixedPitch > 0 ? g.fixedPitch : fitPitch(g.width * 0.66, g.maxPitch)
            color: root.ok(g.value) ? Theme.fg : Theme.fg3
            width: implicitWidth; height: implicitHeight
        }
        // "%": 11px mono, baseline on the bottom dot row
        Text {
            id: pctSign
            visible: root.ok(g.value)
            anchors.left: num.right; anchors.leftMargin: 3
            anchors.baseline: num.bottom
            text: "%"
            color: Theme.fg2
            font.family: Theme.mono
            font.pixelSize: 11
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
            maxPitch: root.u >= 1.4 ? 12 : 8
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
                color: Theme.fg3
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
                // shared pitch 8; both drop to 5 only while either reads "100"
                fixedPitch: root.pct(root.cpu).length > 2 || root.pct(root.mem).length > 2 ? 5 : 8
                mayWarn: modelData.k === (root.ok(root.cpu) && root.ok(root.mem) && root.mem > root.cpu ? "RAM" : "CPU")
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
                        color: Theme.fg2
                    }
                }
            }
        }
    }
}
