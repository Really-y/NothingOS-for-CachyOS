import QtQuick

// Ring of dots used as a gauge (Nothing widget motif). Lit dots are white;
// only the lit dots past the `warn` mark turn red.
Canvas {
    id: root
    property real value: 0
    property int dots: 40
    property real warn: 0.85
    property real dotSize: 4
    property real shown: value
    property color litColor: Theme.fg
    property color warnColor: Theme.red
    property color trackColor: Theme.dotDim
    Behavior on shown { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    onShownChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const cx = width / 2, cy = height / 2, rad = Math.min(width, height) / 2 - dotSize;
        const lit = Math.round(shown * dots);
        if (!(rad > 0) || !(dotSize > 0)) return;
        for (let i = 0; i < dots; i++) {
            const a = -Math.PI / 2 + i / dots * Math.PI * 2;
            ctx.beginPath();
            ctx.arc(cx + Math.cos(a) * rad, cy + Math.sin(a) * rad, dotSize / 2, 0, Math.PI * 2);
            ctx.fillStyle = i < lit ? (i >= Math.floor(warn * dots) ? root.warnColor : root.litColor) : root.trackColor;
            ctx.fill();
        }
    }
}
