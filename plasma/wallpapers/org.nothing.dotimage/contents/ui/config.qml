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
    property int cfg_FillModeDefault: 0
    property alias cfg_DotPitch: pitch.value
    property int cfg_DotPitchDefault: 8
    property int cfg_Levels: 5
    property int cfg_LevelsDefault: 5
    property alias cfg_MinDotSize: minDot.value
    property real cfg_MinDotSizeDefault: 0.18
    property alias cfg_Contrast: contrast.value
    property real cfg_ContrastDefault: 1.15
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
    property bool cfg_EdgeEmphasisDefault: false
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
        Image {
            anchors.fill: parent; anchors.margins: 1
            source: root.toUrl(root.cfg_Image)
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: [Image.PreserveAspectCrop, Image.PreserveAspectFit, Image.Pad][Math.max(0, Math.min(2, root.cfg_FillMode))]
            asynchronous: true; clip: true
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
        model: ["Fill (crop to screen)", "Fit (whole picture, black bars)", "Center (native size)"]
        currentIndex: Math.max(0, Math.min(2, root.cfg_FillMode))
        onActivated: index => root.cfg_FillMode = index
    }

    Item { Kirigami.FormData.isSection: true }

    // ---- dots ------------------------------------------------------------------
    QQC2.SpinBox {
        id: pitch
        Kirigami.FormData.label: "Dot pitch:"
        from: 5; to: 16
        textFromValue: v => v + " px"
        valueFromText: t => parseInt(t)
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: "Dot sizes:"
        model: ["Smooth (continuous)", "3", "4", "5 (Nothing look)", "6"]
        readonly property var values: [0, 3, 4, 5, 6]
        currentIndex: Math.max(0, values.indexOf(root.cfg_Levels))
        onActivated: index => root.cfg_Levels = values[index]
    }
    RowLayout {
        Kirigami.FormData.label: "Smallest dot:"
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
    QQC2.CheckBox { id: edges; Kirigami.FormData.label: "Detail:"; text: "Edge emphasis (line art)" }
    QQC2.CheckBox { id: bgGrid; text: "Faint background dot grid" }

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
