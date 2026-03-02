# ayatana_appindicator

Pure Dart implementation of Ayatana AppIndicator built on top of D-Bus.

This package continues the migration away from C bindings and native glue by implementing the StatusNotifierItem/AppIndicator behavior directly in idiomatic Dart code.

## Goals

- ✅ Pure Dart runtime implementation (no FFI/native C bridge in this package).
- ✅ Minimal dependency surface (`dbus` only at runtime).
- ✅ StatusNotifier watcher probing for KDE/Freedesktop layouts.
- ✅ Rich interaction model: primary click, secondary click, context menu, scroll, and Ayatana-specific activation hooks.
- ✅ Action and menu exports via `org.gtk.Actions` and `org.gtk.Menus`.

## Installation

```yaml
dependencies:
  ayatana_appindicator:
    git:
      url: https://github.com/AyatanaIndicators/libayatana-appindicator
```

## Feature Highlights

- `AppIndicator` exports a fully functional SNI object on the session bus.
- Supports queued property signal emission before `connect()`.
- Offers typed event streams:
  - `activateEvents`
  - `secondaryActivateEvents`
  - `contextMenuEvents`
  - `xAyatanaActivateEvents`
  - `scrollEvents`
- Supports action targeting for:
  - primary click (`setPrimaryActivateTarget`)
  - secondary click (`setSecondaryActivateTarget`)
  - double click (`setDoubleClickTarget`)
- Registers a dedicated well-known D-Bus service name before watcher registration to improve host compatibility.
- Exposes `IconPixmap`/`AttentionIconPixmap`, `WindowId`, and `ItemIsMenu` properties for richer host support.
- Double-click behavior is configurable with `doubleClickWindow`.

## Example

A full showcase is available in `example/simple_client.dart` with:

- dynamic label updates and status transitions,
- menu + submenu composition that mirrors the historical C sample,
- mapped primary/secondary/double-click actions,
- icon source toggling and pixmap fallback support,
- scroll-driven progress adjustment,
- structured event logging and watcher diagnostics.

Run it with:

```bash
dart run example/simple_client.dart
```

## CI Quality Gates

CI validates:

- `dart pub get`
- `dart analyze`
- `dart format --output=show --set-exit-if-changed .`
- `dbus-run-session -- dart test`

When format checks fail, CI prints the format output and a `git diff` preview so changes can be copied/applied quickly.

## Development

```bash
dart pub get
dart analyze
dart format --output=show --set-exit-if-changed .
dbus-run-session -- dart test
```

## License

GNU General Public License version 3 (GPL-3.0). See `COPYING`.
