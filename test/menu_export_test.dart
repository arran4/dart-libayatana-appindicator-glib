import 'package:test/test.dart';
import 'package:dbus/dbus.dart';
import 'package:ayatana_appindicator/src/menu.dart';

void main() {
  test('DBusMenu exports menu structure correctly', () async {
    var menu = DBusMenu(DBusObjectPath('/test'));

    var items = [
      DBusMenuItem({'label': DBusString('Item 1')}, {}),
      DBusMenuItem(
          {'label': DBusString('Item 2'), 'action': DBusString('app.quit')}, {})
    ];

    var id = menu.addMenu(items);

    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Menus',
      name: 'Start',
      values: [
        DBusArray(DBusSignature('u'), [DBusUint32(0)])
      ],
    );

    var response = await menu.handleMethodCall(call);

    if (response is DBusMethodErrorResponse) {
      var msg = response.values.isNotEmpty
          ? response.values.first.asString()
          : 'No message';
      fail('Method call failed: ${response.errorName} - $msg');
    }

    expect(response, isA<DBusMethodSuccessResponse>());

    var success = response as DBusMethodSuccessResponse;
    var result = success.returnValues[0];

    // Check structure: a(uua(a{sv}a{sv}))
    expect(result, isA<DBusArray>());
    var array = result as DBusArray;
    expect(array.children.length, 1);

    var group = array.children[0] as DBusStruct;
    expect(group.children[0], DBusUint32(0)); // sub id
    expect(group.children[1], DBusUint32(id)); // menu id

    var menuItems = group.children[2] as DBusArray;
    expect(menuItems.children.length, 2);

    var item1 = menuItems.children[0] as DBusStruct;
    var attrs1 = item1.children[0] as DBusDict;

    expect(attrs1.children[DBusString('label')],
        DBusVariant(DBusString('Item 1')));
  });
}
