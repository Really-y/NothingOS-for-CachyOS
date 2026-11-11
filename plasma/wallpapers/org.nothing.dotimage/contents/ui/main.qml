import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// org.nothing.dotimage — any picture (or a slideshow folder) as Nothing dot-matrix art.
//
// Cost model: one ShaderEffect draws the whole screen from a texture of ~2 texels per dot;
// the picture is decoded once per change. Per frame only two uniforms move. Frame rate:
//   20 fps while the Glyph band sweeps or a crossfade runs (~2.6 s of every 8 s),
//    8 fps between sweeps when Twinkle is on,
//    0 fps between sweeps when Twinkle is off (one wake-up per sweep),
//    0 fps when Animate is off, when hidden, or when the compositor stops presenting our
//          window (each tick waits for the previous frame to be swapped; while nothing is
//          swapped only a 2 s watchdog wakes up).
WallpaperItem {
    id: root

    readonly property var cfg: root.configuration
    readonly property bool slideshow: cfg.SlideMode === 1

    function toUrl(s) {
        s = (s || "").toString()
        return s.startsWith("/") ? "file://" + s : s
    }
    function isImage(u) { return /\.(png|jpe?g|webp|bmp|gif|avif|jxl|tiff?|heic|svg)$/i.test(u.toString()) }

    // Plasma: an image (or folder) dropped on the desktop
    onOpenUrlRequested: url => {
        const u = url.toString()
        if (root.isImage(u)) {
            root.configuration.Image = u
            root.configuration.SlideMode = 0
        } else {
            root.configuration.SlideFolder = u
            root.configuration.SlideMode = 1
        }
        root.configuration.writeConfig()
    }

    contextualActions: root.slideshow ? [nextAction] : []
    PlasmaCore.Action {
        id: nextAction
        text: "Next Dot Image"
        icon.name: "go-next-view"
        onTriggered: root.nextSlide()
    }

    DotImageField {
        id: field
        anchors.fill: parent
        source: root.slideshow ? root.slideUrl : root.toUrl(root.cfg.Image)
        fillMode: Math.max(0, Math.min(2, root.cfg.FillMode))
        focusY: Math.max(0, Math.min(1, root.cfg.FocusY))
        look: root.cfg.Look === 1 ? 1 : 0
        finePitch: [3, 4, 6, 8].includes(root.cfg.FinePitch) ? root.cfg.FinePitch : 0
        pitch: Math.max(3, Math.min(16, root.cfg.DotPitch))
        minDot: Math.max(0, Math.min(0.6, root.cfg.MinDotSize))
        levels: [0, 3, 4, 5, 6].includes(root.cfg.Levels) ? root.cfg.Levels : 6
        contrast: Math.max(0.5, Math.min(2.5, root.cfg.Contrast))
        brightness: Math.max(0.4, Math.min(2.5, root.cfg.Brightness))
        autoLevels: root.cfg.AutoLevels
        blackPoint: root.cfg.BlackPoint
        whitePoint: root.cfg.WhitePoint
        colorMode: Math.max(0, Math.min(2, root.cfg.ColorMode))
        edges: root.cfg.EdgeEmphasis
        backgroundGrid: root.cfg.BackgroundGrid
        animated: root.cfg.Animate
        twinkle: root.cfg.Twinkle
    }

    // ---- slideshow -------------------------------------------------------------
    property url slideUrl
    property int slideIndex: -1

    FolderListModel {
        id: folder
        folder: root.slideshow ? root.toUrl(root.cfg.SlideFolder) : ""
        showDirs: false
        showDotAndDotDot: false
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif", "*.avif", "*.jxl", "*.tif", "*.tiff", "*.heic", "*.svg"]
        onStatusChanged: if (status === FolderListModel.Ready && root.slideIndex < 0) root.nextSlide()
        onCountChanged: if (status === FolderListModel.Ready && root.slideIndex < 0) root.nextSlide()
    }
    onSlideshowChanged: { slideIndex = -1; if (slideshow && folder.status === FolderListModel.Ready) nextSlide() }

    function nextSlide() {
        const n = folder.count
        if (!root.slideshow || n === 0) return
        let i
        if (root.cfg.SlideShuffle && n > 1) {
            do { i = Math.floor(Math.random() * n) } while (i === root.slideIndex)
        } else {
            i = (root.slideIndex + 1) % n
        }
        root.slideIndex = i
        root.slideUrl = folder.get(i, "fileUrl")
    }

    Timer {
        running: root.slideshow && folder.count > 1
        repeat: true
        interval: Math.max(1, root.cfg.SlideInterval) * 60000
        onTriggered: root.nextSlide()
    }

    // ---- driver -------------------------------------------------------------
    property double lastMs: 0
    property bool framePending: false
    readonly property bool running: field.animated && root.visible && root.width > 0 && field.useShader

    function advance() {
        const now = Date.now()
        const dt = root.lastMs > 0 ? Math.min(10, (now - root.lastMs) / 1000) : 0
        root.lastMs = now
        field.time = (field.time + dt) % field.loopLength
    }

    onRunningChanged: { root.lastMs = 0; root.framePending = false }

    Connections {
        target: root.Window.window
        function onFrameSwapped() { root.framePending = false }
    }

    Timer {
        id: tick
        running: root.running && !root.framePending
        repeat: true
        // between sweeps without twinkle: sleep until the next sweep starts
        interval: field.active ? 50 : field.twinkle ? 125 : Math.max(50, Math.round(field.untilSweep * 1000))
        onTriggered: { root.advance(); root.framePending = true }
    }
    Timer {   // compositor not presenting us: retry slowly
        running: root.running && root.framePending
        interval: 2000
        onTriggered: root.framePending = false
    }
    Timer {   // one line in the journal so the active path is verifiable
        interval: 3000; running: true
        onTriggered: console.log("org.nothing.dotimage: renderer =", field.useShader ? "shader" : "canvas fallback",
                                  "| animate =", field.animated, "| look =", field.look === 0 ? "glyph" : "halftone", "| pitch =", field.dotPitch,
                                  "| mode =", root.slideshow ? "slideshow (" + folder.count + ")" : "single")
    }
}
