# dart_libayatana_appindicator

A pure Dart implementation of the Ayatana AppIndicator specification, built on top of D-Bus. This package allows you to create system tray icons and menus on Linux without using C bindings or FFI.

## Features

- **Pure Dart**: No native dependencies, uses `dbus` package.
- **StatusNotifierItem**: Implements the SNI spec.
- **Menus**: specific menu support via `com.canonical.dbusmenu`.
- **Events**: Handle clicks, scrolls, and other interactions.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dart_libayatana_appindicator: ^0.1.5
```

## Usage

### Basic Usage

```dart
import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';

Future<void> main() async {
  // Create the indicator
  final indicator = AppIndicator(
    id: 'my-app-indicator',
    iconName: 'system-file-manager', // Use a system icon name or path
    category: AppIndicatorCategory.applicationStatus,
  );

  // Set properties
  indicator.status = AppIndicatorStatus.active;
  indicator.title = 'My Indicator';
  indicator.label = 'Ready';

  // Connect to the session bus
  await indicator.connect();
}
```

### Adding a Menu

You can attach a menu to the indicator. **Important**: Ensure each `DBusMenuItem` has a unique `id`.

```dart
import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';

// ... inside main ...

  indicator.setMenu([
    DBusMenuItem.label(
      'Status: Active',
      id: 1, // Unique ID
      onActivated: () => print('Status clicked'),
    ),
    DBusMenuItem.label(
      'Quit',
      id: 2, // Unique ID
      onActivated: () async {
        await indicator.close();
        // Exit the app
      },
    ),
  ]);
```

### Handling Events

```dart
  indicator.activateEvents.listen((event) {
    print('Primary click at ${event.x}, ${event.y}');
  });

  indicator.secondaryActivateEvents.listen((event) {
    print('Secondary click at ${event.x}, ${event.y}');
  });

  indicator.scrollEvents.listen((event) {
    print('Scrolled ${event.orientation} by ${event.delta}');
  });
```

### Flutter Example

To use this in a Flutter Linux application, initialize the indicator in your `main()` function.

```dart
import 'package:flutter/material.dart';
import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';

void main() async {
  // Ensure Flutter bindings are initialized if needed before other setup
  WidgetsFlutterBinding.ensureInitialized();

  final indicator = AppIndicator(
    id: 'flutter-example',
    iconName: 'flutter-logo',
    category: AppIndicatorCategory.applicationStatus,
  );

  indicator.status = AppIndicatorStatus.active;

  indicator.setMenu([
    DBusMenuItem.label('Show App', id: 1, onActivated: () {
      print('Show App clicked');
      // Logic to bring app to front
    }),
    DBusMenuItem.label('Quit', id: 2, onActivated: () {
      indicator.close();
      // Logic to exit app
    }),
  ]);

  await indicator.connect();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AppIndicator Example')),
        body: const Center(child: Text('Check the system tray!')),
      ),
    );
  }
}
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

## Development

```bash
dart pub get
dart analyze
dart format --output=show --set-exit-if-changed .
dbus-run-session -- dart test
```

## License

GNU General Public License version 3 (GPL-3.0). See `COPYING`.
