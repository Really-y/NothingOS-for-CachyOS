import QtQuick
// Offscreen preview of the KSplash theme mid-boot (stage 3 of ~6).
Loader {
    source: "../plasma/lookandfeel/org.nothing.desktop/contents/splash/Splash.qml"
    onLoaded: item.stage = 3
}
