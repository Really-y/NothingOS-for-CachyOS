#!/usr/bin/env bash
# Install the "nothing" SDDM theme system-wide and make it the current theme.
# Needs root:
#
#   sudo sddm/install.sh              # install + select
#   sudo sddm/install.sh --uninstall  # remove theme + config, restore backed-up files
#
# What it does:
#   1. copies sddm/nothing -> /usr/share/sddm/themes/nothing (font symlinks dereferenced,
#      so the theme carries real font files; the greeter runs as the sddm user)
#   2. writes /etc/sddm.conf.d/nothing.conf with [Theme] Current=nothing
#   3. SDDM reads /usr/lib/sddm/sddm.conf.d, then /etc/sddm.conf.d/* alphabetically, then
#      /etc/sddm.conf last; later files win. Any *other* [Theme] Current= in a file that is
#      read after nothing.conf would silently override it, so those lines are commented out
#      (each touched file is backed up once as <file>.nothing-bak).
# Nothing is restarted: the theme shows at the next login screen.
# Preview without installing:  sddm-greeter-qt6 --test-mode --theme sddm/nothing
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/nothing"
# SDDM_ROOT is only for dry runs into a scratch tree (e.g. SDDM_ROOT=/tmp/x); leave unset.
R="${SDDM_ROOT:-}"
DEST="$R/usr/share/sddm/themes/nothing"
CONF_DIR="$R/etc/sddm.conf.d"
CONF="$CONF_DIR/nothing.conf"
MAIN_CONF="$R/etc/sddm.conf"
MARK="# disabled by nothing sddm theme installer:"

if [ "$(id -u)" -ne 0 ] && [ -z "$R" ]; then
    echo "This needs root:  sudo $0 $*" >&2
    exit 1
fi

# Files read after nothing.conf (later wins), excluding nothing.conf itself.
later_files() {
    local f
    for f in "$CONF_DIR"/*.conf; do
        [ -e "$f" ] || continue
        [ "$f" = "$CONF" ] && continue
        [[ "$(basename "$f")" > "nothing.conf" ]] && echo "$f"
    done
    [ -f "$MAIN_CONF" ] && echo "$MAIN_CONF"
    return 0
}

if [ "${1:-}" = "--uninstall" ]; then
    rm -rf "$DEST" "$CONF"
    echo "removed $DEST and $CONF"
    for b in "$CONF_DIR"/*.nothing-bak "$MAIN_CONF.nothing-bak"; do
        [ -e "$b" ] || continue
        mv -f "$b" "${b%.nothing-bak}"
        echo "restored ${b%.nothing-bak}"
    done
    exit 0
fi

[ -f "$SRC/Main.qml" ] || { echo "missing $SRC/Main.qml" >&2; exit 1; }

# 1. theme files
rm -rf "$DEST"
mkdir -p "$DEST"
cp -rL "$SRC"/. "$DEST"/
find "$DEST" -type d -exec chmod 755 {} +
find "$DEST" -type f -exec chmod 644 {} +
echo "installed $DEST"

# 2. select it
mkdir -p "$CONF_DIR"
cat > "$CONF" <<'EOF'
# Written by NothingOS sddm/install.sh — remove this file (or run install.sh --uninstall) to revert.
[Theme]
Current=nothing
EOF
echo "wrote $CONF"

# 3. neutralise overriding Current= lines in files read later
while IFS= read -r f; do
    if awk '/^\[/{s=($0=="[Theme]")} s && /^[ \t]*Current[ \t]*=/{found=1} END{exit !found}' "$f"; then
        [ -e "$f.nothing-bak" ] || cp -p "$f" "$f.nothing-bak"
        awk -v mark="$MARK" '
            /^\[/ { s = ($0 == "[Theme]") }
            s && /^[ \t]*Current[ \t]*=/ { print mark " " $0; next }
            { print }' "$f" > "$f.tmp-nothing"
        cat "$f.tmp-nothing" > "$f"; rm -f "$f.tmp-nothing"
        echo "disabled [Theme] Current= in $f (backup: $f.nothing-bak)"
    fi
done < <(later_files)

echo "done — the Nothing login screen appears next time SDDM starts."
