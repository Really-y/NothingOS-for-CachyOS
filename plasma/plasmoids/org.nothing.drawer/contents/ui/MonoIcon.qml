import QtQuick
import org.kde.kirigami as Kirigami
import "iconmap.js" as IconMap
import "dot3x5.js" as Dot3x5
import "nothing"

// App icon as one flat monochrome glyph (white, or black when `dark`).
// A themed "-symbolic" glyph is preferred: exact name, reverse-DNS tail, then a
// category glyph picked from the app name (iconmap.js). If none fits, the normal
// icon is masked into a flat silhouette — same colour, same mode for every app.
// Kirigami's isMask recolours on the GPU; on the software renderer used by the
// offscreen previews the icon is grabbed and recoloured on a Canvas instead.
Item {
    id: root
    property var source
    property string hint: ""                 // app name / generic name for category matching
    property int size: 24
    property bool dark: false
    property var symbolicNames: ({})
    property int discSize: 64
    property string favoriteId: ""          // "applications:<desktop-id>.desktop"
    // The Nothing icon theme (icons/appicons.py) ships nothing-glyph-<desktop-id>.svg: the exact
    // glyph the dock shows, laid out on a 64px canvas for a 64px disc. Use it as-is (no tint).
    readonly property string themeGlyph: {
        const id = String(favoriteId).replace(/^applications:/, "").replace(/\.desktop$/, "");
        if (id && symbolicNames["nothing-glyph-" + id] === true) return "nothing-glyph-" + id;
        const byIcon = typeof source === "string" ? "nothing-glyph-icon-" + source : "";
        return byIcon && symbolicNames[byIcon] === true ? byIcon : "";
    }
    property string label: ""               // app name: first letter is the dot-matrix fallback
    // nothing fits: house dot-matrix letter instead of any silhouette of the colour icon
    readonly property bool dotLetter: themeGlyph === "" && glyph === ""
    readonly property string letter: (String(label).match(/[A-Za-z0-9]/) || ["?"])[0].toUpperCase()
    property var glyphMap: ({})              // distinct per-app glyphs from IconMap.assign()
    property string key: ""
    readonly property string glyph: IconMap.resolve(source, hint, symbolicNames, glyphMap, key)
    readonly property var iconSource: themeGlyph !== "" ? themeGlyph : (glyph !== "" ? glyph : source)
    readonly property color ink: dark ? "#000000" : "#ffffff"
    readonly property bool gpu: GraphicsInfo.api !== GraphicsInfo.Software

    width: themeGlyph !== "" ? discSize : size
    height: width

    // ≥ 24px: 5×7 house dot font; smaller (result rows): 3×5 grid with fuller dots (dot3x5.js,
    // the same table the 22px theme icons use)
    DotString {
        visible: root.dotLetter && root.size > 24
        anchors.centerIn: parent
        text: root.letter
        size: root.size * 10 / 7 * 0.8
        dotRatio: 0.65
        color: root.ink
    }
    Grid {
        visible: root.dotLetter && root.size <= 24
        anchors.centerIn: parent
        columns: 3
        readonly property real pitch: root.size * 0.2
        spacing: pitch * 0.25
        Repeater {
            model: root.dotLetter && root.size <= 24 ? Dot3x5.glyph(root.letter).join("").split("") : []
            Rectangle {
                required property string modelData
                width: parent.pitch * 0.75; height: width; radius: width / 2
                color: modelData === "#" ? root.ink : "transparent"
            }
        }
    }

    Kirigami.Icon {
        id: icon
        visible: !root.dotLetter
        width: root.width; height: root.height
        x: root.gpu ? 0 : -100000          // software: keep it grabbable but out of sight
        source: root.iconSource
        // theme glyphs are already white single paths: only recolour for the black-on-white focus state
        isMask: root.gpu && (root.themeGlyph === "" || root.dark)
        roundToIconSize: false
        color: root.ink
    }

    // software path (previews only) ────────────────────────────────────
    Loader {
        active: !root.gpu && !root.dotLetter
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
                    const v = root.dark ? 0 : 1;
                    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
                        const a = src[(y * w + x) * 4 + 3];
                        if (a === 0) continue;
                        ctx.fillStyle = Qt.rgba(v, v, v, a / 255);
                        ctx.fillRect(x, y, 1, 1);
                    }
                }
            }
            Connections {
                target: root
                function onIconSourceChanged() { grab.restart(); }
                function onDarkChanged() { canvas.requestPaint(); }
            }
            Timer {
                id: grab
                interval: 50; running: true
                onTriggered: icon.grabToImage(r => { grabbed.source = r.url; })
            }
        }
    }
}
