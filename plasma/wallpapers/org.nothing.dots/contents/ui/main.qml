import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid

// org.nothing.dots — Nothing "Glyph field" live wallpaper.
//
// Cost model: one ShaderEffect draws the whole grid; the only per-frame work is
// bumping one `time` value. Frame rate is adaptive and capped:
//   24 fps while the Glyph band / ripple / a blink / pointer glow is moving,
//   12 fps at rest with the character (hair sway + breathing are slow),
//    8 fps at rest without her (only the red dot breathes),
//    0 fps when hidden, when Animate is off, or when the compositor stops
//          presenting our window (locked, covered by a fullscreen window, DPMS):
//          each tick waits for the previous frame to be swapped; while no frames
//          are swapped only a 2 s watchdog wakes up.
WallpaperItem {
    id: root

    readonly property var cfg: root.configuration
    readonly property bool animate: cfg.Animate
    readonly property bool pointerGlow: cfg.PointerGlow

    GlyphField {
        id: field
        anchors.fill: parent
        pitch: [16, 24, 32].includes(root.cfg.DotPitch) ? root.cfg.DotPitch : 24
        speed: Math.min(3, Math.max(0.25, root.cfg.SweepSpeed))
        showRedDot: root.cfg.ShowRedDot
        ripples: root.cfg.Ripples
        animated: root.animate
        showFigure: root.cfg.ShowCharacter
        figureStyle: root.cfg.CharacterStyle
        figureX: Math.min(0.9, Math.max(0.1, root.cfg.CharacterPosition))
        figureScale: Math.min(1.4, Math.max(0.5, root.cfg.CharacterScale))
        mouse: pointer.item ? Qt.point(pointer.item.mouseX, pointer.item.mouseY) : Qt.point(-1000, -1000)
    }

    // Hover-only: no buttons accepted, so clicks / right-click menus fall through
    // to the desktop. Only created when the option is on (default off).
    Loader {
        id: pointer
        anchors.fill: parent
        active: root.pointerGlow && root.animate
        sourceComponent: MouseArea {
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            onPositionChanged: { root.wakeUntil = Date.now() + 700; root.fast = true }
            onContainsMouseChanged: { root.wakeUntil = Date.now() + 700; root.fast = true }
        }
    }

    // ---- driver -------------------------------------------------------------
    property double lastMs: 0
    property double wakeUntil: 0
    property bool framePending: false
    property bool fast: false
    readonly property bool running: root.animate && root.visible && root.width > 0 && field.useShader

    function advance() {
        const now = Date.now()
        const dt = root.lastMs > 0 ? Math.min(0.25, (now - root.lastMs) / 1000) : 0
        root.lastMs = now
        field.time = (field.time + dt) % field.loopLength
        const target = pointer.item && pointer.item.containsMouse ? 1 : 0
        if (field.mouseOn !== target)
            field.mouseOn = Math.abs(target - field.mouseOn) < 0.08 ? target : field.mouseOn + (target - field.mouseOn) * 0.25
        root.fast = field.active || field.mouseOn !== target || now < root.wakeUntil
    }

    onRunningChanged: { root.lastMs = 0; root.framePending = false; root.fast = false }

    Connections {
        target: root.Window.window
        function onFrameSwapped() { root.framePending = false }
    }

    Timer {
        id: tick
        running: root.running && !root.framePending
        repeat: true
        interval: root.fast ? 42 : (field.idleMotion ? 83 : 125)
        onTriggered: { root.advance(); root.framePending = true }
    }
    Timer {   // compositor not presenting us (or nothing else changed): retry slowly
        running: root.running && root.framePending
        interval: 2000
        onTriggered: root.framePending = false
    }
    Timer {   // one line in the journal so the active path is verifiable
        interval: 3000; running: true
        onTriggered: console.log("org.nothing.dots: renderer =", field.useShader ? "shader" : "canvas fallback",
                                  "| animate =", root.animate, "| pitch =", field.pitch)
    }
}
