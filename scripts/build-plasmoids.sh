#!/usr/bin/env bash
# Sync the shared Nothing UI kit into every plasmoid package and install/update it.
#
#   scripts/build-plasmoids.sh                       # sync kit + install/update all packages
#   scripts/build-plasmoids.sh --sync                # only copy the kit (for offscreen previews)
#   scripts/build-plasmoids.sh org.nothing.clock ... # limit to some packages
#
# Every directory in plasma/plasmoids/ except `shared` is treated as a
# Plasma/Applet KPackage. The kit lands in <pkg>/contents/ui/nothing/ (gitignored).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLASMOIDS="$ROOT/plasma/plasmoids"
SHARED="$PLASMOIDS/shared"
SYNC_ONLY=0
ONLY=()
for a in "$@"; do
    case "$a" in
        --sync|--no-install) SYNC_ONLY=1 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) ONLY+=("$(basename "${a%/}")") ;;
    esac
done

[ -d "$SHARED" ] || { echo "missing $SHARED" >&2; exit 1; }

plugin_id() {  # KPlugin.Id from metadata.json, falling back to the dir name
    local meta="$1/metadata.json" id=""
    if command -v jq >/dev/null 2>&1; then
        id="$(jq -r '.KPlugin.Id // empty' "$meta" 2>/dev/null || true)"
    else
        id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "$meta" 2>/dev/null || true)"
    fi
    echo "${id:-$(basename "$1")}"
}

status=0
for dir in "$PLASMOIDS"/*/; do
    dir="${dir%/}"; name="$(basename "$dir")"
    [ "$name" = "shared" ] && continue
    if [ ${#ONLY[@]} -gt 0 ] && [[ ! " ${ONLY[*]} " =~ " $name " ]]; then continue; fi
    if [ ! -f "$dir/metadata.json" ] || [ ! -d "$dir/contents/ui" ]; then
        echo "skip $name (no metadata.json or contents/ui)"; continue
    fi

    # Fresh copy of the kit so removed shared files don't linger.
    kit="$dir/contents/ui/nothing"
    [ -d "$kit" ] && find "$kit" -mindepth 1 -delete
    mkdir -p "$kit"
    cp -r "$SHARED"/. "$kit"/
    echo "kit  -> $name"

    [ "$SYNC_ONLY" = 1 ] && continue
    id="$(plugin_id "$dir")"
    if kpackagetool6 -t Plasma/Applet --show "$id" >/dev/null 2>&1; then
        if kpackagetool6 -t Plasma/Applet -u "$dir" >/dev/null; then echo "upd  $id"; else echo "FAIL update $id" >&2; status=1; fi
    else
        if kpackagetool6 -t Plasma/Applet -i "$dir" >/dev/null; then echo "inst $id"; else echo "FAIL install $id" >&2; status=1; fi
    fi
done
exit $status
