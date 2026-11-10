import QtQuick
import org.kde.kirigami as Kirigami
import "iconmap.js" as IconMap

// App icon as one flat monochrome glyph (white, or black when `dark`).
// A themed "-symbolic" glyph is preferred: exact name, reverse-DNS tail, then a
// category glyph picked from the app name (iconmap.js). If none fits, the normal
// icon is masked into a flat silhouette — same colour, same mode for every app.
// Kirigami's isMask recolours on the GPU; on the software renderer used by the
// offscreen previews the icon is grabbed and recoloured on a Canvas instead.
Item {
    id: root
    property var source
    property string hint: ""                 // app name / generic name for category matching
    property int size: 26
    property bool dark: false
    property var symbolicNames: ({})
    readonly property string glyph: IconMap.resolve(source, hint, symbolicNames)
    readonly property var iconSource: glyph !== "" ? glyph : source
    readonly property color ink: dark ? "#000000" : "#ffffff"
    readonly property bool gpu: GraphicsInfo.api !== GraphicsInfo.Software

    width: size; height: size

    Kirigami.Icon {
        id: icon
        width: root.size; height: root.size
        x: root.gpu ? 0 : -100000          // software: keep it grabbable but out of sight
        source: root.iconSource
        isMask: root.gpu
        roundToIconSize: false
        color: root.ink
    }

    // software path (previews only) ────────────────────────────────────
    Loader {
        active: !root.gpu
        anchors.fill: parent
        sourceComponent: Item {
            Image {
                id: grabbed
                anchors.fill: parent
                visible: false
                onStatusChanged: if (status === Image.Ready) canvas.requestPaint()
            }
            Canvas {
                id: canvas
                anchors.fill: parent
                renderStrategy: Canvas.Immediate
                onPaint: {
                    if (grabbed.status !== Image.Ready) return;
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.drawImage(grabbed, 0, 0, width, height);
                    // putImageData is unreliable on the software canvas: repaint pixel by pixel
                    const w = Math.round(width), h = Math.round(height);
                    const src = ctx.getImageData(0, 0, w, h).data;
                    ctx.clearRect(0, 0, width, height);
                    const v = root.dark ? 0 : 1;
                    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
                        const a = src[(y * w + x) * 4 + 3];
                        if (a === 0) continue;
                        ctx.fillStyle = Qt.rgba(v, v, v, a / 255);
                        ctx.fillRect(x, y, 1, 1);
                    }
                }
            }
            Connections {
                target: root
                function onIconSourceChanged() { grab.restart(); }
                function onDarkChanged() { canvas.requestPaint(); }
            }
            Timer {
                id: grab
                interval: 50; running: true
                onTriggered: icon.grabToImage(r => { grabbed.source = r.url; })
            }
        }
    }
}
