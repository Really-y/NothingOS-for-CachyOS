#!/usr/bin/env bash
# One app per job: default browser / files / archives, and hide the duplicates from the
# drawer and KRunner (NoDisplay copies in ~/.local/share/applications; nothing is
# uninstalled).  --revert removes the hidden copies and restores the backup.
set -euo pipefail

APPS=~/.local/share/applications
BK=~/.local/share/nothingos-backup/defaults
TAG="X-NothingOS-Hidden=true"

BROWSER=com.google.Chrome.desktop
FILES=org.kde.dolphin.desktop
ARCHIVE=xarchiver.desktop
HIDE=(org.gnome.Nautilus.desktop thunar.desktop thunar-bulk-rename.desktop thunar-settings.desktop
      thunar-volman-settings.desktop xterm.desktop uxterm.desktop firefox.desktop
      com.brave.Browser.desktop Alacritty.desktop)

find_desktop() {
    for d in /usr/share/applications /var/lib/flatpak/exports/share/applications \
             ~/.local/share/flatpak/exports/share/applications; do
        [ -f "$d/$1" ] && { echo "$d/$1"; return; }
    done
    return 0
}

if [ "${1:-}" = "--revert" ]; then
    for f in "$APPS"/*.desktop; do
        grep -q "^$TAG" "$f" || continue
        if [ -f "$BK/apps/$(basename "$f")" ]; then cp "$BK/apps/$(basename "$f")" "$f"; else rm -f "$f"; fi
    done
    [ -f "$BK/mimeapps.list" ] && cp "$BK/mimeapps.list" ~/.config/mimeapps.list
    [ -f "$BK/kdeglobals" ] && cp "$BK/kdeglobals" ~/.config/kdeglobals
    kbuildsycoca6 >/dev/null 2>&1 || true
    echo "reverted"; exit 0
fi

# first run only: keep the original state
if [ ! -d "$BK" ]; then
    mkdir -p "$BK/apps"
    cp ~/.config/mimeapps.list "$BK/" 2>/dev/null || true
    cp ~/.config/kdeglobals "$BK/"
    for n in "${HIDE[@]}"; do [ -f "$APPS/$n" ] && cp "$APPS/$n" "$BK/apps/"; done
fi

# hide duplicates (Alacritty stays reachable as "Terminal", alacritty-terminal.desktop)
for n in "${HIDE[@]}"; do
    dst="$APPS/$n"
    if [ ! -f "$dst" ]; then
        src=$(find_desktop "$n")
        [ -n "$src" ] || continue
        cp "$src" "$dst"
    fi
    grep -q "^$TAG" "$dst" && continue
    python3 - "$dst" "$TAG" <<'EOF'
import sys, re
p, tag = sys.argv[1], sys.argv[2]
s = open(p).read()
head, sep, rest = s.partition('[Desktop Entry]\n')
# only the main group: drop an existing NoDisplay there, add ours
main, nxt, tail = rest.partition('\n[')
main = re.sub(r'^NoDisplay=.*\n?', '', main, flags=re.M)
open(p, 'w').write(f'{head}{sep}NoDisplay=true\n{tag}\n{main}{nxt}{tail}')
EOF
done

# default handlers
for m in x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about x-scheme-handler/unknown \
         text/html application/xhtml+xml application/pdf image/png image/jpeg image/gif image/webp \
         image/svg+xml image/avif image/bmp; do
    xdg-mime default "$BROWSER" "$m" 2>/dev/null
done
xdg-mime default "$FILES" inode/directory 2>/dev/null
for m in application/zip application/x-tar application/x-7z-compressed application/x-rar \
         application/vnd.rar application/gzip application/x-compressed-tar \
         application/x-xz-compressed-tar application/zstd application/x-zstd-compressed-tar; do
    xdg-mime default "$ARCHIVE" "$m" 2>/dev/null
done
sed -i '/^application\/x-wayland-gnome-saved-search=thunar.desktop$/d' ~/.config/mimeapps.list
xdg-settings set default-web-browser "$BROWSER" 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group General --key BrowserApplication "$BROWSER"

kbuildsycoca6 >/dev/null 2>&1 || true
echo "browser=$BROWSER files=$FILES terminal=alacritty archive=$ARCHIVE"
echo "hidden: ${HIDE[*]}"
