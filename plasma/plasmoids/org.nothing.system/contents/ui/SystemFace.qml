import QtQuick
import "nothing"

// Square system card: CPU and RAM as dot-ring gauges. Pure view; null = "--".
Card {
    id: root
    property var cpu: null        // 0..1
    property var mem: null        // 0..1
    property var memUsedGb: null
    property var memTotalGb: null
    property var tempC: null      // optional

    readonly property real u: Math.max(0.5, Math.min(width, height) / 200)
    readonly property int pad: Math.round(20 * u)
    readonly property bool live: cpu !== null && mem !== null
    function pct(v) { return (v === null || v === undefined || isNaN(v)) ? "--" : Math.round(v * 100); }
    function gb(v) { return (v === null || v === undefined || isNaN(v)) ? "--" : Number(v).toFixed(1); }

    implicitWidth: 200
    implicitHeight: 200

    // Header: title + live dot, temperature on the right when available.
    Row {
        id: header
        x: root.pad; y: root.pad
        spacing: Math.round(6 * root.u)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(6 * root.u); height: width; radius: width / 2
            color: root.live ? Theme.red : Theme.fg3
        }
        Label { size: Math.max(10, Math.round(11 * root.u)); color: Theme.fg; text: "System" }
    }
    Label {
        anchors.right: parent.right; anchors.rightMargin: root.pad
        anchors.verticalCenter: header.verticalCenter
        size: Math.max(10, Math.round(11 * root.u))
        visible: root.tempC !== null && root.tempC !== undefined
        text: root.tempC !== null && root.tempC !== undefined ? Math.round(root.tempC) + "°C" : ""
    }

    Row {
        id: gauges
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(2 * root.u)
        spacing: Math.round(10 * root.u)
        readonly property real d: (root.width - 2 * root.pad - spacing) / 2

        Repeater {
            model: [{ k: "CPU", v: root.cpu }, { k: "RAM", v: root.mem }]
            Column {
                spacing: Math.round(6 * root.u)
                Item {
                    width: gauges.d; height: gauges.d
                    DotRing {
                        anchors.fill: parent
                        value: modelData.v === null || modelData.v === undefined ? 0 : modelData.v
                        dots: 24
                        dotSize: Math.max(3, Math.round(5 * root.u))
                    }
                    Row {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Math.round(1 * root.u)
                        DotText {
                            size: Math.round(30 * root.u); weight: 800
                            text: root.pct(modelData.v)
                            color: modelData.v === null || modelData.v === undefined ? Theme.fg3 : Theme.fg
                        }
                    }
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: Math.max(10, Math.round(10 * root.u))
                    text: modelData.k
                }
            }
        }
    }

    Label {
        x: root.pad
        anchors.bottom: parent.bottom; anchors.bottomMargin: root.pad
        size: Math.max(10, Math.round(10 * root.u))
        color: Theme.fg3
        text: "Mem"
    }
    Label {
        anchors.right: parent.right; anchors.rightMargin: root.pad
        anchors.bottom: parent.bottom; anchors.bottomMargin: root.pad
        size: Math.max(10, Math.round(10 * root.u))
        text: root.gb(root.memUsedGb) + " / " + root.gb(root.memTotalGb) + " GB"
    }
}
