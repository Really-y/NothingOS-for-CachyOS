import QtQuick
import "../plasma/plasmoids/shared"

// Nothing mimetype / device / small place icons (icons/Nothing) rendered through QtSvg.
Rectangle {
    color: "#0b0b0b"
    property real zoom: 1
    readonly property string base: Qt.resolvedUrl("../icons/Nothing/")
    readonly property var mimes: ["text-plain", "text-x-python", "text-markdown", "text-html", "application-json",
        "image-png", "video-mp4", "audio-mpeg", "application-pdf", "application-zip", "application-x-compressed-tar",
        "application-x-executable", "application-x-shellscript", "application-vnd.oasis.opendocument.text",
        "application-vnd.oasis.opendocument.spreadsheet", "application-vnd.oasis.opendocument.presentation",
        "font-ttf", "application-x-deb", "application-octet-stream"]
    readonly property var places: ["user-home", "folder-desktop", "folder-documents", "folder-download", "folder-music",
        "folder-pictures", "folder-videos", "folder", "folder-favorites", "folder-network", "user-trash"]
    readonly property var devices: ["drive-harddisk", "drive-harddisk-solidstate", "drive-removable-media-usb",
        "media-flash", "drive-optical", "media-removable"]

    component IconRow: Row {
        property var names: []
        property string dir: ""
        property int px: 48
        spacing: px < 30 ? 10 : 8
        Repeater {
            model: names
            Image {
                required property string modelData
                width: px * (px < 30 ? zoom : 1); height: width; smooth: false
                sourceSize: Qt.size(px, px)
                source: base + dir + "/" + modelData + ".svg"
            }
        }
    }

    Column {
        x: 24; y: 20; spacing: 14
        Label { text: "Mimetypes · 48px (scalable)" }
        IconRow { names: mimes; dir: "scalable/mimetypes"; px: 48 }
        Label { text: "Mimetypes · 22px / 16px" + (zoom > 1 ? " ×" + zoom : "") }
        IconRow { names: mimes; dir: "22/mimetypes"; px: 22 }
        IconRow { names: mimes; dir: "16/mimetypes"; px: 16 }
        Label { text: "Places (Dolphin sidebar) · 22px / 16px — bare glyph" + (zoom > 1 ? " ×" + zoom : "") }
        IconRow { names: places; dir: "22/places"; px: 22 }
        IconRow { names: places; dir: "16/places"; px: 16 }
        Label { text: "Devices · 48px disc / 22px / 16px bare glyph" }
        Row {
            spacing: 24
            IconRow { names: devices; dir: "scalable/devices"; px: 48 }
            IconRow { names: devices; dir: "22/devices"; px: 22; anchors.verticalCenter: parent.verticalCenter }
            IconRow { names: devices; dir: "16/devices"; px: 16; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
