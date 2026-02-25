import 'dart:async';
import 'dart:io';

import 'package:ayatana_appindicator/ayatana_appindicator.dart';
import 'package:dbus/dbus.dart';

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
    ..windowId = 0
    ..tooltipTitle = 'Pure Dart AppIndicator'
    ..tooltipDescription =
        'Left click, middle click, right click, double click and scroll.'
    ..iconThemePath = Platform.script.resolve('assets').toFilePath();

  log('Icon Theme Path: ${indicator.iconThemePath}');

  var percentage = 1;
  var showLabel = true;
  var attentionActive = false;
  var item3Enabled = true;
  var localIconMode = true;
  var lastPrimaryClick = DateTime.fromMillisecondsSinceEpoch(0);

  late Timer heartbeat;
  late int submenuId;

  void updateLabel() {
    indicator.label = showLabel ? '$percentage%' : '';
  }

  final actions = <DBusAction>[
    DBusAction(
      'item_1',
      onActivate: (_) => log('Menu item 1 clicked.'),
    ),
    DBusAction(
      'item_2',
      onActivate: (_) => log('Menu item 2 clicked.'),
    ),
    DBusAction(
      'toggle_item_3',
      onActivate: (_) {
        item3Enabled = !item3Enabled;
        indicator.setMenuGroup(submenuId, [
          DBusMenuItem(
            {
              'label': DBusString('Sub 2 (toggles Sub 1 sensitivity)'),
              'action': DBusString('app.toggle_sub_1'),
            },
            {},
          ),
          DBusMenuItem(
            {
              'label': DBusString(
                  item3Enabled ? 'Sub 1 (enabled)' : 'Sub 1 (disabled)'),
              'action': DBusString('app.sub_1'),
              'enabled': DBusBoolean(item3Enabled),
            },
            {},
          ),
          DBusMenuItem(
            {
              'label': DBusString('Sub 3'),
              'action': DBusString('app.sub_3'),
            },
            {},
          ),
        ]);
      },
    ),
    DBusAction(
      'sub_1',
      onActivate: (_) => log('Sub 1 clicked.'),
    ),
    DBusAction(
      'toggle_sub_1',
      onActivate: (_) =>
          log('Sub 2 clicked. Sub 1 enable state toggled from parent action.'),
    ),
    DBusAction(
      'sub_3',
      onActivate: (_) => log('Sub 3 clicked.'),
    ),
    DBusAction(
      'toggle_attention',
      onActivate: (_) {
        attentionActive = !attentionActive;
        indicator.status = attentionActive
            ? AppIndicatorStatus.attention
            : AppIndicatorStatus.active;
        indicator.tooltipDescription = attentionActive
            ? 'Attention mode enabled.'
            : 'Attention mode disabled.';
      },
    ),
    DBusAction(
      'toggle_label',
      onActivate: (_) {
        showLabel = !showLabel;
        updateLabel();
      },
    ),
    DBusAction(
      'toggle_icon_source',
      onActivate: (_) {
        localIconMode = !localIconMode;
        indicator.iconName =
            localIconMode ? 'demo-indicator' : 'indicator-messages';
        indicator.tooltipDescription = localIconMode
            ? 'Using bundled local icon.'
            : 'Using system theme icon.';
      },
    ),
    DBusAction(
      'double_click_reset_progress',
      onActivate: (_) {
        percentage = 0;
        updateLabel();
        indicator.tooltipDescription = 'Progress reset via double-click.';
      },
    ),
    DBusAction(
      'primary_toggle_attention',
      onActivate: (_) {
        attentionActive = !attentionActive;
        indicator.status = attentionActive
            ? AppIndicatorStatus.attention
            : AppIndicatorStatus.active;
      },
    ),
    DBusAction(
      'secondary_toggle_label',
      onActivate: (_) {
        showLabel = !showLabel;
        updateLabel();
      },
    ),
    DBusAction('quit', onActivate: (_) async {
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

  submenuId = indicator.addSubMenu([
    DBusMenuItem(
      {
        'label': DBusString('Sub 1 (enabled)'),
        'action': DBusString('app.sub_1'),
        'enabled': DBusBoolean(true),
      },
      {},
    ),
    DBusMenuItem(
      {
        'label': DBusString('Sub 2 (toggles Sub 1 sensitivity)'),
        'action': DBusString('app.toggle_sub_1'),
      },
      {},
    ),
    DBusMenuItem(
      {
        'label': DBusString('Sub 3'),
        'action': DBusString('app.sub_3'),
      },
      {},
    ),
  ]);

  indicator.setMenu([
    DBusMenuItem(
        {'label': DBusString('Item 1'), 'action': DBusString('app.item_1')},
        {}),
    DBusMenuItem(
        {'label': DBusString('Item 2'), 'action': DBusString('app.item_2')},
        {}),
    DBusMenuItem(
        {'label': DBusString('Submenu')}, {'submenu': DBusUint32(submenuId)}),
    DBusMenuItem({
      'label': DBusString('Toggle Attention'),
      'action': DBusString('app.toggle_attention')
    }, {}),
    DBusMenuItem({
      'label': DBusString('Toggle Label'),
      'action': DBusString('app.toggle_label')
    }, {}),
    DBusMenuItem({
      'label': DBusString('Toggle Submenu Item State'),
      'action': DBusString('app.toggle_item_3')
    }, {}),
    DBusMenuItem({
      'label': DBusString('Toggle Icon Source'),
      'action': DBusString('app.toggle_icon_source')
    }, {}),
    DBusMenuItem(
        {'label': DBusString('Quit'), 'action': DBusString('app.quit')}, {}),
  ]);

  indicator.activateEvents.listen((event) {
    final now = DateTime.now();
    final elapsed = now.difference(lastPrimaryClick).inMilliseconds;
    lastPrimaryClick = now;
    log('Primary activation @(${event.x}, ${event.y}) delta=${elapsed}ms');
  });

  indicator.secondaryActivateEvents.listen((event) {
    log('Secondary activation @(${event.x}, ${event.y}) ts=${event.timestamp}');
  });

  indicator.contextMenuEvents.listen((event) {
    log('Context menu @(${event.x}, ${event.y})');
  });

  indicator.scrollEvents.listen((event) {
    percentage = (percentage + event.delta).clamp(0, 100);
    updateLabel();
  });

  await indicator.connect();
  log('Connected to D-Bus and registered with watcher.');

  if (!indicator.isWatcherAvailable) {
    log('No StatusNotifierWatcher is available on session bus.');
  } else if (!await indicator.isStatusNotifierHostRegistered()) {
    log('Watcher found but no StatusNotifierHost registered.');
  }

  heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
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
