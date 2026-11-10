import QtQuick

// Mock greeter environment for offscreen lock screen previews: provides the context
// objects kscreenlocker_greet normally injects (authenticator, config, user name/image,
// i18n functions) and loads the real lockscreen/LockScreen.qml.
// Render with:  QML_IMPORT_PATH=previews/mock tools/render.sh previews/LockscreenPreview.qml out.png 1280 720
// (run plasma/lookandfeel/install.sh --sync first so lockscreen/nothing/ exists).
Rectangle {
    id: mock
    color: "black"
    property bool showPrompt: true
    property string notification: ""
    property var media: null
    property string typed: ""

    property string kscreenlocker_userName: "nothing"
    property string kscreenlocker_userImage: ""
    function i18nd(domain, s, a) { return s.replace("%1", a) }
    function i18ndc(domain, ctx, s, a) { return s.replace("%1", a) }
    function i18nc(ctx, s, a) { return s.replace("%1", a) }

    QtObject {
        id: authenticator
        signal failed(int kind)
        signal succeeded()
        signal noninteractiveError(int kind, var authenticator)
        signal promptForSecretChanged(string msg)
        property bool graceLocked: false
        property bool hadPrompt: true
        property int authenticatorTypes: 1
        property string infoMessage
        property string errorMessage
        property string prompt
        function startAuthenticating() {}
        function respond(p) {}
    }
    QtObject {
        id: config
        property bool alwaysShowClock: true
        property bool hideClockWhenIdle: false
        property bool showMediaControls: mock.media !== null   // never instantiate real MPRIS in previews
    }
    Item { id: wallpaper }

    Loader {
        id: loader
        anchors.fill: parent
    }
    // Pass the mocks as initial properties so the real MPRIS model is never created
    // (a preview must not pick up whatever the user is playing).
    Component.onCompleted: loader.setSource(
        "../plasma/lookandfeel/org.nothing.desktop/contents/lockscreen/LockScreen.qml",
        { previewMode: mock.showPrompt, mockMedia: mock.media, notification: mock.notification })
    // Type into the password field after load so the pill shows dots.
    Timer {
        interval: 600; running: mock.typed !== ""
        onTriggered: {
            const s = [loader.item]; // breadth-first search for the TextInput
            while (s.length) {
                const it = s.shift();
                if (it && it.echoMode !== undefined && it.passwordCharacter !== undefined) { it.text = mock.typed; break }
                if (it && it.children) for (let i = 0; i < it.children.length; ++i) s.push(it.children[i]);
            }
        }
    }
}
