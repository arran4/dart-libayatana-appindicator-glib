import 'package:dart_libayatana_appindicator/src/dbus_menu.dart';
import 'package:dbus/dbus.dart';

void main() async {
  print('Building menu items...');
  List<DBusMenuItem> buildItems(int depth, int countPerLevel, int idPrefix) {
    if (depth == 0) return [];
    final items = <DBusMenuItem>[];
    for (int i = 0; i < countPerLevel; i++) {
      int id = idPrefix * 100 + i + 1;
      final children = buildItems(depth - 1, countPerLevel, id);
      items.add(DBusMenuItem(
        id: id,
        properties: {'label': DBusString('Item $id')},
        children: children,
        onActivated: () {},
      ));
    }
    return items;
  }

  // 4 levels deep, 10 items per level = 10 + 100 + 1000 + 10000 = 11110 items
  final rootItems = buildItems(4, 10, 1);
  final menu = DBusMenu(DBusObjectPath('/com/canonical/dbusmenu'), rootItems);

  print('Warming up...');
  // The deepest item ID would be something like 1010101
  // Let's just find the last item in a deep list.
  int realId = rootItems.last.children.last.children.last.children.last.id;
  print('Target ID: $realId');

  for (int i = 0; i < 1000; i++) {
    await menu.handleMethodCall(DBusMethodCall(
        sender: 'sender',
        interface: 'com.canonical.dbusmenu',
        name: 'Event',
        values: [
          DBusInt32(realId),
          DBusString('clicked'),
          DBusVariant(DBusString('')),
          DBusUint32(0)
        ]));
  }

  print('Benchmarking...');
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    await menu.handleMethodCall(DBusMethodCall(
        sender: 'sender',
        interface: 'com.canonical.dbusmenu',
        name: 'Event',
        values: [
          DBusInt32(realId),
          DBusString('clicked'),
          DBusVariant(DBusString('')),
          DBusUint32(0)
        ]));
  }
  stopwatch.stop();

  print('Time taken: ${stopwatch.elapsedMilliseconds} ms');
}
