import 'dart:async';
import 'dart:io';
import 'package:ayatana_appindicator/ayatana_appindicator.dart';
import 'package:dbus/dbus.dart';

Future<void> main() async {
  var indicator = AppIndicator(
    id: 'example-simple-client',
    iconName: 'demo-indicator',
    category: AppIndicatorCategory.applicationStatus,
  );

  indicator.status = AppIndicatorStatus.active;

  final iconThemePath = Platform.script.resolve('assets').toFilePath();
  indicator.iconThemePath = iconThemePath;
  indicator.attentionIconName = 'demo-indicator';
  indicator.label = '1%';
  indicator.labelGuide = '100%';
  indicator.title = 'Test Indicator (Dart)';

  var percentage = 0;
  var hasLabel = true;

  Timer.periodic(const Duration(seconds: 1), (timer) {
    percentage = (percentage + 1) % 100;
    if (hasLabel) {
      indicator.label = '$percentage%';
    } else {
      indicator.label = '';
    }
  });

  // Actions
  var actions = <DBusAction>[];

  actions.add(DBusAction('check', state: DBusBoolean(false), onActivate: (param) {
      print('Check activated');
  }, onStateChange: (state) {
      print('Check state changed: $state');
  }));

  actions.add(DBusAction('toggle_label', onActivate: (_) {
      hasLabel = !hasLabel;
      print('Label toggled: $hasLabel');
  }));

  actions.add(DBusAction('quit', onActivate: (_) {
      print('Quit activated');
      indicator.close();
      // exit(0);
  }));

  indicator.setActions(actions);

  // Menu
  var menuItems = <DBusMenuItem>[];
  menuItems.add(DBusMenuItem({
      'label': DBusString('Check Item'),
      'action': DBusString('app.check')
  }, {}));

  menuItems.add(DBusMenuItem({
      'label': DBusString('Toggle Label'),
      'action': DBusString('app.toggle_label')
  }, {}));

  // Submenu
  var subItems = [
      DBusMenuItem({'label': DBusString('Sub Item 1')}, {}),
      DBusMenuItem({'label': DBusString('Sub Item 2')}, {})
  ];
  // addSubMenu returns the menu-model ID exported for this submenu.
  var subMenuId = indicator.addSubMenu(subItems);

  menuItems.add(DBusMenuItem({
      'label': DBusString('Submenu'),
  }, {
      // The submenu property links this menu item to the exported submenu ID.
      'submenu': DBusUint32(subMenuId)
  }));

  menuItems.add(DBusMenuItem({
      'label': DBusString('Quit'),
      'action': DBusString('app.quit')
  }, {}));

  indicator.setMenu(menuItems);

  await indicator.connect();
  print('Indicator connected. Press Ctrl+C to exit.');

  // Keep running
  await Completer().future;
}
