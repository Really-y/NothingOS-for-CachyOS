import QtQuick

// Ring of dots used as a gauge (Nothing widget motif). Lit dots are white,
// turning red above `warn`.
Canvas {
    id: root
    property real value: 0
    property int dots: 28
    property real warn: 0.85
    property real dotSize: 5
    property real shown: value
    Behavior on shown { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    onShownChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const cx = width / 2, cy = height / 2, rad = Math.min(width, height) / 2 - dotSize;
        const lit = Math.round(shown * dots);
        for (let i = 0; i < dots; i++) {
            const a = -Math.PI / 2 + i / dots * Math.PI * 2;
            ctx.beginPath();
            ctx.arc(cx + Math.cos(a) * rad, cy + Math.sin(a) * rad, dotSize / 2, 0, Math.PI * 2);
            ctx.fillStyle = i < lit ? (shown >= warn ? Theme.red : Theme.fg) : Theme.card3;
            ctx.fill();
        }
    }
}
