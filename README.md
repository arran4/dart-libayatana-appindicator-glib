# Ayatana Application Indicator (Dart Port)

A complete Dart port of [libayatana-appindicator](https://github.com/AyatanaIndicators/libayatana-appindicator).

This library allows applications to export a menu into an Application Indicators aware menu bar, implementing the StatusNotifierItem Specification (SNI). It uses DBus to communicate with the indicator service.

**Note:** This is a "hard port" from C to Dart. It does not bind to the C library but reimplements the protocol in pure Dart using the `dbus` package.

## Features

-   **Pure Dart**: No native dependencies (other than DBus availability).
-   **StatusNotifierItem**: Implements the full SNI specification.
-   **Menus**: Exports menus via `org.gtk.Menus`.
-   **Actions**: Exports actions via `org.gtk.Actions`.
-   **Cross-platform**: Works on Linux environments with DBus (e.g., KDE Plasma, GNOME with AppIndicator support, XFCE, MATE).

## Usage

Add `ayatana_appindicator` to your `pubspec.yaml`:

```yaml
dependencies:
  ayatana_appindicator:
    path: . # or git url
```

### Example

```dart
import 'package:ayatana_appindicator/ayatana_appindicator.dart';
import 'package:dbus/dbus.dart';

Future<void> main() async {
  var indicator = AppIndicator(
    id: 'my-indicator',
    iconName: 'indicator-messages',
  );

  indicator.status = AppIndicatorStatus.active;
  indicator.title = 'My Indicator';

  // Add actions
  var actions = [
    DBusAction('quit', onActivate: (_) => indicator.close()),
  ];
  indicator.setActions(actions);

  // Add menu
  var menu = [
    DBusMenuItem({'label': DBusString('Quit'), 'action': DBusString('app.quit')}, {}),
  ];
  indicator.setMenu(menu);

  await indicator.connect();
}
```

See `example/simple_client.dart` for a complete example.

## Building and Testing

To run the tests:

```bash
dart test
```

To run the example (requires a session bus):

```bash
dart run example/simple_client.dart
```

## License

GNU General Public License version 3 (GPL-3.0). See `COPYING` for details.

## Authors

Original library by Canonical Ltd. and Robert Tari.
Dart port by [Your Name/Entity].
