pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window

// Nothing "Dot Image": the visual part of org.nothing.dotimage, no Plasma deps
// (rendered offscreen by previews/DotImagePreview.qml).
//
// Two picture slots (A, B) ping-pong: a new `source` loads into the hidden slot, and once
// the picture and its auto levels are ready, `fade` animates over so the dots morph from
// the old picture to the new one. Each slot is the picture framed on the screen and
// rendered by a ShaderEffectSource at 2 texels per (fine) dot cell, with mipmaps (the shader
// samples cell centres; the Glyph look's soft mask reads a high mip).
//
// Looks: 0 "Glyph field" (org.nothing.dots language: dim 24 px field + the picture as a fine
// dot matrix that feathers into it), 1 "Halftone" (one grid, quantised dot sizes).
//
// Timeline (pure function of `time`, s): cycle = 8 s, loop = 3 cycles = 24 s.
//   0.00–0.32 cycle  Glyph band sweeps top-left -> bottom-right
//   every 3rd cycle  Glyph look, mono + red: one ring ripples out of the red accent
//   always           sparse twinkle, 4 s / 2 s periods (integer number per loop)
Item {
    id: field

    property url source
    property int fillMode: 0              // 0 Fill (cover), 1 Fit (contain), 2 Center
    property real focusY: 0.3            // Fill only: 0 top … 0.5 centre … 1 bottom
    property int look: 0                  // 0 Glyph field, 1 Halftone
    property int pitch: 5                 // halftone grid
    property int finePitch: 0             // glyph look: picture dots 3/4/6/8 px (divide the 24 px
                                          // field); 0 = auto from the picture's resolution
    readonly property int fieldPitch: 24
    // auto: each fine cell should cover >= ~1.6 source pixels, else the dots only show the
    // source's grain (a 637 px wide picture on 1080p -> 6 px; anything >= ~1200 px -> 4 px)
    readonly property real _srcScale: (slotA.source.toString() === source.toString() ? slotA : slotB).pxScale
    readonly property int autoFine: [4, 6, 8].find(v => v >= 1.6 * _srcScale) || 8
    readonly property int dotPitch: look === 0 ? ([3, 4, 6, 8].includes(finePitch) ? finePitch : autoFine) : pitch
    property real maxRatio: 0.84
    property real minDot: 0.18
    property int levels: 6                // 0 = continuous
    property real contrast: 1.0
    property real brightness: 1.0
    property bool autoLevels: true
    property real blackPoint: 0.0
    property real whitePoint: 1.0
    property int colorMode: 0             // 0 mono, 1 colour, 2 mono + red accent
    property bool edges: true             // subtle sharpening + edge boost
    property bool backgroundGrid: true
    property bool animated: true
    property bool twinkle: true
    property int transitionMs: 1400
    property real time: 0

    readonly property real cycle: 8.0
    readonly property real loopLength: cycle * 3
    readonly property real sweep: {
        if (!animated) return -1
        const d = 0.32 * cycle, l = time % cycle
        if (l >= d) return -1
        const x = l / d
        return x - Math.sin(2 * Math.PI * x) / (2 * Math.PI) * 0.5
    }
    readonly property var _red: front === 0 ? slotA : slotB
    readonly property bool hasRipple: animated && look === 0 && colorMode === 2 && _red.redFrac > 0.0005
    readonly property point ripple: {
        if (!hasRipple || Math.floor(time / cycle) % 3 !== 2) return Qt.point(0, 0)
        const q = ((time % cycle) - 0.45 * cycle) / (0.36 * cycle)
        if (q < 0 || q >= 1) return Qt.point(0, 0)
        const ease = 1 - Math.pow(1 - q, 3)
        return Qt.point(ease * Math.max(width, height) * 0.55, Math.pow(1 - q, 1.6) * Math.min(1, q * 10))
    }
    // true while the band / ripple moves (driver uses the higher frame rate)
    readonly property bool active: sweep >= 0 || ripple.y > 0 || fadeAnim.running
    // seconds until the next sweep starts (driver sleeps this long when nothing else moves)
    readonly property real untilSweep: {
        const l = time % cycle
        return hasRipple && Math.floor(time / cycle) % 3 === 2 && l < 0.45 * cycle ? 0.45 * cycle - l : cycle - l
    }

    readonly property bool useShader: GraphicsInfo.api !== GraphicsInfo.Software
                                      && shader.status !== ShaderEffect.Error
    readonly property bool ready: slotA.ready || slotB.ready

    // ---- slots ---------------------------------------------------------------
    property int front: 0                 // slot currently shown (0 = A, 1 = B)
    property real fade: 0                 // 0 shows A, 1 shows B
    property bool _pending: false

    function _back() { return front === 0 ? slotB : slotA }
    function _load() {
        const s = field.source.toString()
        const fr = front === 0 ? slotA : slotB
        if (fr.source.toString() === s && !_pending) return
        if (fadeAnim.running) fadeAnim.complete()   // the back slot is still fading out
        _back().source = s
        _pending = true
        _tryFlip()
    }
    function _tryFlip() {
        const b = _back()
        if (!_pending || !b.ready) return
        _pending = false
        fadeAnim.stop()
        fadeAnim.to = front === 0 ? 1 : 0
        front = 1 - front
        if (transitionMs > 0) fadeAnim.start(); else fade = fadeAnim.to
    }
    onSourceChanged: _load()
    Component.onCompleted: _load()

    NumberAnimation { id: fadeAnim; target: field; property: "fade"; duration: field.transitionMs; easing.type: Easing.InOutQuad }

    component Slot: Item {
        id: slot
        property alias source: img.source
        readonly property bool ready: source.toString() === ""
            || ((img.status === Image.Ready || img.status === Image.Error) && probe.done)
        readonly property vector3d levels: field.autoLevels ? probe.levels
            : Qt.vector3d(field.blackPoint, Math.max(field.blackPoint + 0.02, field.whitePoint), 1)
        readonly property alias texture: tex
        readonly property real redFrac: probe.redFrac
        readonly property real pxScale: img.status === Image.Ready ? img.s : 1   // screen px per decoded px
        // red accent centroid on screen (picture uv -> frame px)
        readonly property point redPos: Qt.point(img.x + probe.redUV.x * img.width, img.y + probe.redUV.y * img.height)
        width: field.width; height: field.height
        onReadyChanged: if (ready) field._tryFlip()

        // the screen-sized frame the shader sees; the picture is placed in it by hand so
        // Fill can keep a chosen vertical focus (faces) instead of always cropping the centre
        Item {
            id: frame
            width: slot.width; height: slot.height
            clip: true
            Image {
                id: img
                asynchronous: true
                autoTransform: true
                cache: false
                smooth: true
                // trilinear only when the picture is shrunk into the texture; a small picture
                // being enlarged stays plain bilinear (mipmaps would only soften it)
                mipmap: s * slot.texScale < 1
                fillMode: Image.Stretch     // geometry below keeps the aspect ratio
                // decode at most ~1.5x the screen's long side (Center keeps native pixels)
                sourceSize: field.fillMode === 2 ? undefined
                    : Qt.size(slot.cap, slot.cap)
                readonly property real nw: Math.max(1, implicitWidth)
                readonly property real nh: Math.max(1, implicitHeight)
                readonly property real s: field.fillMode === 0 ? Math.max(slot.width / nw, slot.height / nh)
                                        : field.fillMode === 1 ? Math.min(slot.width / nw, slot.height / nh)
                                        : 1 / Screen.devicePixelRatio
                width: Math.round(nw * s); height: Math.round(nh * s)
                x: Math.round((slot.width - width) / 2)
                // Fill: focus 0 = keep the top, 0.5 = centre, 1 = keep the bottom
                y: Math.round((slot.height - height) * (field.fillMode === 0 && height > slot.height ? field.focusY : 0.5))
                onStatusChanged: if (status === Image.Error) console.warn("org.nothing.dotimage: cannot load", source)
            }
        }
        readonly property int cap: Math.max(16, Math.round(1.5 * Math.max(width, height) * Screen.devicePixelRatio))
        readonly property real texScale: tex.textureSize.width / Math.max(1, width)
        ShaderEffectSource {
            id: tex
            sourceItem: frame
            hideSource: true
            visible: false
            smooth: true
            mipmap: true                    // the Glyph look's soft mask reads a high mip
            textureSize: Qt.size(Math.max(2, Math.ceil(field.width / field.dotPitch) * 2),
                                 Math.max(2, Math.ceil(field.height / field.dotPitch) * 2))
        }
        LevelProbe { id: probe; source: img.source; opacity: 0 }
    }

    Slot { id: slotA }
    Slot { id: slotB }

    ShaderEffect {
        id: shader
        anchors.fill: parent
        visible: field.useShader
        blending: false
        fragmentShader: Qt.resolvedUrl("shaders/dotimage.frag.qsb")
        onStatusChanged: if (status === ShaderEffect.Error)
            console.warn("org.nothing.dotimage: shader failed, using static Canvas:", log)

        property size res: Qt.size(width, height)
        property real look: field.look
        property real pitch: field.dotPitch
        property real fieldPitch: field.fieldPitch
        // blur ~ one field cell: texel = dotPitch / 2 px
        property real maskLod: Math.max(0, Math.log(field.fieldPitch / (field.dotPitch / 2)) / Math.LN2 - 1)
        property real maxRatio: field.maxRatio
        property real minDot: Math.min(field.minDot, field.maxRatio - 0.05)
        property real levels: field.levels
        property real contrast: field.contrast
        property real brightness: field.brightness
        property vector3d lvA: slotA.levels
        property vector3d lvB: slotB.levels
        property real fade: field.fade
        property real colorMode: field.colorMode
        property real edge: field.edges ? 1 : 0
        property real bgOn: field.backgroundGrid ? 1 : 0
        property real bgLum: 0.10
        property real base: 0.078                 // field dots ~#141414 .. #1c1c1c (org.nothing.dots)
        property real sweep: field.sweep
        property point ripple: field.ripple
        property point redPos: field._red.redPos
        property real twinkle: field.animated && field.twinkle ? 1 : 0
        property real phase: 2 * Math.PI * 6 * (field.time % field.loopLength) / field.loopLength
        property var srcA: slotA.texture
        property var srcB: slotB.texture
    }

    // Software scene graph / shader failure: static Canvas (mono, front picture only),
    // painted only when the picture, size or settings change.
    Loader {
        anchors.fill: parent
        active: !field.useShader
        sourceComponent: Canvas {
            id: cv
            renderStrategy: Canvas.Cooperative
            readonly property url src: (field.front === 0 ? slotA : slotB).source
            onSrcChanged: if (src.toString() !== "") loadImage(src); else requestPaint()
            onImageLoaded: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: field
                function onPitchChanged() { cv.requestPaint() }
                function onLevelsChanged() { cv.requestPaint() }
                function onContrastChanged() { cv.requestPaint() }
                function onBrightnessChanged() { cv.requestPaint() }
            }
            onPaint: {
                const ctx = getContext("2d"), p = field.pitch
                const cols = Math.ceil(width / p), rows = Math.ceil(height / p)
                ctx.fillStyle = "#000000"; ctx.fillRect(0, 0, width, height)
                let px = null
                if (src.toString() !== "" && isImageLoaded(src)) {
                    ctx.drawImage(src, 0, 0, cols, rows)          // stretched; fallback only
                    px = ctx.getImageData(0, 0, cols, rows).data
                    ctx.fillRect(0, 0, cols, rows)
                }
                const lv = (field.front === 0 ? slotA : slotB).levels
                for (let j = 0; j < rows; j++) for (let i = 0; i < cols; i++) {
                    let q = 0
                    if (px) {
                        const k = (j * cols + i) * 4
                        let t = (0.2126 * px[k] + 0.7152 * px[k + 1] + 0.0722 * px[k + 2]) / 255
                        t = Math.min(1, Math.max(0, (t - lv.x) / Math.max(0.02, lv.y - lv.x)))
                        t = Math.pow(t, lv.z / field.brightness)
                        t = Math.min(1, Math.max(0, (t - 0.5) * field.contrast + 0.5))
                        q = field.levels >= 2 ? Math.round(t * field.levels) / field.levels : (t < 0.06 ? 0 : t)
                    }
                    const x = (i + 0.5) * p, y = (j + 0.5) * p
                    let r, v
                    if (q > 0) { r = 0.5 * p * (field.minDot + (field.maxRatio - field.minDot) * q); v = 0.62 + 0.38 * q }
                    else if (field.backgroundGrid) { r = 0.21 * p; v = 0.10 }
                    else continue
                    ctx.fillStyle = Qt.rgba(v, v, v, 1)
                    ctx.beginPath(); ctx.arc(x, y, r, 0, 2 * Math.PI); ctx.fill()
                }
            }
        }
    }
}
