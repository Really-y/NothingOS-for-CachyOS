import QtQuick

// Album art rendered Nothing-style on a Canvas (works on every scene-graph
// backend, no shaders):
//   halftone: greyscale dot dither (`pitch` px), dots fade out toward the
//             top/bottom edges so overlaid text stays legible
//   mono:     desaturated photo
// Corners are clipped to `radius` (mono: painted in `matte`); `ready` is false until the image loads.
Item {
    id: root
    property url source
    property string mode: "halftone"     // "halftone" | "mono"
    property real radius: 20
    property real pitch: 6
    property real fadeTop: 0             // fraction of height kept clear at the top (halftone)
    property real fadeBottom: 0.4        // ... and at the bottom (text band)
    property real fadeRamp: 0.14         // soft ramp beyond the clear bands
    property int levels: 4               // posterisation levels for dot sizes
    property real maxDot: 0.92           // largest dot diameter as a fraction of the cell (< 0.75 keeps clear gaps)
    property color matte: Theme.widget   // colour behind the corners (mono mode)
    readonly property bool ready: probe.status === Image.Ready && String(source) !== ""

    Image {
        id: probe
        visible: false
        source: root.source
        asynchronous: true
        cache: true
        onStatusChanged: canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections { target: root; function onModeChanged() { canvas.requestPaint(); } function onPitchChanged() { canvas.requestPaint(); } }

        function roundedPath(c, w, h, r) {
            c.beginPath();
            c.moveTo(r, 0); c.lineTo(w - r, 0); c.arcTo(w, 0, w, r, r);
            c.lineTo(w, h - r); c.arcTo(w, h, w - r, h, r);
            c.lineTo(r, h); c.arcTo(0, h, 0, h - r, r);
            c.lineTo(0, r); c.arcTo(0, 0, r, 0, r);
            c.closePath();
        }

        onPaint: {
            const c = getContext("2d");
            const w = Math.round(width), h = Math.round(height);
            const r = Math.min(root.radius, w / 2, h / 2);
            c.reset();
            if (!root.ready || w < 2 || h < 2) return;

            // 1. draw the art cropped to fill (PreserveAspectCrop)
            const iw = probe.implicitWidth, ih = probe.implicitHeight;
            const s = Math.max(w / iw, h / ih);
            const sw = w / s, sh = h / s;
            c.drawImage(probe, (iw - sw) / 2, (ih - sh) / 2, sw, sh, 0, 0, w, h);
            const img = c.getImageData(0, 0, w, h);
            const d = img.data;

            if (root.mode === "mono") {
                for (let i = 0; i < d.length; i += 4) {
                    const l = 0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2];
                    d[i] = d[i + 1] = d[i + 2] = l;
                }
                c.putImageData(img, 0, 0);
                // putImageData ignores clipping: paint the corners in the matte colour
                c.fillStyle = root.matte;
                c.beginPath();
                c.rect(0, 0, w, h);
                c.moveTo(r, 0); c.arcTo(0, 0, 0, r, r); c.lineTo(0, h - r); c.arcTo(0, h, r, h, r);
                c.lineTo(w - r, h); c.arcTo(w, h, w, h - r, r); c.lineTo(w, r); c.arcTo(w, 0, w - r, 0, r);
                c.closePath();
                c.fill("evenodd");
            } else {
                // 2. halftone: average luminance per cell → dot radius
                const p = root.pitch;
                c.clearRect(0, 0, w, h);
                c.fillStyle = Theme.fg;
                // dots whose centre falls outside the rounded rect are skipped
                // (no clip(): it is unreliable on the software backend)
                const inside = (x, y, m) => {
                    const ax = Math.max(r - x, 0, x - (w - r)), ay = Math.max(r - y, 0, y - (h - r));
                    return ax * ax + ay * ay <= (r - m) * (r - m);
                };
                const ft = h * root.fadeTop, fb = h * root.fadeBottom;
                for (let cy = 0; cy + p <= h + 0.01; cy += p) {
                    for (let cx = 0; cx + p <= w + 0.01; cx += p) {
                        let sum = 0, n = 0;
                        for (let y = Math.floor(cy); y < Math.min(h, cy + p); y += 2)
                            for (let x = Math.floor(cx); x < Math.min(w, cx + p); x += 2) {
                                const k = (y * w + x) * 4;
                                sum += 0.2126 * d[k] + 0.7152 * d[k + 1] + 0.0722 * d[k + 2];
                                n++;
                            }
                        let l = n ? sum / n / 255 : 0;
                        const my = cy + p / 2;
                        // posterise: clamp the mid-greys, few dot sizes → reads as a dot portrait
                        l = Math.min(1, Math.max(0, (l - 0.18) / 0.6));
                        l = Math.round(l * (root.levels - 1)) / (root.levels - 1);
                        // clear under the text bands, short ramp beyond
                        const ramp = Math.max(1, h * root.fadeRamp);
                        const top = ft > 0 ? Math.min(1, Math.max(0, (my - ft) / ramp)) : 1;
                        const bot = fb > 0 ? Math.min(1, Math.max(0, (h - fb - my) / ramp)) : 1;
                        l *= top * bot;
                        const rad = p * root.maxDot / 2 * l;
                        if (rad < 0.6 || !inside(cx + p / 2, my, p * 0.5)) continue;
                        c.beginPath();
                        c.arc(cx + p / 2, my, rad, 0, Math.PI * 2);
                        c.fill();
                    }
                }
            }
        }
    }
}
