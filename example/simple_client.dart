import 'dart:async';
import 'dart:io';

import 'package:ayatana_appindicator/ayatana_appindicator.dart';
import 'package:dbus/dbus.dart';

Future<void> main() async {
  final indicator = AppIndicator(
    id: 'example-feature-showcase',
    iconName: 'demo-indicator',
    category: AppIndicatorCategory.applicationStatus,
  );

  indicator
    ..status = AppIndicatorStatus.active
    ..title = 'Ayatana AppIndicator Dart Showcase'
    ..label = '0%'
    ..labelGuide = '100%'
    ..tooltipTitle = 'Dart-native AppIndicator'
    ..tooltipDescription = 'Left click, middle click, right click and scroll to interact.'
    ..iconThemePath = Platform.script.resolve('assets').toFilePath();

  var percentage = 0;
  var showLabel = true;
  var blink = false;
  var lastPrimaryClick = DateTime.fromMillisecondsSinceEpoch(0);

  late Timer heartbeat;

  void log(String message) {
    stdout.writeln('[showcase] $message');
  }

  final actions = <DBusAction>[
    DBusAction(
      'primary_toggle_attention',
      onActivate: (_) {
        blink = !blink;
        indicator.status = blink
            ? AppIndicatorStatus.attention
            : AppIndicatorStatus.active;
        log('Primary click toggled attention mode: $blink');
      },
    ),
    DBusAction(
      'secondary_toggle_label',
      onActivate: (_) {
        showLabel = !showLabel;
        indicator.label = showLabel ? '$percentage%' : '';
        log('Secondary click toggled label visibility: $showLabel');
      },
    ),
    DBusAction(
      'double_click_reset_progress',
      onActivate: (_) {
        percentage = 0;
        indicator.label = showLabel ? '$percentage%' : '';
        indicator.tooltipDescription = 'Progress reset via double-click.';
        log('Double click reset progress to 0%.');
      },
    ),
    DBusAction(
      'toggle_status',
      onActivate: (_) {
        indicator.status = indicator.status == AppIndicatorStatus.passive
            ? AppIndicatorStatus.active
            : AppIndicatorStatus.passive;
      },
    ),
    DBusAction('quit', onActivate: (_) async {
      log('Quit requested. Closing indicator...');
      heartbeat.cancel();
      await indicator.close();
      exit(0);
    }),
  ];

  indicator.setActions(actions);
  indicator
    ..setPrimaryActivateTarget('primary_toggle_attention')
    ..setSecondaryActivateTarget('secondary_toggle_label')
    ..setDoubleClickTarget('double_click_reset_progress');

  final submenuId = indicator.addSubMenu([
    DBusMenuItem({'label': DBusString('Sub Action A')}, {}),
    DBusMenuItem({'label': DBusString('Sub Action B')}, {}),
  ]);

  indicator.setMenu([
    DBusMenuItem({'label': DBusString('Toggle Passive/Active'), 'action': DBusString('app.toggle_status')}, {}),
    DBusMenuItem({'label': DBusString('Reset via Double Click'), 'action': DBusString('app.double_click_reset_progress')}, {}),
    DBusMenuItem({'label': DBusString('Submenu')}, {'submenu': DBusUint32(submenuId)}),
    DBusMenuItem({'label': DBusString('Quit'), 'action': DBusString('app.quit')}, {}),
  ]);

  indicator.activateEvents.listen((event) {
    final now = DateTime.now();
    final elapsed = now.difference(lastPrimaryClick).inMilliseconds;
    lastPrimaryClick = now;
    log('Primary activation at (${event.x}, ${event.y}), delta=${elapsed}ms');
  });

  indicator.secondaryActivateEvents.listen((event) {
    log('Secondary activation at (${event.x}, ${event.y}) timestamp=${event.timestamp}');
  });

  indicator.contextMenuEvents.listen((event) {
    log('Context menu requested at (${event.x}, ${event.y})');
  });

  indicator.scrollEvents.listen((event) {
    percentage = (percentage + event.delta).clamp(0, 100);
    indicator.label = showLabel ? '$percentage%' : '';
    indicator.tooltipDescription =
        'Progress adjusted by scroll (${event.orientation}): $percentage%';
    log('Scroll event delta=${event.delta}, orientation=${event.orientation}, progress=$percentage');
  });

  await indicator.connect();

  if (!indicator.isWatcherAvailable) {
    print('Indicator exported on D-Bus, but no StatusNotifierWatcher is available.');
    print('No icon will be shown until an indicator host/watcher is running.');
  } else if (!await indicator.isStatusNotifierHostRegistered()) {
    print('Indicator registered with watcher, but no StatusNotifierHost is registered.');
    print('Ensure your desktop environment has an AppIndicator/SNI host enabled.');
  }

  log('Indicator connected. Use Ctrl+C to exit.');

  heartbeat = Timer.periodic(const Duration(seconds: 2), (_) {
    percentage = (percentage + 1) % 101;
    indicator.label = showLabel ? '$percentage%' : '';
  });

  await Completer<void>().future;
}
