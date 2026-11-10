import QtQuick
// Offscreen preview of the KSplash theme at "desktop ready" (red final dot), before the fade-out.
Loader {
    id: l
    source: "../plasma/lookandfeel/org.nothing.desktop/contents/splash/Splash.qml"
    onLoaded: item.stage = 2
    Timer { interval: 1050; running: true; onTriggered: l.item.stage = 5 }
}
