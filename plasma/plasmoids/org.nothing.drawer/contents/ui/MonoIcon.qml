import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// App icon rendered monochrome. On the GPU (plasmashell) this is a MultiEffect
// with saturation -1. The software renderer (offscreen previews) can't run
// shaders, so there we grab the icon and desaturate it on a Canvas instead.
Item {
    id: root
    property var source
    property int size: 32
    property bool dark: false
    readonly property bool gpu: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property real brightness: dark ? -0.2 : 0.05

    width: size; height: size

    Kirigami.Icon {
        id: icon
        width: root.size; height: root.size
        x: root.gpu ? 0 : -100000          // software: keep it grabbable but out of sight
        source: root.source
        visible: !root.gpu
    }
    MultiEffect {
        visible: root.gpu
        anchors.fill: parent
        source: icon
        saturation: -1
        contrast: 0.15
        brightness: root.brightness
    }

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
                renderStrategy: Canvas.Immediate
                anchors.fill: parent
                onPaint: {
                    if (grabbed.status !== Image.Ready) return;
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.drawImage(grabbed, 0, 0, width, height);
                    // putImageData is unreliable on the software canvas: repaint pixel by pixel
                    const w = Math.round(width), h = Math.round(height);
                    const src = ctx.getImageData(0, 0, w, h).data;
                    ctx.clearRect(0, 0, width, height);
                    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
                        const i = (y * w + x) * 4;
                        if (src[i + 3] === 0) continue;
                        let g = 0.299 * src[i] + 0.587 * src[i + 1] + 0.114 * src[i + 2];
                        g = Math.max(0, Math.min(255, (g - 128) * 1.15 + 128 + root.brightness * 255)) / 255;
                        ctx.fillStyle = Qt.rgba(g, g, g, src[i + 3] / 255);
                        ctx.fillRect(x, y, 1, 1);
                    }
                }
            }
            Timer {
                interval: 50; running: true
                onTriggered: icon.grabToImage(r => { grabbed.source = r.url; })
            }
        }
    }
}
