#!/usr/bin/env bash
# Dolphin tuned for a Nothing look (native ~/.config and Flatpak org.kde.dolphin).
#   scripts/dolphin.sh            apply (backs up originals once)
#   scripts/dolphin.sh --revert   restore the originals
set -euo pipefail
BK="$HOME/.local/share/nothingos-backup/dolphin"
FP="$HOME/.var/app/org.kde.dolphin"
# config file  ->  backup name
declare -A FILES=(
  ["$HOME/.config/dolphinrc"]=dolphinrc
  ["$HOME/.local/share/dolphin/view_properties/global/.directory"]=global.directory
  ["$FP/config/dolphinrc"]=flatpak-dolphinrc
  ["$FP/data/dolphin/view_properties/global/.directory"]=flatpak-global.directory
)

if [ "${1:-}" = --revert ]; then
  [ -d "$BK" ] || { echo "no dolphin backup"; exit 0; }
  for f in "${!FILES[@]}"; do
    b="$BK/${FILES[$f]}"
    if [ -f "$b" ]; then mkdir -p "$(dirname "$f")"; cp -a "$b" "$f"
    elif [ -f "$b.absent" ]; then rm -f "$f"; fi
  done
  [ -L "$FP/config/Kvantum" ] && rm -f "$FP/config/Kvantum"
  exit 0
fi

# one-time backup of the originals (".absent" marks files that did not exist)
if [ ! -e "$BK/.done" ]; then
  mkdir -p "$BK"
  for f in "${!FILES[@]}"; do
    if [ -f "$f" ]; then cp -a "$f" "$BK/${FILES[$f]}"; else : > "$BK/${FILES[$f]}.absent"; fi
  done
  touch "$BK/.done"
fi

STAMP=$(date +%Y,%-m,%-d,%-H,%-M,%-S)
tune() {  # $1 = dolphinrc, $2 = global view .directory
  local rc="$1" vp="$2"
  mkdir -p "$(dirname "$rc")" "$(dirname "$vp")"
  k() { kwriteconfig6 --file "$rc" "$@"; }
  # chrome: hamburger only, icon-only flat toolbar, slim floating status bar
  k --group MainWindow --key MenuBar Disabled
  k --group MainWindow --key ToolBarsMovable Disabled
  k --group MainWindow --group "Toolbar mainToolBar" --key ToolButtonStyle IconOnly
  k --group MainWindow --group "Toolbar mainToolBar" --key IconSize 22
  k --group General --key ShowStatusBar Small
  k --group General --key ShowZoomSlider true
  k --group General --key ShowSpaceInfo false
  k --group General --key ShowFullPath false
  k --group General --key ShowSelectionToggle false
  k --group General --key LockPanels true
  # tabs
  k --group General --key OpenExternallyCalledFolderInNewTab true
  k --group General --key OpenNewTabAfterLastTab true
  k --group General --key AlwaysShowTabBar false
  k --group General --key ShowCloseButtonOnTabs true
  k --group General --key TabStyle AutoSize
  k --group General --key RememberOpenedTabs true
  # one look for every folder: big icon grid with previews
  k --group General --key GlobalViewProps true
  k --group General --key ViewPropsTimestamp "$STAMP"
  k --group IconsMode --key IconSize 80
  k --group IconsMode --key PreviewSize 96
  k --group IconsMode --key TextWidthIndex 1
  k --group IconsMode --key MaximumTextLines 2
  k --group IconsMode --key UseSystemFont true
  k --group PlacesPanel --key IconSize 22
  kwriteconfig6 --file "$vp" --group Dolphin --key Version 4
  kwriteconfig6 --file "$vp" --group Dolphin --key ViewMode 0
  kwriteconfig6 --file "$vp" --group Dolphin --key PreviewsShown true
  kwriteconfig6 --file "$vp" --group Dolphin --key SortFoldersFirst true
  kwriteconfig6 --file "$vp" --group Dolphin --key Timestamp "$STAMP"
}

tune "$HOME/.config/dolphinrc" "$HOME/.local/share/dolphin/view_properties/global/.directory"
if [ -d "$FP" ] || flatpak info org.kde.dolphin >/dev/null 2>&1; then
  tune "$FP/config/dolphinrc" "$FP/data/dolphin/view_properties/global/.directory"
  # the sandbox reads Kvantum from its own XDG_CONFIG_HOME; point it at the real one
  [ -e "$FP/config/Kvantum" ] || ln -s "$HOME/.config/Kvantum" "$FP/config/Kvantum"
fi
