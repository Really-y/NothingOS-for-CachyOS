import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.weather/contents/ui" as W

// Weather card: live data, a long city/description, larger size, daemon absent.
Rectangle {
    color: Theme.bg
    Row {
        x: 24; y: 24; spacing: 16
        W.WeatherFace { width: 180; height: 180; temp: 14; hi: 17; lo: 9; icon: "cloud"; desc: "Cloudy"; city: "BAKU" }
        W.WeatherFace { width: 180; height: 180; temp: -3; hi: 1; lo: -8; icon: "weather_snowy"; desc: "Heavy snow showers"; city: "Reykjavik Capital" }
        W.WeatherFace { width: 220; height: 220; temp: 31; hi: 34; lo: 24; icon: "sunny"; desc: "Clear sky"; city: "DUBAI" }
        W.WeatherFace { width: 180; height: 180 }
    }
}
