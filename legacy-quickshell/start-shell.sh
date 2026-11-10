#!/usr/bin/env bash
# Start the Nothing shell once (also used for DBus activation of notifications).
SHELL_DIR="$HOME/.local/share/nothingos/shell"
pgrep -f "qs -p $SHELL_DIR" >/dev/null && exit 0
exec qs -p "$SHELL_DIR" >"$HOME/.local/share/nothingos/shell.log" 2>&1
