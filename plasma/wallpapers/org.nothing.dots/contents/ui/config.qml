import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout
    property alias formLayout: root

    property int cfg_DotPitch: 24
    property int cfg_DotPitchDefault: 24
    property alias cfg_SweepSpeed: speed.value
    property real cfg_SweepSpeedDefault: 1.0
    property alias cfg_ShowRedDot: redDot.checked
    property bool cfg_ShowRedDotDefault: true
    property alias cfg_Ripples: ripples.checked
    property bool cfg_RipplesDefault: true
    property alias cfg_PointerGlow: pointerGlow.checked
    property bool cfg_PointerGlowDefault: false
    property alias cfg_ShowCharacter: character.checked
    property bool cfg_ShowCharacterDefault: true
    property alias cfg_CharacterPosition: charPos.value
    property real cfg_CharacterPositionDefault: 0.75
    property alias cfg_CharacterScale: charScale.value
    property real cfg_CharacterScaleDefault: 1.0
    property alias cfg_Animate: animate.checked
    property bool cfg_AnimateDefault: true

    QQC2.ComboBox {
        Kirigami.FormData.label: "Dot pitch:"
        model: ["16 px", "24 px", "32 px"]
        readonly property var values: [16, 24, 32]
        currentIndex: Math.max(0, values.indexOf(root.cfg_DotPitch))
        onActivated: index => root.cfg_DotPitch = values[index]
    }

    QQC2.Slider {
        id: speed
        Kirigami.FormData.label: "Sweep speed:"
        from: 0.5; to: 2.0; stepSize: 0.25
        enabled: animate.checked
    }
    QQC2.Label {
        text: speed.value.toFixed(2) + "× · one sweep every " + (11 / speed.value).toFixed(1) + " s"
        opacity: 0.7
    }

    QQC2.CheckBox { id: character; Kirigami.FormData.label: "Character:"; text: "Dot-matrix anime girl" }
    QQC2.Slider {
        id: charPos
        Kirigami.FormData.label: "Position:"
        from: 0.15; to: 0.85; stepSize: 0.01
        enabled: character.checked
    }
    QQC2.Slider {
        id: charScale
        Kirigami.FormData.label: "Size:"
        from: 0.6; to: 1.25; stepSize: 0.01
        enabled: character.checked
    }

    QQC2.CheckBox { id: redDot; Kirigami.FormData.label: "Accent:"; text: "Breathing red dot (her hair clip)" }
    QQC2.CheckBox { id: ripples; text: "Occasional ripple from the red dot"; enabled: redDot.checked && animate.checked }
    QQC2.CheckBox { id: pointerGlow; Kirigami.FormData.label: "Pointer:"; text: "Dots glow near the pointer"; enabled: animate.checked }
    QQC2.CheckBox { id: animate; Kirigami.FormData.label: "Motion:"; text: "Animate (off = static frame)" }
}
