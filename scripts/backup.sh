#!/usr/bin/env bash
# Hazırkı KDE/GTK ayarlarının ehtiyat nüsxəsini götürür.
set -euo pipefail
STAMP=$(date +%Y%m%d-%H%M%S)
DEST="$HOME/.local/share/nothingos-backup/$STAMP"
mkdir -p "$DEST"
FILES=(kdeglobals kwinrc kwinrulesrc plasmarc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc
       ksplashrc kscreenlockerrc breezerc kcminputrc kglobalshortcutsrc plasmanotifyrc
       gtk-3.0 gtk-4.0 gtkrc gtkrc-2.0 Kvantum xsettingsd konsolerc autostart)
for f in "${FILES[@]}"; do
  [ -e "$HOME/.config/$f" ] && cp -a "$HOME/.config/$f" "$DEST/"
done
ln -sfn "$DEST" "$HOME/.local/share/nothingos-backup/latest"
echo "Ehtiyat nüsxə: $DEST"
