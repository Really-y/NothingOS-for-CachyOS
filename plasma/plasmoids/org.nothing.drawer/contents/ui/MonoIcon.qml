import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// App icon as a monochrome glyph.
//  1. If the icon theme ships "<name>-symbolic" (looked up in `symbolicNames`),
//     draw that as a flat white (black when `dark`) mask — a real line glyph.
//  2. Otherwise `fallback` decides: "mask" = flat silhouette of the normal icon,
//     "grey" = desaturated high-contrast icon (MultiEffect saturation -1).
// Kirigami's isMask/MultiEffect need the GPU; on the software renderer used by the
// offscreen previews the icon is grabbed and recoloured on a Canvas instead.
Item {
    id: root
    property var source
    property int size: 26
    property bool dark: false
    property var symbolicNames: ({})
    property string fallback: "grey"
    readonly property bool symbolic: typeof source === "string" && source !== ""
                                     && symbolicNames[source + "-symbolic"] === true
    readonly property bool masked: symbolic || fallback === "mask"
    readonly property var iconSource: symbolic ? source + "-symbolic" : source
    readonly property color ink: dark ? "#000000" : "#ffffff"
    readonly property bool gpu: GraphicsInfo.api !== GraphicsInfo.Software

    width: size; height: size

    // GPU path ───────────────────────────────────────────────────────────
    Kirigami.Icon {
        id: icon
        width: root.size; height: root.size
        x: root.gpu ? 0 : -100000          // software: keep it grabbable but out of sight
        source: root.iconSource
        isMask: root.masked && root.gpu
        roundToIconSize: false
        color: root.ink
        visible: root.gpu ? root.masked : true
    }
    MultiEffect {
        visible: root.gpu && !root.masked
        anchors.fill: parent
        source: icon
        saturation: -1
        contrast: 0.35
        brightness: root.dark ? -0.35 : 0.08
    }

    // software path (previews) ─────────────────────────────────────────
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
                    const inkV = root.dark ? 0 : 1;
                    const bright = root.dark ? -0.35 : 0.08;
                    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
                        const i = (y * w + x) * 4;
                        if (src[i + 3] === 0) continue;
                        let g = inkV;
                        if (!root.masked) {
                            g = 0.299 * src[i] + 0.587 * src[i + 1] + 0.114 * src[i + 2];
                            g = Math.max(0, Math.min(255, (g - 128) * 1.35 + 128 + bright * 255)) / 255;
                        }
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
