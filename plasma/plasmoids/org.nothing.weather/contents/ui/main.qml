import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "nothing"

// Nothing weather card, fed by nothingd Weather().
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    NothingDaemon {
        id: weather
        member: "Weather"
        topic: "weather"
        interval: 10 * 60 * 1000     // refresh every 10 min (plus on Changed("weather"))
        retryInterval: 5000          // daemon missing → retry every 5 s
    }
    readonly property var w: weather.result

    toolTipMainText: w ? (w.city + "  " + Math.round(w.temp) + "°") : i18n("Weather")
    toolTipSubText: w ? w.desc : i18n("Waiting for nothingd…")

    fullRepresentation: WeatherFace {
        Layout.minimumWidth: 140
        Layout.minimumHeight: 140
        Layout.preferredWidth: 180
        Layout.preferredHeight: 180
        temp: root.w ? root.w.temp : null
        hi: root.w ? root.w.hi : null
        lo: root.w ? root.w.lo : null
        icon: root.w && root.w.icon ? root.w.icon : "cloud"
        desc: root.w ? root.w.desc : ""
        city: root.w ? root.w.city : ""
    }
}
