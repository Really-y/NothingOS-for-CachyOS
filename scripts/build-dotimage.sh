#!/usr/bin/env bash
# Build + install the picture-to-dots wallpaper org.nothing.dotimage (Plasma/Wallpaper KPackage).
#
#   scripts/build-dotimage.sh            # recompile shaders if changed, install or upgrade the package
#   scripts/build-dotimage.sh --shaders  # only recompile shaders (.frag -> .frag.qsb, committed)
#
# Never switches the desktop wallpaper: pick "Nothing Dot Image" yourself in
# Desktop & Wallpaper settings. To load new code after an upgrade, switch the
# wallpaper away and back.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$ROOT/plasma/wallpapers/org.nothing.dotimage"
ID=org.nothing.dotimage
QSB="${QSB:-$(command -v qsb6 || command -v qsb || echo /usr/lib/qt6/bin/qsb)}"

shaders() {
    for f in "$PKG"/contents/ui/shaders/*.frag; do
        out="$f.qsb"
        [ -f "$out" ] && [ "$out" -nt "$f" ] && [ "${FORCE:-0}" = 0 ] && continue
        if [ -x "$QSB" ]; then
            "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$out" "$f" && echo "qsb  $(basename "$out")"
        else
            echo "qsb not found (qt6-shadertools); using committed $(basename "$out")" >&2
        fi
    done
}

case "${1:-}" in
    --shaders) FORCE=1 shaders; exit 0 ;;
    "") ;;
    *) echo "usage: $0 [--shaders]" >&2; exit 2 ;;
esac

shaders
if kpackagetool6 -t Plasma/Wallpaper --show "$ID" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Wallpaper -u "$PKG" >/dev/null && echo "upd  $ID"
else
    kpackagetool6 -t Plasma/Wallpaper -i "$PKG" >/dev/null && echo "inst $ID"
fi
