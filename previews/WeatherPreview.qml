import QtQuick
import "../plasma/plasmoids/shared"
import "../plasma/plasmoids/org.nothing.weather/contents/ui" as W

// Weather: squares (cloudy, long city + negative, clear, no data) and wide variants.
Rectangle {
    color: Theme.bg
    Column {
        x: 24; y: 24; spacing: 16
        Row {
            spacing: 16
            W.WeatherFace { width: 180; height: 180; temp: 14; hi: 17; lo: 9; code: 3; city: "BAKU" }
            W.WeatherFace { width: 180; height: 180; temp: -23; hi: -18; lo: -27; code: 75; city: "Reykjavik Capital Region" }
            W.WeatherFace { width: 180; height: 180; temp: 31; hi: 34; lo: 24; code: 0; city: "DUBAI" }
            W.WeatherFace { width: 180; height: 180 }
        }
        Row {
            spacing: 16
            W.WeatherFace { width: 360; height: 180; temp: 8; hi: 11; lo: 4; code: 63; city: "LONDON" }
            W.WeatherFace { width: 360; height: 180; temp: 22; hi: 25; lo: 16; code: 2; city: "BAKU" }
        }
        Row {
            spacing: 16
            W.WeatherFace { width: 360; height: 180; temp: 18; hi: 19; lo: 14; code: 95; city: "MUMBAI" }
            W.WeatherFace { width: 360; height: 180; temp: 1; hi: 2; lo: -1; code: 45; city: "SAN FRANCISCO" }
        }
    }
}
