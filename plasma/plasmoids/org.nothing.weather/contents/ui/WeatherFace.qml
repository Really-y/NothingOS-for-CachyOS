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
    // Short condition names (≤10 chars, fits beside H/L): never ellipsised.
    readonly property string condition: {
        if (!live) return "NO DATA";
        const c = code;
        if (c === null || c === undefined) return (desc || "").toUpperCase().slice(0, 10);
        if (c <= 1) return "CLEAR";
        if (c === 2) return "SOME CLOUD";
        if (c === 3) return "CLOUDY";
        if (c === 45 || c === 48) return "FOG";
        if (c >= 51 && c <= 57) return "DRIZZLE";
        if (c === 65) return "HEAVY RAIN";
        if (c >= 61 && c <= 67) return "RAIN";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "SNOW";
        if (c >= 80 && c <= 82) return "SHOWERS";
        if (c >= 95) return "STORM";
        return (desc || "").toUpperCase().slice(0, 10);
    }

    padding: Math.round(20 * u)
    implicitWidth: 180
    implicitHeight: 180

    // Caption metrics: pictograms align their first lit row with the cap height.
    FontMetrics { id: capFm; font.family: Theme.mono; font.pixelSize: root.captionPx }
    TextMetrics { id: capTm; font.family: Theme.mono; font.pixelSize: root.captionPx; text: "H" }
    readonly property int captionPx: Math.max(10, Math.round(11 * u))
    // distance from a caption's top edge to the top of its capitals
    readonly property real capTop: Math.max(0, capFm.ascent + capTm.tightBoundingRect.y)

    component Caption: Text {
        color: Theme.fg2
        font.family: Theme.mono
        font.pixelSize: root.captionPx
        font.letterSpacing: 1.2
    }

    // ── Square ─────────────────────────────────────────────────────────────
    Item {
        id: sq
        visible: !root.wide
        anchors.fill: parent
        anchors.margins: root.padding

        Caption {
            id: cityLabel
            width: parent.width - pict.width - 8 * root.u
            clip: true
            text: root.cityText
        }
        DotGlyph {
            id: pict
            anchors.right: parent.right; anchors.rightMargin: -pitch * 0.14
            y: root.capTop - pitch * 0.14
            width: Math.round(52 * root.u); height: heightForWidth(width)
            icon: root.glyph
            trimTop: true; trimBottom: true
            litColor: root.live ? Theme.fg : Theme.fg3
            halfColor: root.live ? Theme.fg2 : Theme.fg3
        }

        Caption {
            id: hl
            anchors.left: parent.left; anchors.bottom: parent.bottom
            text: root.hiLo
        }
        // Temperature is the hero: as big as the width allows (cap ≈ 96u).
        DotString {
            id: bigTemp
            anchors.left: parent.left
            anchors.bottom: hl.top; anchors.bottomMargin: Math.round(10 * root.u)
            text: root.tempText
            color: root.live ? Theme.fg : Theme.fg3
            size: Math.max(1, Math.min(96 * root.u, sq.width * 10 / (Math.max(columns, 1) - 1 + dotRatio),
                           (sq.height - hl.height - 10 * root.u - pict.y - pict.height - 8 * root.u) * 10 / (6 + dotRatio)))
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
            x: -pitch * 0.14
            y: root.capTop - pitch * 0.14
            readonly property real gridH: Math.max(11, parent.height - root.capTop - capFm.descent)
            height: gridH * (1 + 0.28 / 11)
            width: height
            icon: root.glyph
            litColor: root.live ? Theme.fg : Theme.fg3
            halfColor: root.live ? Theme.fg2 : Theme.fg3
        }
        Item {
            anchors.left: wpict.right; anchors.leftMargin: Math.round(18 * root.u)
            anchors.right: parent.right
            anchors.top: parent.top; anchors.bottom: parent.bottom

            Caption {
                id: wCity
                width: parent.width
                clip: true
                text: root.cityText
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
            Caption {
                anchors.left: parent.left; anchors.bottom: parent.bottom
                width: parent.width - wHl.implicitWidth - 8
                clip: true
                text: root.condition
                color: Theme.fg
            }
            Caption {
                id: wHl
                anchors.right: parent.right; anchors.bottom: parent.bottom
                text: root.hiLo
            }
        }
    }
}
