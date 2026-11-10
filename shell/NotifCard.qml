import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// One notification. Swipe right / click × to dismiss.
Rectangle {
    id: card
    required property var notif
    property bool popup: false
    signal dismissed()
    implicitHeight: col.implicitHeight + 28
    radius: Theme.r - 4
    color: popup ? Theme.card : Theme.card2
    border.width: popup ? 1 : 0
    border.color: Theme.line

    function ago(ms) {
        if (!ms) return "";
        const m = Math.floor((Date.now() - ms) / 60000);
        return m < 1 ? "now" : m < 60 ? m + "m" : Math.floor(m / 60) + "h";
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 6
        RowLayout {
            spacing: 8
            IconImage {
                implicitSize: 16
                source: card.notif.appIcon ? Quickshell.iconPath(card.notif.appIcon, "dialog-information") : Quickshell.iconPath("dialog-information")
            }
            Label { text: card.notif.appName || "System"; Layout.fillWidth: true; elide: Text.ElideRight }
            Rectangle { visible: card.notif.urgency === 2; width: 6; height: 6; radius: 3; color: Theme.red }
            Label { text: card.ago(Notifs.times[card.notif.id]); color: Theme.fg3 }
            Icon {
                name: "close"; size: 16; color: xm.containsMouse ? Theme.fg : Theme.fg3
                MouseArea { id: xm; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.close() }
            }
        }
        RowLayout {
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: card.notif.summary; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    color: Theme.fg; font.family: Theme.sans; font.pixelSize: 15; font.weight: Font.Medium
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notif.body; wrapMode: Text.Wrap; maximumLineCount: card.popup ? 3 : 5; elide: Text.ElideRight
                    color: Theme.fg2; font.family: Theme.sans; font.pixelSize: 13
                    textFormat: Text.PlainText
                }
            }
            ClippingRectangle {
                visible: (card.notif.image || "") !== ""
                Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 12
                Image { anchors.fill: parent; source: card.notif.image || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
            }
        }
        Flow {
            Layout.fillWidth: true
            visible: card.notif.actions.length > 0
            spacing: 6
            Repeater {
                model: card.notif.actions
                Pressable {
                    id: act
                    required property var modelData
                    width: at.implicitWidth + 24; height: 30
                    onClicked: modelData.invoke()
                    Rectangle { anchors.fill: parent; radius: 15; color: act.containsMouse ? Theme.fg : Theme.card3 }
                    Text { id: at; anchors.centerIn: parent; text: act.modelData.text; color: act.containsMouse ? Theme.bg : Theme.fg; font.family: Theme.sans; font.pixelSize: 12 }
                }
            }
        }
    }

    function close() { leave.start(); }
    SequentialAnimation {
        id: leave
        ParallelAnimation {
            NumberAnimation { target: card; property: "x"; to: card.width + 40; duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
            NumberAnimation { target: card; property: "opacity"; to: 0; duration: Theme.normal }
        }
        ScriptAction { script: { card.dismissed(); card.notif.dismiss(); } }
    }

    // drag to dismiss
    DragHandler {
        id: drag
        xAxis.enabled: true; yAxis.enabled: false
        xAxis.minimum: 0
        onActiveChanged: if (!active) { if (card.x > card.width * 0.3) card.close(); else back.start(); }
    }
    NumberAnimation { id: back; target: card; property: "x"; to: 0; duration: Theme.normal; easing.type: Easing.OutBack }
}
