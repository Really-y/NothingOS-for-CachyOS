pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window

// Nothing "Dot Image": the visual part of org.nothing.dotimage, no Plasma deps
// (rendered offscreen by previews/DotImagePreview.qml).
//
// Two picture slots (A, B) ping-pong: a new `source` loads into the hidden slot, and once
// the picture and its auto levels are ready, `fade` animates over so the dots morph from
// the old picture to the new one. Each slot is the picture fitted to the screen and
// shrunk by a ShaderEffectSource to 2 texels per grid cell (the shader samples cell centres).
//
// Timeline (pure function of `time`, s): cycle = 8 s, loop = 3 cycles = 24 s.
//   0.00–0.32 cycle  Glyph band sweeps top-left -> bottom-right
//   always           sparse twinkle, 4 s / 2 s periods (integer number per loop)
Item {
    id: field

    property url source
    property int fillMode: 0              // 0 Fill (cover), 1 Fit (contain), 2 Center
    property int pitch: 8
    property real maxRatio: 0.84
    property real minDot: 0.18
    property int levels: 5                // 0 = continuous
    property real contrast: 1.0
    property real brightness: 1.0
    property bool autoLevels: true
    property real blackPoint: 0.0
    property real whitePoint: 1.0
    property int colorMode: 0             // 0 mono, 1 colour, 2 mono + red accent
    property bool edges: false
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
    // true while the band is on screen (driver uses the higher frame rate)
    readonly property bool active: sweep >= 0 || fadeAnim.running
    // seconds until the next sweep starts (driver sleeps this long when nothing else moves)
    readonly property real untilSweep: cycle - (time % cycle)

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
            || ((img.status === Image.Ready || img.status === Image.Error) && (!field.autoLevels || probe.done))
        readonly property vector3d levels: field.autoLevels ? probe.levels
            : Qt.vector3d(field.blackPoint, Math.max(field.blackPoint + 0.02, field.whitePoint), 1)
        readonly property alias texture: tex
        width: field.width; height: field.height
        onReadyChanged: if (ready) field._tryFlip()

        Image {
            id: img
            anchors.fill: parent
            asynchronous: true
            autoTransform: true
            cache: false
            smooth: true
            mipmap: true                    // trilinear shrink into the 2-texel-per-cell texture
            fillMode: field.fillMode === 1 ? Image.PreserveAspectFit
                    : field.fillMode === 2 ? Image.Pad : Image.PreserveAspectCrop
            // decode near screen size (Center keeps native pixels)
            sourceSize: field.fillMode === 2 ? undefined
                : Qt.size(Math.max(1, slot.width * Screen.devicePixelRatio), Math.max(1, slot.height * Screen.devicePixelRatio))
            onStatusChanged: if (status === Image.Error) console.warn("org.nothing.dotimage: cannot load", source)
        }
        ShaderEffectSource {
            id: tex
            sourceItem: img
            hideSource: true
            visible: false
            smooth: true
            textureSize: Qt.size(Math.max(2, Math.ceil(field.width / field.pitch) * 2),
                                 Math.max(2, Math.ceil(field.height / field.pitch) * 2))
        }
        LevelProbe { id: probe; source: field.autoLevels ? img.source : ""; opacity: 0 }
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
        property real pitch: field.pitch
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
        property real sweep: field.sweep
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
