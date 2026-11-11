#!/usr/bin/env bash
# Nothing quick search: Alt+Space / Alt+F2 / Search open the Nothing drawer in search mode
# instead of KRunner, and KRunner itself (still installed: `krunner`, Alt+Shift+F2) is tuned.
#
#   scripts/quicksearch.sh install   # take KRunner's keys, bind them to nothing-search, tune krunnerrc
#   scripts/quicksearch.sh revert    # give KRunner its keys back, restore krunnerrc, remove our files
#   scripts/quicksearch.sh status    # print what the keys are bound to
#
# Applied live through kglobalaccel's DBus API (kglobalaccel runs inside kwin_wayland, so
# editing kglobalshortcutsrc alone is not picked up); kglobalaccel persists it itself.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$HOME/.local/share"
BIN="$D/nothingos/bin/nothing-search"
SVC="$D/kglobalaccel/nothingos-search.desktop"
BAK="$D/nothingos-backup/krunnerrc.orig"

ga() { gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
          --method "org.kde.KGlobalAccel.$1" "${@:2}" >/dev/null; }
KRUNNER="['org.kde.krunner.desktop', '_launch', 'KRunner', 'KRunner']"
OURS="['nothingos-search.desktop', '_launch', 'Nothing Search', 'Search']"
KEYS="[([134217760, 0, 0, 0],), ([150994993, 0, 0, 0],), ([16777362, 0, 0, 0],)]"     # Alt+Space, Alt+F2, Search
SET_PRESENT_NO_AUTOLOADING=6   # SetPresent|NoAutoloading: active now, not only after relogin

status() {
    for id in "$KRUNNER" "$OURS"; do
        printf '%-26s %s\n' "$(echo "$id" | cut -d"'" -f2)" \
            "$(gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
                 --method org.kde.KGlobalAccel.shortcutKeys "$id" 2>/dev/null || echo '(not registered)')"
    done
}

do_install() {
    # trigger + kglobalaccel service entry (absolute Exec: kwin's env has no ~/.local/bin)
    mkdir -p "$(dirname "$BIN")" "$(dirname "$SVC")"
    install -m755 "$ROOT/plasma/search/nothing-search" "$BIN"
    sed "s|@BIN@|$BIN|" "$ROOT/plasma/search/nothingos-search.desktop" > "$SVC"

    # 1. free the keys from KRunner (component stays, RunClipboard Alt+Shift+F2 untouched)
    ga setForeignShortcutKeys "$KRUNNER" "@a(ai) []"
    # 2. bind them to our service
    ga doRegister "$OURS"
    ga setShortcutKeys "$OURS" "$KEYS" "$SET_PRESENT_NO_AUTOLOADING"

    # KRunner itself, for anyone who opens it directly: centred free-floating window,
    # no history autocompletion clutter, fresh query each time, one result list for all activities
    [ -e "$BAK" ] || { mkdir -p "$(dirname "$BAK")"; if [ -e "$HOME/.config/krunnerrc" ]; then cp -a "$HOME/.config/krunnerrc" "$BAK"; else : > "$BAK"; fi; }
    kwriteconfig6 --file krunnerrc --group General --key FreeFloating true
    kwriteconfig6 --file krunnerrc --group General --key historyBehavior Disabled
    kwriteconfig6 --file krunnerrc --group General --key RetainPriorSearch false
    kwriteconfig6 --file krunnerrc --group General --key ActivityAware false
}

do_revert() {
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.unregister nothingos-search.desktop _launch >/dev/null 2>&1 || true
    rm -f "$SVC" "$BIN"
    ga setForeignShortcutKeys "$KRUNNER" "$KEYS"
    if [ -e "$BAK" ]; then
        if [ -s "$BAK" ]; then cp -a "$BAK" "$HOME/.config/krunnerrc"; else rm -f "$HOME/.config/krunnerrc"; fi
        rm -f "$BAK"
    fi
}

case "${1:-status}" in
    install) do_install; status ;;
    revert)  do_revert;  status ;;
    status)  status ;;
    *) sed -n '2,9p' "$0"; exit 1 ;;
esac
