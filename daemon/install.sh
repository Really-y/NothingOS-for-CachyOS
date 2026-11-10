#!/usr/bin/env bash
# Build and install nothingd as a DBus-activated systemd user service (no sudo).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="$HOME/.local/bin"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
dbus_dir="${XDG_DATA_HOME:-$HOME/.local/share}/dbus-1/services"

echo ":: building nothingd"
(cd "$here" && cargo build --release)

mkdir -p "$bin_dir" "$unit_dir" "$dbus_dir"
# Install atomically so a running instance's binary is not overwritten in place.
install -m 0755 "$here/target/release/nothingd" "$bin_dir/nothingd.new"
mv -f "$bin_dir/nothingd.new" "$bin_dir/nothingd"
echo ":: installed $bin_dir/nothingd"

cat > "$unit_dir/nothingd.service" <<UNIT
[Unit]
Description=NothingOS data daemon (org.nothing.Daemon)
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=dbus
BusName=org.nothing.Daemon
ExecStart=%h/.local/bin/nothingd
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical-session.target
UNIT
echo ":: wrote $unit_dir/nothingd.service"

cat > "$dbus_dir/org.nothing.Daemon.service" <<SVC
[D-BUS Service]
Name=org.nothing.Daemon
Exec=$bin_dir/nothingd
SystemdService=nothingd.service
SVC
echo ":: wrote $dbus_dir/org.nothing.Daemon.service"

systemctl --user daemon-reload
systemctl --user enable --now nothingd
# Pick up a new binary if the service was already running.
systemctl --user restart nothingd
systemctl --user --no-pager --lines=5 status nothingd || true
