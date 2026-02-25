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

  test('DBusMenu handles org.gtk.Menus.Start with invalid arguments', () async {
    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), []);

    // Call Start with signature 's' (string) instead of 'au' (array of uint32)
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Menus',
      name: 'Start',
      values: [DBusString('invalid')],
    );

    var response = await menu.handleMethodCall(call);
    expect(response, isA<DBusMethodErrorResponse>());
    expect(response.toString(), contains('InvalidArgs'));
  });

  test('DBusMenu handles org.gtk.Menus.End with invalid arguments', () async {
    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), []);

    // Call End with signature 's' (string) instead of 'au' (array of uint32)
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Menus',
      name: 'End',
      values: [DBusString('invalid')],
    );

    var response = await menu.handleMethodCall(call);
    expect(response, isA<DBusMethodErrorResponse>());
    expect(response.toString(), contains('InvalidArgs'));
  });

  test('DBusMenu handles org.gtk.Menus.Start with valid arguments', () async {
    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), []);

    // Call Start with signature 'au'
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Menus',
      name: 'Start',
      values: [DBusArray(DBusSignature('u'), [])],
    );

    var response = await menu.handleMethodCall(call);
    expect(response, isA<DBusMethodSuccessResponse>());
  });

  test('DBusMenu handles org.gtk.Menus.End with valid arguments', () async {
    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), []);

    // Call End with signature 'au'
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Menus',
      name: 'End',
      values: [DBusArray(DBusSignature('u'), [])],
    );

    var response = await menu.handleMethodCall(call);
    expect(response, isA<DBusMethodSuccessResponse>());
  });
}
