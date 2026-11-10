#!/usr/bin/env bash
# Render a preview QML file offscreen to PNG (no screen capture, nothing private).
# usage: tools/render.sh path/to/Preview.qml out.png [width height]
set -euo pipefail
QML="$(realpath "$1")"; OUT="$(realpath -m "$2")"; W="${3:-800}"; H="${4:-600}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/Render.qml" <<EOQ
import QtQuick
import QtQuick.Window
Window {
    width: $W; height: $H; visible: true; color: "#000000"
    Loader { id: l; anchors.fill: parent; source: "file://$QML" }
    Timer { interval: 1500; running: true; onTriggered: l.parent.contentItem ? 0 : 0 }
    Timer {
        interval: 1600; running: true
        onTriggered: contentItem.grabToImage(r => { r.saveToFile("$OUT"); Qt.quit(); })
    }
}
EOQ
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software timeout 20 /usr/lib/qt6/bin/qml "$TMP/Render.qml" 2>&1 | grep -vE "QML debugging|^$" || true
[ -f "$OUT" ] && echo "rendered $OUT"
