import 'dart:async';
import 'dart:io';

import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';

Future<void> main(List<String> args) async {
  void log(String message) => stdout.writeln('[showcase] $message');

  var protocol = AppIndicatorProtocol.gtk;
  if (args.isNotEmpty) {
    try {
      protocol =
          AppIndicatorProtocol.values.firstWhere((e) => e.name == args[0]);
      log('Using protocol: ${protocol.name}');
    } catch (e) {
      log('Unknown protocol: ${args[0]}. Using default: ${protocol.name}');
      log('Available protocols: ${AppIndicatorProtocol.values.map((e) => e.name).join(', ')}');
    }
  }

  final indicator = AppIndicator(
    id: 'example-feature-showcase',
    iconName: 'example/assets/demo-indicator.png',
    category: AppIndicatorCategory.applicationStatus,
    protocol: protocol,
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
    DBusMenuItem.label('Item 1',
        onActivated: () => log('Menu item 1 clicked.')),
    DBusMenuItem.label('Item 2',
        onActivated: () => log('Menu item 2 clicked.')),
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
  indicator.activateEvents
      .listen((event) => log('Primary activation @(${event.x}, ${event.y})'));
  indicator.secondaryActivateEvents
      .listen((event) => log('Secondary activation @(${event.x}, ${event.y})'));
  indicator.contextMenuEvents
      .listen((event) => log('Context menu @(${event.x}, ${event.y})'));
  indicator.scrollEvents.listen((event) {
    log('Scroll event: delta=${event.delta}, orientation=${event.orientation}');
    percentage = (percentage + event.delta).clamp(0, 100);
    updateLabel();
  });

  await indicator.connect();
  log('Connected to D-Bus and registered with watcher.');

  if (!indicator.isWatcherAvailable &&
      (protocol == AppIndicatorProtocol.gtk ||
          protocol == AppIndicatorProtocol.statusNotifier)) {
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
