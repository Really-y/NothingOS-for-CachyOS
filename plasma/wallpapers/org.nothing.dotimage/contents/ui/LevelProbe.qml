import QtQuick

// One-shot luminance histogram of a picture -> auto levels for the shader.
// Draws the image at 64x64 into a tiny software canvas once per source, reads the pixels
// back and returns vector3d(black point, white point, gamma):
//   black / white = 2nd (max 0.15) / 99th luminance percentile (dark art is stretched),
//   gamma pulls the stretched median towards ~0.30 (clamped 0.75..1.35); dark backgrounds
//   stay dark (missing dots) instead of turning into a sheet of small dots.
// `done` flips true when levels are known (or the probe failed -> neutral levels).
Canvas {
    id: probe
    width: 64; height: 64
    renderStrategy: Canvas.Immediate
    renderTarget: Canvas.Image

    property url source
    property vector3d levels: Qt.vector3d(0, 1, 1)
    property bool done: false
    property url _loaded

    onSourceChanged: {
        done = false
        if (_loaded.toString() !== "") unloadImage(_loaded)
        _loaded = source
        if (source.toString() === "") { levels = Qt.vector3d(0, 1, 1); done = true; return }
        if (isImageLoaded(source)) requestPaint()
        else loadImage(source)
    }
    onImageLoaded: requestPaint()

    onPaint: {
        if (done || !isImageLoaded(source)) return
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.drawImage(source, 0, 0, width, height)
        const px = ctx.getImageData(0, 0, width, height).data
        const hist = new Array(256).fill(0)
        let n = 0
        for (let i = 0; i < px.length; i += 4) {
            if (px[i + 3] < 128) continue
            const l = Math.round(0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2])
            hist[l]++; n++
        }
        if (n < 16) { levels = Qt.vector3d(0, 1, 1); done = true; return }
        const pct = f => { let acc = 0; for (let v = 0; v < 256; v++) { acc += hist[v]; if (acc >= f * n) return v / 255 } return 1 }
        // black point capped at 0.15: a flat mid-grey backdrop stays faint dots, not nothing
        let lo = Math.min(0.15, pct(0.02)), hi = Math.max(lo + 0.15, pct(0.99))
        if (hi - lo < 0.15) { const m = (hi + lo) / 2; lo = Math.max(0, m - 0.25); hi = Math.min(1, m + 0.25) }
        const med = Math.min(0.95, Math.max(0.03, (pct(0.5) - lo) / (hi - lo)))
        const g = Math.min(1.35, Math.max(0.75, Math.log(0.30) / Math.log(med)))
        levels = Qt.vector3d(lo, hi, g)
        done = true
        unloadImage(source); _loaded = ""
    }
}
