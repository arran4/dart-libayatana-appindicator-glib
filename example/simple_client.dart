import 'dart:async';
import 'dart:io';

import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';

Future<void> main() async {
  void log(String message) => stdout.writeln('[showcase] $message');

  final indicator = AppIndicator(
    id: 'example-feature-showcase',
    iconName: 'example/assets/demo-indicator.png',
    category: AppIndicatorCategory.applicationStatus,
  );

  log('Indicator created with ID: ${indicator.id}');
  log('Primary Icon: ${indicator.iconName}');

  indicator
    ..status = AppIndicatorStatus.active
    ..title = 'Ayatana AppIndicator Dart Showcase'
    ..label = '1%'
    ..labelGuide = '100%'
    ..tooltipTitle = 'Pure Dart AppIndicator'
    ..tooltipDescription =
        'Left click, middle click, right click, double click and scroll.'
    ..iconThemePath = Platform.script.resolve('assets').toFilePath();

  log('Icon Theme Path: ${indicator.iconThemePath}');

  var percentage = 1;
  var showLabel = true;
  var attentionActive = false;

  void updateLabel() {
    indicator.label = showLabel ? '$percentage%' : '';
  }

  // Set up the menu
  indicator.setMenu([
    DBusMenuItem.label('Item 1', onActivated: () => log('Menu item 1 clicked.')),
    DBusMenuItem.label('Item 2', onActivated: () => log('Menu item 2 clicked.')),
    DBusMenuItem.label('Toggle Attention', onActivated: () {
      attentionActive = !attentionActive;
      indicator.status = attentionActive
          ? AppIndicatorStatus.attention
          : AppIndicatorStatus.active;
      log('Attention mode: $attentionActive');
    }),
    DBusMenuItem.label('Toggle Label', onActivated: () {
      showLabel = !showLabel;
      updateLabel();
      log('Show label: $showLabel');
    }),
    DBusMenuItem.label('Quit', onActivated: () async {
      log('Quit clicked, closing...');
      await indicator.close();
      exit(0);
    }),
  ]);

  // Set up event callbacks (Simplified API)
  indicator.onActivate = (x, y) => log('Primary activation @($x, $y)');
  indicator.onSecondaryActivate = (x, y) => log('Secondary activation @($x, $y)');
  indicator.onContextMenu = (x, y) => log('Context menu @($x, $y)');
  indicator.onScroll = (delta, orientation) {
    log('Scroll event: delta=$delta, orientation=$orientation');
    percentage = (percentage + delta).clamp(0, 100);
    updateLabel();
  };

  await indicator.connect();
  log('Connected to D-Bus and registered with watcher.');

  if (!indicator.isWatcherAvailable) {
    log('No StatusNotifierWatcher is available on session bus.');
  }

  final heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
    percentage = (percentage + 1) % 101;
    updateLabel();
  });

  ProcessSignal.sigint.watch().listen((_) async {
    log('SIGINT received, stopping showcase...');
    heartbeat.cancel();
    await indicator.close();
    exit(0);
  });

  await Completer<void>().future;
}
