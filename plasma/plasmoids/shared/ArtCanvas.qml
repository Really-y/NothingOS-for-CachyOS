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
    // preset "small" — the one recipe for every art tile ≤ 90px (media 2×2, control
    // center, lockscreen): 5px pitch, 3px round pixel-stamp dots (≈3.5px optical), binary (dot or
    // no dot), the cover square-cropped into a centred dot grid that fills ~80 % of
    // the tile. Overrides pitch / maxDot / levels / fades.
    property string preset: ""
    readonly property int smallPitch: 5       // 3px dot stamp + 2px pure-black gap
    property real radius: 20
    property real pitch: 6
    property real fadeTop: 0             // fraction of height kept clear at the top (halftone)
    property real fadeBottom: 0.4        // ... and at the bottom (text band)
    property real fadeRamp: 0.14         // soft ramp beyond the clear bands
    property int levels: 4               // posterisation levels for dot sizes
    property real minDot: 2.5            // px; smaller dots are dropped
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
        // nearest sampling: if the tile lands on a fractional scene position the
        // canvas texture must not be bilinear-filtered (that adds grey halos/bridges)
        smooth: false
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

        function paintSmall(c, w, h, iw, ih) {
            const p = root.smallPitch, n = Math.max(1, Math.round(0.8 * Math.min(w, h) / p));
            const G = n * p;
            const gx = Math.floor((w - G) / 2), gy = Math.floor((h - G) / 2);
            // square cover-crop of the art into the grid area
            const sq = Math.min(iw, ih);
            c.drawImage(probe, (iw - sq) / 2, (ih - sq) / 2, sq, sq, gx, gy, G, G);
            const d = c.getImageData(gx, gy, G, G).data;
            c.clearRect(0, 0, w, h);
            c.fillStyle = Theme.fg;
            // Each dot is a pixel stamp — a 3×3 disc (corners at 85 %) on whole pixels —
            // instead of an antialiased arc, whose faint fringe bridged neighbours.
            const corner = Qt.rgba(1, 1, 1, 0.85);
            for (let j = 0; j < n; j++)
                for (let i = 0; i < n; i++) {
                    let sum = 0, k = 0;
                    for (let y = j * p; y < (j + 1) * p; y++)
                        for (let x = i * p; x < (i + 1) * p; x++) {
                            const q = (y * G + x) * 4;
                            sum += 0.2126 * d[q] + 0.7152 * d[q + 1] + 0.0722 * d[q + 2];
                            k++;
                        }
                    if (sum / k / 255 < 0.5) continue;          // binary: dot or nothing
                    const x0 = gx + i * p + Math.floor(p / 2) - 1, y0 = gy + j * p + Math.floor(p / 2) - 1;
                    c.fillStyle = Theme.fg;
                    c.fillRect(x0 + 1, y0, 1, 3);
                    c.fillRect(x0, y0 + 1, 3, 1);
                    c.fillStyle = corner;
                    c.fillRect(x0, y0, 1, 1); c.fillRect(x0 + 2, y0, 1, 1);
                    c.fillRect(x0, y0 + 2, 1, 1); c.fillRect(x0 + 2, y0 + 2, 1, 1);
                }
        }

        onPaint: {
            const c = getContext("2d");
            const w = Math.round(width), h = Math.round(height);
            const r = Math.min(root.radius, w / 2, h / 2);
            c.reset();
            if (!root.ready || w < 2 || h < 2) return;

            const iw = probe.implicitWidth, ih = probe.implicitHeight;
            if (root.preset === "small") { paintSmall(c, w, h, iw, ih); return; }

            // 1. draw the art cropped to fill (PreserveAspectCrop)
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
                // centre the dot grid on the tile (leftover split evenly on both sides)
                const gx = (w - Math.floor(w / p) * p) / 2, gy = (h - Math.floor(h / p) * p) / 2;
                for (let cy = gy; cy + p <= h + 0.01; cy += p) {
                    for (let cx = gx; cx + p <= w + 0.01; cx += p) {
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
                        // dots under minDot px read as specks: drop them
                        if (rad * 2 < root.minDot || !inside(cx + p / 2, my, p * 0.5)) continue;
                        // Centre each dot on a pixel centre: a small circle centred on a
                        // pixel corner rasterises as a 2×2 square with a grey cross halo.
                        const px = Math.floor(cx + p / 2) + 0.5, py = Math.floor(my) + 0.5;
                        c.beginPath();
                        c.arc(px, py, rad, 0, Math.PI * 2);
                        c.fill();
                    }
                }
            }
        }
    }
}
