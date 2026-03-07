import 'package:dart_libayatana_appindicator/src/dbus_menu.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  test('DBusMenu GetLayout propertyNames filter', () async {
    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), []);

    menu.updateItems([
      DBusMenuItem(id: 1, properties: {
        'label': DBusString('Item 1'),
        'icon-name': DBusString('folder'),
        'enabled': DBusBoolean(true),
      }),
    ]);

    // Test with empty propertyNames (should return all properties)
    var response = await menu.handleMethodCall(DBusMethodCall(
        sender: 'test',
        interface: 'com.canonical.dbusmenu',
        name: 'GetLayout',
        values: [DBusInt32(0), DBusInt32(-1), DBusArray.string([])]));

    expect(response, isA<DBusMethodSuccessResponse>());
    var values = (response as DBusMethodSuccessResponse).returnValues;
    var layout = values[1] as DBusStruct;
    var rootChildren = layout.children[2] as DBusArray;
    var item1 = (rootChildren.children[0] as DBusVariant).value as DBusStruct;
    var props = item1.children[1] as DBusDict;
    expect(props.children.length, 3);

    // Test with specific propertyNames
    response = await menu.handleMethodCall(DBusMethodCall(
        sender: 'test',
        interface: 'com.canonical.dbusmenu',
        name: 'GetLayout',
        values: [
          DBusInt32(0),
          DBusInt32(-1),
          DBusArray.string(['label', 'non-existent'])
        ]));

    values = (response as DBusMethodSuccessResponse).returnValues;
    layout = values[1] as DBusStruct;
    rootChildren = layout.children[2] as DBusArray;
    item1 = (rootChildren.children[0] as DBusVariant).value as DBusStruct;
    props = item1.children[1] as DBusDict;
    expect(props.children.length, 1);
    expect(props.children.keys.first, DBusString('label'));
  });
}
