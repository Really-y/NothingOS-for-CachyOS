import QtQuick
import "nothing"
import "nothing/doticons.js" as DotIcons

// Nothing weather card. Pure view; null temperature renders "--" at full size.
//  square: city (top-left) · dot pictogram (top-right) · big temp + H/L (bottom-left)
//  wide:   big pictogram left · city, big temp, condition + H/L right
Card {
    id: root
    property var temp: null          // °C or null
    property var hi: null
    property var lo: null
    property var code: null          // WMO weather code (preferred for the pictogram)
    property string icon: ""         // daemon's Material icon name (fallback)
    property string desc: ""
    property string city: ""
    property string variant: "auto"  // "auto" | "square" | "wide"

    readonly property bool wide: variant === "wide" || (variant === "auto" && width / Math.max(1, height) >= 1.5)
    readonly property bool live: temp !== null && temp !== undefined && !isNaN(temp)
    readonly property real u: wide ? Math.min(width / 360, height / 180) : Math.min(width, height) / 180
    readonly property string glyph: live ? DotIcons.forWeather(code, icon) : "cloudoff"
    readonly property string tempText: live ? Math.round(temp) + "°" : "--°"
    readonly property string cityText: {
        let c = (city || "--").toUpperCase().trim();
        const cap = wide ? 16 : 10;
        if (c.length > cap) c = c.split(/[\s,]+/)[0];   // "REYKJAVIK CAPITAL" → "REYKJAVIK"
        return c.slice(0, cap);
    }
    function deg(v) { return (v === null || v === undefined || isNaN(v)) ? "--" : Math.round(v) + "°"; }
    readonly property string hiLo: "H" + deg(hi) + " L" + deg(lo)
    // Short condition names: never ellipsised.
    readonly property string condition: {
        if (!live) return "NO DATA";
        const c = code;
        if (c === null || c === undefined) return (desc || "").toUpperCase().slice(0, 14);
        if (c <= 1) return "CLEAR";
        if (c === 2) return "PARTLY CLOUDY";
        if (c === 3) return "CLOUDY";
        if (c === 45 || c === 48) return "FOG";
        if (c >= 51 && c <= 57) return "DRIZZLE";
        if (c === 65) return "HEAVY RAIN";
        if (c >= 61 && c <= 67) return "RAIN";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "SNOW";
        if (c >= 80 && c <= 82) return "SHOWERS";
        if (c >= 95) return "STORM";
        return (desc || "").toUpperCase().slice(0, 14);
    }

    padding: Math.round(20 * u)
    implicitWidth: 180
    implicitHeight: 180

    // ── Square ─────────────────────────────────────────────────────────────
    Item {
        id: sq
        visible: !root.wide
        anchors.fill: parent
        anchors.margins: root.padding

        Text {
            id: cityLabel
            width: parent.width - pict.width - 6 * root.u
            clip: true
            text: root.cityText
            color: Theme.fg2
            font.family: Theme.mono
            font.pixelSize: Math.max(10, Math.round(11 * root.u))
            font.letterSpacing: 1.2
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 8
        }
        DotGlyph {
            id: pict
            anchors.right: parent.right; anchors.rightMargin: -pitch * 0.14
            anchors.top: parent.top; anchors.topMargin: -pitch * 0.14
            width: Math.round(66 * root.u); height: width
            icon: root.glyph
            dimColor: "transparent"
        }

        Text {
            id: hl
            anchors.left: parent.left; anchors.bottom: parent.bottom
            text: root.hiLo
            color: Theme.fg2
            font.family: Theme.mono
            font.pixelSize: Math.max(10, Math.round(11 * root.u))
            font.letterSpacing: 1.2
        }
        DotString {
            id: bigTemp
            anchors.left: parent.left
            anchors.bottom: hl.top; anchors.bottomMargin: Math.round(9 * root.u)
            text: root.tempText
            color: root.live ? Theme.fg : Theme.fg3
            // ~80px type, shrunk only when "-23°" would overflow
            size: Math.min(64 * root.u, sq.width * 10 / (Math.max(columns, 1) - 1 + dotRatio))
            width: implicitWidth; height: implicitHeight
        }
    }

    // ── Wide ───────────────────────────────────────────────────────────────
    Item {
        id: wd
        visible: root.wide
        anchors.fill: parent
        anchors.margins: root.padding

        DotGlyph {
            id: wpict
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.height * 0.86, parent.width * 0.4); height: width
            icon: root.glyph
        }
        Item {
            anchors.left: wpict.right; anchors.leftMargin: Math.round(18 * root.u)
            anchors.right: parent.right
            anchors.top: parent.top; anchors.bottom: parent.bottom

            Text {
                width: parent.width
                text: root.cityText
                color: Theme.fg2
                font.family: Theme.mono
                font.pixelSize: Math.max(10, Math.round(11 * root.u))
                font.letterSpacing: 1.2
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 8
            }
            DotString {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Math.round(2 * root.u)
                text: root.tempText
                color: root.live ? Theme.fg : Theme.fg3
                size: Math.min(104 * root.u, parent.width * 10 / (Math.max(columns, 1) - 1 + dotRatio))
                width: implicitWidth; height: implicitHeight
            }
            Text {
                anchors.left: parent.left; anchors.bottom: parent.bottom
                width: parent.width - wHl.implicitWidth - 8
                text: root.condition
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: Math.max(10, Math.round(11 * root.u))
                font.letterSpacing: 1.2
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 8
            }
            Text {
                id: wHl
                anchors.right: parent.right; anchors.bottom: parent.bottom
                text: root.hiLo
                color: Theme.fg2
                font.family: Theme.mono
                font.pixelSize: Math.max(10, Math.round(11 * root.u))
                font.letterSpacing: 1.2
            }
        }
    }
}
