# NothingOS for CachyOS — architecture

Goal: KDE Plasma 6.7 (Wayland) that looks and feels like Nothing OS, built
**into** Plasma (real panels, real plasmoids, native notifications), with a
small Rust daemon for data. No separate shell process.

## Design language (must follow)
- Pure black `#000000` background; surfaces `#111111` / `#1c1c1c` / `#262626`; hairline `#2a2a2a`.
- Text white `#ffffff`, secondary `#8e8e8e`, tertiary `#5e5e5e`. ONE accent: Nothing red `#d71921`,
  used sparingly (live indicators, warnings, the "now" dot) — never as a large fill.
- Active toggles = white surface + black glyph. Inactive = `#1c1c1c` + white glyph.
- Type: **Doto** (dot-matrix, `font.variableAxes: {"ROND":100,"wght":800}`) for big numbers/time;
  **Inter** for UI text (Nothing OS system font); **Space Mono** UPPERCASE letter-spaced for small labels.
- Icons: **Material Symbols Rounded** ligatures, thin weight (300), `Icon { name: "wifi" }`.
- Shapes: cards radius 30, tiles radius 24, pills fully round. Generous padding. Flat, no gradients, no blur, no drop shadows on cards.
- Motif: dots (dot rings as gauges, dot rows as progress, dot grids).
- Motion: entries `Easing.BezierSpline` [0.05,0.7,0.1,1] ~260–420 ms; exits [0.3,0,0.8,0.15] ~140 ms; press = spring scale 0.94.

## Shared UI kit
`plasma/plasmoids/shared/` (QML, no Plasma deps, has `qmldir` with singleton `Theme`):
Theme, Icon, Label, Pressable, Tile, NSlider, DotRing, Card, DotString, DotTime, DotGlyph, ArtCanvas
(dot type: DotString `pitch` in house steps 5/8/12/15 via `Theme.dotPitch()`, dots 0.65 × pitch).
Every plasmoid gets a copy at `contents/ui/nothing/` at install time
(`scripts/build-plasmoids.sh`) and uses `import "nothing"`.

Visual parts of each plasmoid live in plain QML files taking properties (no `Plasmoid`
dependency) so they can be rendered offscreen: `tools/render.sh previews/X.qml out.png W H`.

## Rust daemon `nothingd` (crate in `daemon/`)
Session DBus: service `org.nothing.Daemon`, path `/org/nothing/Daemon`, interface `org.nothing.Daemon1`.
All data methods return a JSON **string** (easy `JSON.parse` in QML):
- `Stats() -> s`   `{"cpu":0.23,"mem":0.41,"memUsedGb":6.5,"memTotalGb":15.6,"tempC":48.0|null,"uptimeS":12345}`
- `Weather() -> s` `{"ok":true,"temp":14,"hi":17,"lo":9,"code":3,"icon":"cloud","desc":"Cloudy","city":"BAKU","updated":1731300000}`
  (Open-Meteo, cached 15 min; config `~/.config/nothingos/config.toml` `[weather] lat lon city`, default Baku 40.4093/49.8671)
- `Network() -> s` `{"wifiEnabled":true,"kind":"wifi|ethernet|none","name":"Home","signal":72}`
- `SetWifi(b) -> b`
- `PlaySound(s event)` plays `~/.local/share/sounds/nothing/stereo/<event>.oga` with `pw-play`
- signal `Changed(s topic)` when stats/weather/network change.
Activation: systemd user unit `nothingd.service` + DBus service file (SystemdService=nothingd.service).

QML call pattern:
```qml
import org.kde.plasma.workspace.dbus as DBus
DBus.SessionBus.asyncCall({service: "org.nothing.Daemon", path: "/org/nothing/Daemon",
    iface: "org.nothing.Daemon1", member: "Stats", arguments: []},
    reply => { const d = JSON.parse(reply.value) }, err => {})
```
(verify exact reply shape against /usr/lib/qt6/qml/org/kde/plasma/workspace/dbus/dbusplugin.qmltypes)

## Plasmoids (ids `org.nothing.*`, in `plasma/plasmoids/<id>/`)
Desktop: `clock`, `weather`, `system`, `media`. Panel: `clock` (compact), `controlcenter`, `drawer`.

## Layout
Top panel (36px, black, full width): drawer · spacer · clock · spacer · systemtray · controlcenter.
Bottom: floating dock with task icons only. Notifications = Plasma native, themed.
