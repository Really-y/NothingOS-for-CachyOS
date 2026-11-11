#!/usr/bin/env bash
# Son ehtiyat nüsxəni (və ya verilən qovluğu) geri yükləyir.
set -euo pipefail
# default: the very first backup = the pre-Nothing original
FIRST=$(ls -d "$HOME"/.local/share/nothingos-backup/2* 2>/dev/null | sort | head -1)
SRC="${1:-$FIRST}"
[ -d "$SRC" ] || { echo "Ehtiyat nüsxə tapılmadı: $SRC"; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
pkill -x qs 2>/dev/null || true
# live wallpaper -> static image first (live, via plasmashell scripting), then drop the package
"$ROOT/scripts/build-wallpaper.sh" --revert >/dev/null 2>&1 || true
kpackagetool6 -t Plasma/Wallpaper -r org.nothing.dots >/dev/null 2>&1 || true
systemctl --user disable --now nothingd.service 2>/dev/null || true
# give notifications back to dunst if that was the original setup
systemctl --user unmask dunst.service 2>/dev/null || true
[ -f "$HOME/.local/share/nothingos-backup/dunst/org.freedesktop.Notifications.service" ] && \
  cp "$HOME/.local/share/nothingos-backup/dunst/org.freedesktop.Notifications.service" "$HOME/.local/share/dbus-1/services/"
"$ROOT/plasma/lookandfeel/install.sh" --revert 2>/dev/null || true
# KRunner gets Alt+Space / Alt+F2 / Search back (live, via kglobalaccel) and its original krunnerrc
# quick search shortcut removed: changing kglobalaccel components at runtime crashed KWin (see scripts/quicksearch.sh header)
rm -f "$HOME/.config/autostart/nothingos-shell.desktop"
rm -f "$HOME/.local/share/dbus-1/services/org.knopwob.dunst.service" "$HOME/.local/share/dbus-1/services/org.kde.plasma.Notifications.service"
rm -f "$HOME"/.local/share/applications/nothingos-*.desktop
"$ROOT/scripts/dolphin.sh" --revert 2>/dev/null || true
for f in "$SRC"/*; do
  name=$(basename "$f")
  rm -rf "$HOME/.config/$name"
  cp -a "$f" "$HOME/.config/$name"
done
# terminals (Konsole/Alacritty/Ghostty/Kitty/WezTerm/Starship/fastfetch) from ~/.local/share/nothingos-backup/terminal
python3 "$ROOT/terminal/gen_terminal.py" --restore 2>/dev/null || true
plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
systemctl --user restart plasma-plasmashell.service 2>/dev/null || (plasmashell --replace >/dev/null 2>&1 & disown)
echo "Geri yükləndi: $SRC"
echo "SDDM giriş ekranını geri qaytarmaq üçün: sudo $ROOT/sddm/install.sh --uninstall"
