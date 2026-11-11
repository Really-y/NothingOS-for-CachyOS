pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout
    property alias formLayout: root
    property var configDialog            // set by Plasma's wallpaper settings page
    property var wallpaperConfiguration  // idem

    property string cfg_Image: ""
    property string cfg_ImageDefault: ""
    property list<string> cfg_RecentImages: []
    property list<string> cfg_RecentImagesDefault: []
    property int cfg_SlideMode: 0
    property int cfg_SlideModeDefault: 0
    property string cfg_SlideFolder: ""
    property string cfg_SlideFolderDefault: ""
    property alias cfg_SlideInterval: interval.value
    property int cfg_SlideIntervalDefault: 10
    property alias cfg_SlideShuffle: shuffle.checked
    property bool cfg_SlideShuffleDefault: false
    property int cfg_FillMode: 0
    property real cfg_FocusY: 0.3
    property real cfg_FocusYDefault: 0.3
    property int cfg_FillModeDefault: 0
    property int cfg_Look: 0
    property int cfg_LookDefault: 0
    property int cfg_FinePitch: 0
    property int cfg_FinePitchDefault: 0
    property alias cfg_DotPitch: pitch.value
    property int cfg_DotPitchDefault: 5
    property int cfg_Levels: 6
    property int cfg_LevelsDefault: 6
    property alias cfg_MinDotSize: minDot.value
    property real cfg_MinDotSizeDefault: 0.18
    property alias cfg_Contrast: contrast.value
    property real cfg_ContrastDefault: 1.2
    property alias cfg_Brightness: brightness.value
    property real cfg_BrightnessDefault: 1.0
    property alias cfg_AutoLevels: autoLevels.checked
    property bool cfg_AutoLevelsDefault: true
    property real cfg_BlackPoint: 0.0
    property real cfg_BlackPointDefault: 0.0
    property real cfg_WhitePoint: 1.0
    property real cfg_WhitePointDefault: 1.0
    property int cfg_ColorMode: 0
    property int cfg_ColorModeDefault: 0
    property alias cfg_EdgeEmphasis: edges.checked
    property bool cfg_EdgeEmphasisDefault: true
    property alias cfg_BackgroundGrid: bgGrid.checked
    property bool cfg_BackgroundGridDefault: true
    property alias cfg_Animate: animate.checked
    property bool cfg_AnimateDefault: true
    property alias cfg_Twinkle: twinkle.checked
    property bool cfg_TwinkleDefault: true

    function toUrl(s) {
        s = (s || "").toString()
        return s.startsWith("/") ? "file://" + s : s
    }
    function fileName(u) {
        const s = decodeURIComponent(u.toString())
        return s.substring(s.lastIndexOf("/") + 1)
    }
    function isImage(u) { return /\.(png|jpe?g|webp|bmp|gif|avif|jxl|tiff?|heic|svg)$/i.test(u.toString()) }
    function pick(u) {
        u = u.toString()
        if (u === "") return
        root.cfg_Image = u
        root.cfg_SlideMode = 0
        const rec = [u]
        for (const r of root.cfg_RecentImages) if (r !== u && rec.length < 6) rec.push(r)
        root.cfg_RecentImages = rec
    }

    // ---- picture ---------------------------------------------------------------
    QQC2.ComboBox {
        Kirigami.FormData.label: "Source:"
        model: ["Single picture", "Slideshow folder"]
        currentIndex: root.cfg_SlideMode === 1 ? 1 : 0
        onActivated: index => root.cfg_SlideMode = index
    }

    // preview + drop target
    Rectangle {
        Kirigami.FormData.label: root.cfg_SlideMode === 0 ? "Picture:" : ""
        visible: root.cfg_SlideMode === 0
        implicitWidth: Kirigami.Units.gridUnit * 16
        implicitHeight: Kirigami.Units.gridUnit * 9
        color: "#000000"
        radius: Kirigami.Units.cornerRadius
        border.width: drop.containsDrag ? 2 : 1
        border.color: drop.containsDrag ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.15)
        Item {   // same framing as the wallpaper (Fill keeps the vertical focus; Fit = bars)
            id: thumbFrame
            anchors.fill: parent; anchors.margins: 1
            clip: true
            Image {
                id: thumb
                source: root.toUrl(root.cfg_Image)
                sourceSize: Qt.size(512, 512)
                asynchronous: true
                readonly property real nw: Math.max(1, implicitWidth)
                readonly property real nh: Math.max(1, implicitHeight)
                readonly property real s: root.cfg_FillMode === 0 ? Math.max(thumbFrame.width / nw, thumbFrame.height / nh)
                                        : root.cfg_FillMode === 1 ? Math.min(thumbFrame.width / nw, thumbFrame.height / nh)
                                        : Math.min(thumbFrame.width / nw, thumbFrame.height / nh)   // Center: approximated as Fit
                width: nw * s; height: nh * s
                x: (thumbFrame.width - width) / 2
                y: (thumbFrame.height - height) * (root.cfg_FillMode === 0 && height > thumbFrame.height ? root.cfg_FocusY : 0.5)
            }
        }
        QQC2.Label {
            anchors.centerIn: parent
            visible: root.cfg_Image === ""
            text: "Choose or drop a picture"
            color: "#8e8e8e"
        }
        DropArea {
            id: drop
            anchors.fill: parent
            keys: ["text/uri-list"]
            onDropped: drop => { if (drop.hasUrls && root.isImage(drop.urls[0])) root.pick(drop.urls[0]) }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: fileDialog.open() }
    }
    RowLayout {
        visible: root.cfg_SlideMode === 0
        QQC2.Button { text: "Choose…"; icon.name: "document-open"; onClicked: fileDialog.open() }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            text: root.cfg_Image === "" ? "" : root.fileName(root.cfg_Image)
            elide: Text.ElideMiddle; opacity: 0.7
        }
    }
    Row {
        Kirigami.FormData.label: "Recent:"
        visible: root.cfg_SlideMode === 0 && root.cfg_RecentImages.length > 1
        spacing: Kirigami.Units.smallSpacing
        Repeater {
            model: root.cfg_RecentImages
            delegate: QQC2.ToolButton {
                id: recentBtn
                required property string modelData
                implicitWidth: Kirigami.Units.gridUnit * 3.6
                implicitHeight: Kirigami.Units.gridUnit * 2.4
                checkable: false
                highlighted: modelData === root.cfg_Image
                QQC2.ToolTip.text: root.fileName(modelData)
                QQC2.ToolTip.visible: hovered
                contentItem: Image {
                    source: root.toUrl(recentBtn.modelData)
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectCrop; asynchronous: true; clip: true
                }
                onClicked: root.pick(modelData)
            }
        }
    }

    // slideshow
    RowLayout {
        Kirigami.FormData.label: "Folder:"
        visible: root.cfg_SlideMode === 1
        QQC2.TextField {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            text: decodeURIComponent(root.cfg_SlideFolder.replace(/^file:\/\//, ""))
            placeholderText: "Pick a folder of pictures"
            onEditingFinished: root.cfg_SlideFolder = text === "" ? "" : root.toUrl(text)
        }
        QQC2.Button { icon.name: "folder-open"; onClicked: folderDialog.open(); QQC2.ToolTip.text: "Choose folder"; QQC2.ToolTip.visible: hovered }
    }
    QQC2.SpinBox {
        id: interval
        Kirigami.FormData.label: "Change every:"
        visible: root.cfg_SlideMode === 1
        from: 1; to: 1440
        textFromValue: v => v + " min"
        valueFromText: t => parseInt(t)
    }
    QQC2.CheckBox { id: shuffle; visible: root.cfg_SlideMode === 1; text: "Shuffle" }

    QQC2.ComboBox {
        Kirigami.FormData.label: "Positioning:"
        model: ["Fill: cover the whole screen (crops)", "Fit: whole picture, dot grid at the sides", "Center: native size"]
        currentIndex: Math.max(0, Math.min(2, root.cfg_FillMode))
        onActivated: index => root.cfg_FillMode = index
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: "Keep in view:"
        visible: root.cfg_FillMode === 0
        model: ["Top", "Upper third (faces)", "Center", "Bottom"]
        readonly property var values: [0.0, 0.3, 0.5, 1.0]
        currentIndex: {
            let best = 0
            for (let i = 1; i < values.length; i++)
                if (Math.abs(values[i] - root.cfg_FocusY) < Math.abs(values[best] - root.cfg_FocusY)) best = i
            return best
        }
        onActivated: index => root.cfg_FocusY = values[index]
    }

    Item { Kirigami.FormData.isSection: true }

    // ---- dots ------------------------------------------------------------------
    QQC2.ComboBox {
        Kirigami.FormData.label: "Look:"
        model: ["Glyph field (fine dots over the dim field)", "Halftone (one dot grid)"]
        currentIndex: root.cfg_Look === 1 ? 1 : 0
        onActivated: index => root.cfg_Look = index
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: "Picture dots:"
        visible: root.cfg_Look === 0
        model: ["Auto (4 px, coarser for small pictures)", "3 px (finest)", "4 px", "6 px", "8 px"]
        readonly property var values: [0, 3, 4, 6, 8]
        currentIndex: Math.max(0, values.indexOf(root.cfg_FinePitch))
        onActivated: index => root.cfg_FinePitch = values[index]
    }
    QQC2.SpinBox {
        id: pitch
        visible: root.cfg_Look === 1
        Kirigami.FormData.label: "Dot pitch:"
        from: 3; to: 16
        textFromValue: v => v + " px"
        valueFromText: t => parseInt(t)
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: "Dot sizes:"
        visible: root.cfg_Look === 1
        model: ["Smooth (continuous)", "3", "4", "5", "6 (default)"]
        readonly property var values: [0, 3, 4, 5, 6]
        currentIndex: Math.max(0, values.indexOf(root.cfg_Levels))
        onActivated: index => root.cfg_Levels = values[index]
    }
    RowLayout {
        Kirigami.FormData.label: "Smallest dot:"
        visible: root.cfg_Look === 1
        QQC2.Slider { id: minDot; from: 0.0; to: 0.6; stepSize: 0.02 }
        QQC2.Label { text: Math.round(minDot.value * 100) + " %"; opacity: 0.7 }
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: "Colour:"
        model: ["Monochrome white", "Original colours", "Mono + Nothing red accent"]
        currentIndex: Math.max(0, Math.min(2, root.cfg_ColorMode))
        onActivated: index => root.cfg_ColorMode = index
    }

    Item { Kirigami.FormData.isSection: true }

    // ---- tone ------------------------------------------------------------------
    QQC2.CheckBox { id: autoLevels; Kirigami.FormData.label: "Tones:"; text: "Auto levels (stretch dark pictures)" }
    RowLayout {
        Kirigami.FormData.label: "Black / white point:"
        enabled: !autoLevels.checked
        QQC2.RangeSlider {
            id: blackPoint
            from: 0; to: 1; stepSize: 0.01
            first.value: root.cfg_BlackPoint
            second.value: root.cfg_WhitePoint
            first.onMoved: root.cfg_BlackPoint = first.value
            second.onMoved: root.cfg_WhitePoint = second.value
        }
        QQC2.Label { text: blackPoint.first.value.toFixed(2) + " – " + blackPoint.second.value.toFixed(2); opacity: 0.7 }
    }
    RowLayout {
        Kirigami.FormData.label: "Brightness:"
        QQC2.Slider { id: brightness; from: 0.5; to: 2.0; stepSize: 0.05 }
        QQC2.Label { text: brightness.value.toFixed(2); opacity: 0.7 }
    }
    RowLayout {
        Kirigami.FormData.label: "Contrast:"
        QQC2.Slider { id: contrast; from: 0.5; to: 2.0; stepSize: 0.05 }
        QQC2.Label { text: contrast.value.toFixed(2); opacity: 0.7 }
    }
    QQC2.CheckBox { id: edges; Kirigami.FormData.label: "Detail:"; text: "Sharpen edges (line art)" }
    QQC2.CheckBox { id: bgGrid; visible: root.cfg_Look === 1; text: "Faint background dot grid" }

    Item { Kirigami.FormData.isSection: true }

    QQC2.CheckBox { id: animate; Kirigami.FormData.label: "Motion:"; text: "Glyph sweep every 8 s (off = static)" }
    QQC2.CheckBox { id: twinkle; text: "Gentle twinkle"; enabled: animate.checked }

    QtDialogs.FileDialog {
        id: fileDialog
        title: "Choose a picture"
        fileMode: QtDialogs.FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.gif *.avif *.jxl *.tif *.tiff *.heic *.svg)", "All files (*)"]
        onAccepted: root.pick(selectedFile)
    }
    QtDialogs.FolderDialog {
        id: folderDialog
        title: "Choose a slideshow folder"
        onAccepted: root.cfg_SlideFolder = selectedFolder.toString()
    }
}
