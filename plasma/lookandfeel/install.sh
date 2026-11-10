#!/usr/bin/env bash
# Build, install and activate the Nothing boot splash + lock screen (per user, no root).
#
#   plasma/lookandfeel/install.sh            # sync kit, install/update packages, activate splash + lock screen
#   plasma/lookandfeel/install.sh --sync     # only assemble files (for offscreen previews), no install
#   plasma/lookandfeel/install.sh --no-activate   # install packages but leave settings alone
#   plasma/lookandfeel/install.sh --revert   # restore previous splash, drop the lock screen override
#
# What gets installed:
#   Plasma/LookAndFeel  org.nothing.desktop  (splash, lockscreen sources, defaults)
#   Plasma/Shell        org.nothing.desktop  (carrier: only contents/lockscreen, falls back to
#                                             org.kde.plasma.desktop for everything else)
#
# Why a Shell package: since Plasma 6 kscreenlocker_greet loads lockscreen/LockScreen.qml from
# the *shell* package named by plasmashellrc [Shell] ShellPackage, else $PLASMA_DEFAULT_SHELL,
# else org.kde.plasma.desktop. Look-and-Feel packages no longer provide the lock screen.
# plasmashell reads the same key and names its layout file after it
# (plasma-<shell>-appletsrc), so changing the key would "reset" the panels. Instead we set
# PLASMA_DEFAULT_SHELL only in kwin_wayland's environment (systemd drop-in): kwin spawns the
# greeter with its own environment, plasmashell never sees the variable.
# Takes effect after the next login (kwin is not restarted by this script).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LNF="$HERE/org.nothing.desktop"
SHELLPKG="$ROOT/plasma/shells/org.nothing.desktop"
KIT="$ROOT/plasma/plasmoids/shared"
ID="org.nothing.desktop"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nothingos"
STATE="$STATE_DIR/lookandfeel.prev"
DROPIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/plasma-kwin_wayland.service.d"
DROPIN="$DROPIN_DIR/nothing-lockscreen.conf"

MODE=install; ACTIVATE=1
for a in "$@"; do
    case "$a" in
        --sync) MODE=sync ;;
        --no-activate) ACTIVATE=0 ;;
        --revert) MODE=revert ;;
        -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
        *) echo "unknown option $a" >&2; exit 2 ;;
    esac
done

kread()  { kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null || true; }
kwrite() { if [ -n "$4" ]; then kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; else kwriteconfig6 --file "$1" --group "$2" --key "$3" --delete; fi; }

if [ "$MODE" = revert ]; then
    if [ -f "$STATE" ]; then
        # shellcheck disable=SC1090
        . "$STATE"
        kwrite ksplashrc KSplash Theme "${PREV_SPLASH_THEME:-}"
        kwrite ksplashrc KSplash Engine "${PREV_SPLASH_ENGINE:-}"
        echo "splash   -> restored '${PREV_SPLASH_THEME:-<default>}' (${PREV_SPLASH_ENGINE:-<default>})"
        rm -f "$STATE"
    else
        kwrite ksplashrc KSplash Theme ""
        echo "splash   -> no saved state; reset to Plasma default"
    fi
    if [ -f "$DROPIN" ]; then
        rm -f "$DROPIN"; rmdir "$DROPIN_DIR" 2>/dev/null || true
        systemctl --user daemon-reload
        echo "lock     -> override removed (Breeze lock screen after next login)"
    fi
    echo "packages are left installed; remove with:"
    echo "  kpackagetool6 -t Plasma/LookAndFeel -r $ID; kpackagetool6 -t Plasma/Shell -r $ID"
    exit 0
fi

# 1. Shared UI kit -> lockscreen/nothing (fresh copy, gitignored)
kit="$LNF/contents/lockscreen/nothing"
rm -rf "$kit"; mkdir -p "$kit"; cp -r "$KIT"/. "$kit"/
echo "kit      -> lockscreen/nothing"

# 2. Lock screen -> shell carrier package (fresh copy, gitignored)
rm -rf "$SHELLPKG/contents"; mkdir -p "$SHELLPKG/contents"
cp -r "$LNF/contents/lockscreen" "$SHELLPKG/contents/lockscreen"
echo "lock     -> plasma/shells/$ID/contents/lockscreen"

[ "$MODE" = sync ] && exit 0

# 3. Install / update both packages for this user
install_pkg() {  # type dir
    # note: --show exits 0 and prints a fallback package when $ID is missing, so match the id
    if kpackagetool6 -t "$1" --show "$ID" 2>/dev/null | grep -qE "Plugin +: $ID\$"; then
        kpackagetool6 -t "$1" -u "$2" >/dev/null || { echo "FAIL update $1 $ID" >&2; return 1; }
        echo "upd      $1 $ID"
    else
        kpackagetool6 -t "$1" -i "$2" >/dev/null || { echo "FAIL install $1 $ID" >&2; return 1; }
        echo "inst     $1 $ID"
    fi
}
install_pkg Plasma/LookAndFeel "$LNF"
install_pkg Plasma/Shell "$SHELLPKG"

[ "$ACTIVATE" = 1 ] || exit 0

# 4. Splash: remember the previous choice once, then select ours
mkdir -p "$STATE_DIR"
if [ ! -f "$STATE" ]; then
    {
        printf 'PREV_SPLASH_THEME=%q\n' "$(kread ksplashrc KSplash Theme)"
        printf 'PREV_SPLASH_ENGINE=%q\n' "$(kread ksplashrc KSplash Engine)"
    } > "$STATE"
fi
kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
kwriteconfig6 --file ksplashrc --group KSplash --key Theme "$ID"
echo "splash   -> $ID"

# 5. Lock screen: PLASMA_DEFAULT_SHELL for kwin_wayland (and so the greeter) only
mkdir -p "$DROPIN_DIR"
cat > "$DROPIN" <<EOF
# Installed by NothingOS plasma/lookandfeel/install.sh — selects the Nothing lock screen.
# kscreenlocker_greet inherits kwin's environment; plasmashell is unaffected.
# Remove this file (or run install.sh --revert) to get the Breeze lock screen back.
[Service]
Environment=PLASMA_DEFAULT_SHELL=$ID
EOF
systemctl --user daemon-reload
echo "lock     -> $DROPIN (active after next login)"

shellpkg="$(kread plasmashellrc Shell ShellPackage)"
if [ -n "$shellpkg" ]; then
    echo "WARNING: plasmashellrc [Shell] ShellPackage=$shellpkg overrides PLASMA_DEFAULT_SHELL;"
    echo "         the greeter will keep using that shell's lock screen."
fi
if ! systemctl --user is-active -q plasma-kwin_wayland.service; then
    echo "WARNING: kwin is not running as plasma-kwin_wayland.service (non-systemd session?);"
    echo "         the drop-in has no effect there."
fi
