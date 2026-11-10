#!/usr/bin/env bash
# NothingOS for CachyOS/KDE — idempotent installer (user-level, no sudo).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D="$HOME/.local/share"
kw() { kwriteconfig6 "$@"; }

[ -e "$D/nothingos-backup/latest" ] || "$ROOT/scripts/backup.sh"

echo "· fonts";        mkdir -p "$D/fonts/nothingos"; cp "$ROOT"/fonts/*.ttf "$D/fonts/nothingos/"; fc-cache -f >/dev/null
echo "· colours";      mkdir -p "$D/color-schemes"; cp "$ROOT/plasma/colors/Nothing.colors" "$D/color-schemes/"; plasma-apply-colorscheme Nothing >/dev/null || true
for k in "font:Space Grotesk,10,-1,5,400,0,0,0,0,0" "menuFont:Space Grotesk,10,-1,5,400,0,0,0,0,0" \
         "toolBarFont:Space Grotesk,9,-1,5,400,0,0,0,0,0" "smallestReadableFont:Space Mono,8,-1,5,400,0,0,0,0,0" \
         "fixed:Space Mono,10,-1,5,400,0,0,0,0,0"; do kw --file kdeglobals --group General --key "${k%%:*}" "${k#*:}"; done
kw --file kdeglobals --group WM --key activeFont "Space Grotesk,10,-1,5,500,0,0,0,0,0"
echo "· kvantum";      mkdir -p "$HOME/.config/Kvantum"; cp -r "$ROOT/kvantum/NothingDark" "$HOME/.config/Kvantum/"
kw --file "$HOME/.config/Kvantum/kvantum.kvconfig" --group General --key theme NothingDark
kw --file kdeglobals --group KDE --key widgetStyle Breeze
echo "· decoration";   python3 "$ROOT/plasma/aurorae/gen_aurorae.py" >/dev/null; mkdir -p "$D/aurorae/themes"; rm -rf "$D/aurorae/themes/Nothing"; cp -r "$ROOT/plasma/aurorae/Nothing" "$D/aurorae/themes/"
kw --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kw --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Nothing
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
echo "· plasma theme"; python3 "$ROOT/plasma/desktoptheme/gen_desktoptheme.py" >/dev/null; mkdir -p "$D/plasma/desktoptheme"; rm -rf "$D/plasma/desktoptheme/Nothing"; cp -r "$ROOT/plasma/desktoptheme/Nothing" "$D/plasma/desktoptheme/"; plasma-apply-desktoptheme Nothing >/dev/null || true

echo "· motion"        # snappier, decisive animations
kw --file kdeglobals --group KDE --key AnimationDurationFactor 0.7
kw --file kwinrc --group Plugins --key scaleEnabled true
kw --file kwinrc --group Plugins --key fadeEnabled false
kw --file kwinrc --group Plugins --key wobblywindowsEnabled false
kw --file kwinrc --group Plugins --key magiclampEnabled false
kw --file kwinrc --group Plugins --key slidingpopupsEnabled true
kw --file kwinrc --group Effect-scale --key InScale 0.92
kw --file kwinrc --group Effect-scale --key OutScale 0.96

echo "· sounds";       python3 "$ROOT/sounds/gen_sounds.py" >/dev/null; mkdir -p "$D/sounds"; rm -rf "$D/sounds/nothing"; cp -r "$ROOT/sounds/nothing" "$D/sounds/"
kw --file kdeglobals --group Sounds --key Theme nothing
kw --file kdeglobals --group Sounds --key Enable true

echo "· wallpaper";    mkdir -p "$D/wallpapers/nothing"; cp "$ROOT"/wallpapers/*.png "$D/wallpapers/nothing/"
plasma-apply-wallpaperimage "$D/wallpapers/nothing/nothing-sweep.png" >/dev/null || true

echo "· konsole";      mkdir -p "$D/konsole"; cp "$ROOT/terminal/Nothing.colorscheme" "$D/konsole/"

echo "· shell"
mkdir -p "$D/nothingos" "$HOME/.config/autostart" "$D/dbus-1/services" "$D/applications"
ln -sfn "$ROOT/shell" "$D/nothingos/shell"
cp "$ROOT/scripts/start-shell.sh" "$D/nothingos/"
for f in org.knopwob.dunst org.kde.plasma.Notifications; do
  printf '[D-BUS Service]\nName=org.freedesktop.Notifications\nExec=%s\n' "$D/nothingos/start-shell.sh" > "$D/dbus-1/services/$f.service"
done
cat > "$HOME/.config/autostart/nothingos-shell.desktop" <<EOD
[Desktop Entry]
Type=Application
Name=Nothing Shell
Exec=$D/nothingos/start-shell.sh
X-KDE-autostart-phase=2
EOD
for t in launcher quicksettings; do
  cat > "$D/applications/nothingos-$t.desktop" <<EOD
[Desktop Entry]
Type=Application
Name=Nothing ${t^}
Exec=qs -p $D/nothingos/shell ipc call $t toggle
NoDisplay=true
EOD
done
kw --file kglobalshortcutsrc --group services --group nothingos-launcher.desktop --key _launch "Meta+Space"
kw --file kglobalshortcutsrc --group services --group nothingos-quicksettings.desktop --key _launch "Meta+N"
kw --file kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.kglobalaccel,/component/nothingos_launcher_desktop,org.kde.kglobalaccel.Component,invokeShortcut,_launch"

if [ "${NOTHING_DOCK:-1}" = 1 ]; then
  echo "· dock"; qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$ROOT/plasma/layout/dock.js")" >/dev/null || true
fi

qdbus6 org.kde.KWin /KWin reconfigure >/dev/null || true
pkill -x dunst 2>/dev/null || true
pgrep -f "qs -p $D/nothingos/shell" >/dev/null || setsid -f "$D/nothingos/start-shell.sh"
echo "Hazırdır. Qısayollar tam olaraq yenidən girişdən sonra işləyir."
