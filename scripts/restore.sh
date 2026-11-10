#!/usr/bin/env bash
# Son ehtiyat nüsxəni (və ya verilən qovluğu) geri yükləyir.
set -euo pipefail
# default: the very first backup = the pre-Nothing original
FIRST=$(ls -d "$HOME"/.local/share/nothingos-backup/2* 2>/dev/null | sort | head -1)
SRC="${1:-$FIRST}"
[ -d "$SRC" ] || { echo "Ehtiyat nüsxə tapılmadı: $SRC"; exit 1; }
pkill -x qs 2>/dev/null || true
rm -f "$HOME/.config/autostart/nothingos-shell.desktop"
rm -f "$HOME/.local/share/dbus-1/services/org.knopwob.dunst.service" "$HOME/.local/share/dbus-1/services/org.kde.plasma.Notifications.service"
rm -f "$HOME"/.local/share/applications/nothingos-*.desktop
for f in "$SRC"/*; do
  name=$(basename "$f")
  rm -rf "$HOME/.config/$name"
  cp -a "$f" "$HOME/.config/$name"
done
plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
systemctl --user restart plasma-plasmashell.service 2>/dev/null || (plasmashell --replace >/dev/null 2>&1 & disown)
echo "Geri yükləndi: $SRC"
