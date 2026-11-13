import QtQuick

// Nothing "Glyph field": the visual part of org.nothing.dots, no Plasma deps
// (rendered offscreen by previews/LiveWallpaperPreview.qml).
//
// Everything is a pure function of `time` (seconds). The timeline repeats every
// `loopLength` (= 3 sweep cycles) and every periodic motion is an integer number of
// periods per loop, so the driver can wrap `time` without a visible jump.
//   cycle = 11 s / speed
//   0.00–0.40 cycle  diagonal Glyph band sweeps top-left -> bottom-right (through her too)
//   every 3rd cycle  one ring ripples out of the red dot ("notification")
//   always           red dot breathes; her hair sways (~6 s), she breathes (~4.4 s)
//   ~every 5 s       she blinks (one double blink per loop)
Item {
    id: field

    property real time: 0
    property int pitch: 24
    property real dotRatio: 0.65          // house rule: dot = 0.65 x pitch
    property real speed: 1.0
    property bool showRedDot: true
    property bool ripples: true
    property bool animated: true          // false = calm static frame
    property point mouse: Qt.point(-1000, -1000)
    property real mouseOn: 0

    // the character
    property bool showFigure: true
    property string figureStyle: "glam"   // "glam" (portrait) | "cute" — wallpapers/glyphgirl/*.svg
    property real figureX: 0.75           // horizontal centre, fraction of width
    property real figureScale: 1.15       // height, fraction of screen height
    // fine grid per style; 8 and 6 divide the 24 px field and share its origin (no moire)
    readonly property int figurePitch: _style === "glam" ? 8 : 5
    readonly property rect figRect: {
        const h = Math.round(figureScale * height), w = Math.round(h * 0.75)
        // bottom-aligned; when taller than the screen, keep the ahoge ~2 % below the top edge
        // (the hoodie runs off the bottom instead), which also lifts her face
        return Qt.rect(Math.round(figureX * width - w / 2), Math.round(Math.max(height - h, -0.035 * h)), w, h)
    }

    readonly property real cycle: 11.0 / Math.max(0.25, speed)
    readonly property real loopLength: cycle * 3
    readonly property real _local: time % cycle
    readonly property int _cycleNo: Math.floor(time / cycle) % 3

    readonly property real sweep: {
        if (!animated) return 0.78                       // frozen tail in the lower right
        const d = 0.40 * cycle
        if (_local >= d) return -1
        const x = _local / d
        return x - Math.sin(2 * Math.PI * x) / (2 * Math.PI) * 0.5   // gentle ease in/out
    }
    readonly property point ripple: {
        if (!animated || !ripples || !showRedDot || _cycleNo !== 2) return Qt.point(0, 0)
        const start = 0.45 * cycle, len = 0.36 * cycle
        const q = (_local - start) / len
        if (q < 0 || q >= 1) return Qt.point(0, 0)
        const ease = 1 - Math.pow(1 - q, 3)
        return Qt.point(ease * Math.max(width, height) * 0.55,
                        Math.pow(1 - q, 1.6) * Math.min(1, q * 10))
    }
    readonly property real breath: animated
        ? 0.45 + 0.55 * (0.5 - 0.5 * Math.cos(2 * Math.PI * time / (cycle / 2)))
        : 1.0

    // ---- her motion (periods snapped to the loop) ----
    readonly property real swayPhase: animated
        ? 2 * Math.PI * Math.max(1, Math.round(loopLength / 6.0)) * time / loopLength : 0
    readonly property real breathe: animated
        ? 0.006 * (0.5 - 0.5 * Math.cos(2 * Math.PI * Math.max(1, Math.round(loopLength / 4.4)) * time / loopLength))
        : 0
    readonly property var blinkTimes: {
        const n = Math.max(2, Math.round(loopLength / 5.2)), jit = [0.10, -0.18, 0.05, 0.22, -0.08]
        const t = []
        for (let i = 0; i < n; i++) {
            const at = (i + 0.5 + jit[i % 5]) * loopLength / n
            t.push(at)
            if (i === 1) t.push(at + 0.38)              // one double blink per loop
        }
        return t
    }
    readonly property real blink: {
        if (!animated || !showFigure) return 0
        let b = 0
        for (const at of blinkTimes) {
            const d = time - at
            if (d >= 0 && d < 0.07) b = Math.max(b, d / 0.07)                 // close fast
            else if (d >= 0.07 && d < 0.21) b = Math.max(b, 1 - (d - 0.07) / 0.14)  // open slower
        }
        return b * b * (3 - 2 * b)
    }
    readonly property bool _blinkSoon: animated && showFigure
        && blinkTimes.some(at => time > at - 0.35 && time < at + 0.3)

    // true while something quick is moving -> driver uses the high frame rate
    readonly property bool active: animated && (sweep >= 0 || ripple.y > 0 || _blinkSoon)
    // something always moves (sway / breathing) -> driver's resting frame rate
    readonly property bool idleMotion: animated && showFigure

    // ---- the one red dot: her hair-clip bead, else bottom-right ----
    // red bead per style, in canvas uv after the head tilt (see the svg sources)
    readonly property point clipUV: _style === "cute" ? Qt.point(228.0 / 600, 214.4 / 800)     // hair-clip end
                                  : Qt.point(399.67 / 600, 403.02 / 800)                       // earring (glam)
    readonly property point redPos: showFigure
        ? Qt.point(figRect.x + (0.5 + (clipUV.x - 0.5) * (1 + breathe)) * figRect.width,
                   figRect.y + (1 + (clipUV.y - 1) * (1 + breathe)) * figRect.height)
        : Qt.point((Math.floor((width - 216) / pitch) + 0.5) * pitch,
                   (Math.floor((height - 168) / pitch) + 0.5) * pitch)
    readonly property real redR: showFigure ? Math.max(4.5, figRect.height / 800 * 5.5) : 0.5 * dotRatio * pitch
    readonly property string _style: ["cute", "glam"].includes(figureStyle) ? figureStyle : "glam"

    readonly property bool useShader: GraphicsInfo.api !== GraphicsInfo.Software
                                      && shader.status !== ShaderEffect.Error

    Image { id: figTexImg; source: "figure-" + field._style + ".png"; visible: false; smooth: true; mipmap: false }
    Image { id: figAuxImg; source: "figure-" + field._style + "-aux.png"; visible: false; smooth: true }

    ShaderEffect {
        id: shader
        anchors.fill: parent
        visible: field.useShader
        blending: false
        fragmentShader: Qt.resolvedUrl("shaders/glyphfield.frag.qsb")
        // a broken/missing .qsb flips useShader -> the static Canvas takes over, no error UI
        onStatusChanged: if (status === ShaderEffect.Error)
            console.warn("org.nothing.dots: shader failed, using static Canvas:", log)

        property size res: Qt.size(width, height)
        property real pitch: field.pitch
        property real dotRatio: field.dotRatio
        property real base: 0.078                 // ~#141414 .. #1c1c1c across the field
        property real sweep: field.sweep
        property real sweepGain: 0.215            // crest ~#3a3a3a .. #4a4a4a
        property point ripple: field.ripple
        property real breath: field.breath
        property real redOn: field.showRedDot ? 1 : 0
        property point redPos: field.redPos
        property real redR: field.redR
        property point mouse: field.mouse
        property real mouseOn: field.mouseOn
        property real figOn: field.showFigure && figTexImg.status === Image.Ready
                             && figAuxImg.status === Image.Ready ? 1 : 0
        property rect figRect: field.figRect
        property real figPitch: field.figurePitch
        property real swayPhase: field.swayPhase
        property real swayAmp: 0.013
        property real blink: field.blink
        property real breathe: field.breathe
        property var figTex: figTexImg
        property var figAux: figAuxImg
    }

    // Software scene graph / shader failure: static Canvas, painted only on resize/config.
    Loader {
        anchors.fill: parent
        active: !field.useShader
        sourceComponent: Canvas {
            id: cv
            renderStrategy: Canvas.Cooperative
            readonly property url figUrl: Qt.resolvedUrl("figure-" + field._style + ".png")
            Component.onCompleted: loadImage(figUrl)
            onImageLoaded: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: field
                function onPitchChanged() { cv.requestPaint() }
                function onShowRedDotChanged() { cv.requestPaint() }
                function onShowFigureChanged() { cv.requestPaint() }
                function onFigRectChanged() { cv.requestPaint() }
            }
            onPaint: {
                const ctx = getContext("2d"), p = field.pitch, r = 0.5 * field.dotRatio * p
                const fr = field.figRect, fp = field.figurePitch, fig = field.showFigure && isImageLoaded(figUrl)
                // sample the figure once per fine cell: draw it at one pixel per cell, read it back
                let px = null, cols = 0, rows = 0
                if (fig) {
                    cols = Math.ceil(fr.width / fp); rows = Math.ceil(fr.height / fp)
                    ctx.clearRect(0, 0, cols, rows)
                    ctx.drawImage(figUrl, 0, 0, cols, rows)
                    px = ctx.getImageData(0, 0, cols, rows).data
                }
                const at = (x, y) => {   // [lum, silhouette] at screen px, or null
                    const cx = Math.floor((x - fr.x) / fp), cy = Math.floor((y - fr.y) / fp)
                    if (!px || cx < 0 || cy < 0 || cx >= cols || cy >= rows) return null
                    const i = (cy * cols + cx) * 4
                    return [px[i] / 255, px[i + 2] / 255]
                }
                ctx.fillStyle = "#000000"; ctx.fillRect(0, 0, width, height)
                for (let y = p / 2; y < height; y += p) {
                    for (let x = p / 2; x < width; x += p) {
                        const s = at(x, y)
                        if (s && s[1] > 0.05) continue
                        const g = Math.min(1, Math.max(0, x / width * 0.55 + y / height * 0.45))
                        const v = 0.078 * (0.85 + 0.35 * g * g)
                        ctx.fillStyle = Qt.rgba(v, v, v, 1)
                        ctx.beginPath(); ctx.arc(x, y, r, 0, 2 * Math.PI); ctx.fill()
                    }
                }
                if (fig) {
                    const fr2 = 0.5 * field.dotRatio * fp
                    const x0 = Math.floor(fr.x / fp) * fp, y0 = Math.floor(fr.y / fp) * fp
                    for (let y = y0 + fp / 2; y < fr.y + fr.height; y += fp) {
                        for (let x = x0 + fp / 2; x < fr.x + fr.width; x += fp) {
                            const s = at(x, y)
                            if (!s || s[1] < 0.4) continue
                            const v = Math.max(0.055, s[0])
                            ctx.fillStyle = Qt.rgba(v, v, v, 1)
                            ctx.beginPath(); ctx.arc(x, y, fr2, 0, 2 * Math.PI); ctx.fill()
                        }
                    }
                }
                if (field.showRedDot) {
                    ctx.fillStyle = "#d71921"
                    ctx.beginPath(); ctx.arc(field.redPos.x, field.redPos.y, field.redR, 0, 2 * Math.PI); ctx.fill()
                }
            }
        }
    }
}
