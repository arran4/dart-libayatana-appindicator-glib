import 'package:dart_libayatana_appindicator/src/dbus_menu.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  test('DBusMenu GetLayout parentId and recursionDepth', () async {
    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), []);

    menu.updateItems([
      DBusMenuItem(id: 1, properties: {'label': DBusString('Item 1')}),
      DBusMenuItem(id: 2, properties: {
        'label': DBusString('Item 2')
      }, children: [
        DBusMenuItem(id: 3, properties: {
          'label': DBusString('Sub Item 1')
        }, children: [
          DBusMenuItem(
              id: 4, properties: {'label': DBusString('Sub Sub Item 1')})
        ]),
      ]),
    ]);

    // Test parentId = 0, recursionDepth = -1
    var response = await menu.handleMethodCall(DBusMethodCall(
        sender: 'test',
        interface: 'com.canonical.dbusmenu',
        name: 'GetLayout',
        values: [DBusInt32(0), DBusInt32(-1), DBusArray.string([])]));

    expect(response, isA<DBusMethodSuccessResponse>());
    var values = (response as DBusMethodSuccessResponse).returnValues;
    expect(values.length, 2);
    expect(values[0], isA<DBusUint32>()); // revision
    var layout = values[1] as DBusStruct;
    expect(layout.children[0].asInt32(), 0); // root id

    // Check root children count
    var rootChildren = layout.children[2] as DBusArray;
    expect(rootChildren.children.length, 2); // Item 1, Item 2

    // Check parentId = 2, recursionDepth = 1
    response = await menu.handleMethodCall(DBusMethodCall(
        sender: 'test',
        interface: 'com.canonical.dbusmenu',
        name: 'GetLayout',
        values: [DBusInt32(2), DBusInt32(1), DBusArray.string([])]));

    values = (response as DBusMethodSuccessResponse).returnValues;
    layout = values[1] as DBusStruct;
    expect(layout.children[0].asInt32(), 2); // Item 2 id

    var item2Children = layout.children[2] as DBusArray;
    expect(item2Children.children.length, 1); // Sub Item 1

    var subItem1 =
        (item2Children.children[0] as DBusVariant).value as DBusStruct;
    expect(subItem1.children[0].asInt32(), 3); // Sub Item 1 id
    var subItem1Children = subItem1.children[2] as DBusArray;
    expect(subItem1Children.children.length,
        0); // Should be empty because recursionDepth = 1
  });
}
