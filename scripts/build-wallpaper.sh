#!/usr/bin/env bash
# Build + install the live wallpaper package org.nothing.dots (Plasma/Wallpaper KPackage).
#
#   scripts/build-wallpaper.sh            # recompile shaders if changed, install/update package
#   scripts/build-wallpaper.sh --shaders  # only recompile shaders (.frag -> .frag.qsb, committed)
#   scripts/build-wallpaper.sh --figure   # re-bake the character (wallpapers/glyphgirl/girl.svg -> figure*.png)
#   scripts/build-wallpaper.sh --apply    # also set it on every desktop, live (no plasmashell restart)
#   scripts/build-wallpaper.sh --revert   # put every desktop back on the static Nothing image
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$ROOT/plasma/wallpapers/org.nothing.dots"
ID=org.nothing.dots
QSB="${QSB:-$(command -v qsb6 || command -v qsb || echo /usr/lib/qt6/bin/qsb)}"
STATIC_IMG="$HOME/.local/share/wallpapers/nothing/nothing-sweep.png"

shaders() {
    for f in "$PKG"/contents/ui/shaders/*.frag; do
        out="$f.qsb"
        [ -f "$out" ] && [ "$out" -nt "$f" ] && continue
        if [ -x "$QSB" ]; then
            "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$out" "$f" && echo "qsb  $(basename "$out")"
        else
            echo "qsb not found (qt6-shadertools); using committed $(basename "$out")" >&2
        fi
    done
}

js_apply() {  # $1 = plugin, $2 = extra JS run per desktop
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        "for (const d of desktops()) { d.wallpaperPlugin = '$1'; $2 d.reloadConfig(); }" >/dev/null
}

case "${1:-}" in
    --shaders) shaders; exit 0 ;;
    --figure) python3 "$ROOT/wallpapers/glyphgirl/gen_figure.py"; exit 0 ;;
    --revert)
        js_apply org.kde.image "d.currentConfigGroup = ['Wallpaper','org.kde.image','General']; $( [ -f "$STATIC_IMG" ] && echo "d.writeConfig('Image', 'file://$STATIC_IMG');" )"
        echo "wallpaper -> org.kde.image"; exit 0 ;;
esac

shaders
if kpackagetool6 -t Plasma/Wallpaper --show "$ID" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Wallpaper -u "$PKG" >/dev/null && echo "upd  $ID"
else
    kpackagetool6 -t Plasma/Wallpaper -i "$PKG" >/dev/null && echo "inst $ID"
fi
if [ "${1:-}" = --apply ]; then
    js_apply "$ID" "d.currentConfigGroup = ['Wallpaper','$ID','General'];"
    echo "wallpaper -> $ID"
fi
