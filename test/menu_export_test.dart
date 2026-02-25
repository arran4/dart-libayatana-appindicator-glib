@TestOn('linux')
import 'package:dart_libayatana_appindicator/src/dbus_menu.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  test('DBusMenu basic export', () async {
    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), []);

    menu.updateItems([
      DBusMenuItem(id: 1, properties: {'label': DBusString('Item 1')}),
      DBusMenuItem(id: 2, properties: {
        'label': DBusString('Item 2')
      }, children: [
        DBusMenuItem(id: 3, properties: {'label': DBusString('Sub Item 1')}),
      ]),
    ]);

    expect(menu.items.length, 2);
    expect(menu.items[1].children.length, 1);
  });
}
