import 'package:ayatana_appindicator/src/menu.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  test('setMenu keeps group id and replaces items', () async {
    var menu = DBusMenu(DBusObjectPath('/test'));
    var id = menu.addMenu([
      DBusMenuItem({'label': DBusString('Old')}, {}),
    ]);

    menu.setMenu(id, [
      DBusMenuItem({'label': DBusString('New')}, {}),
      DBusMenuItem({'label': DBusString('Another')}, {}),
    ]);

    var response = await menu.handleMethodCall(DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Menus',
      name: 'Start',
      values: [DBusArray(DBusSignature('u'), [DBusUint32(0)])],
    ));

    var success = response as DBusMethodSuccessResponse;
    var groups = success.returnValues.first as DBusArray;
    var group = groups.children.single as DBusStruct;

    expect(group.children[1], DBusUint32(id));

    var items = group.children[2] as DBusArray;
    expect(items.children.length, 2);
  });

  test('updateMenuItems applies targeted splice update', () async {
    var menu = DBusMenu(DBusObjectPath('/test'));
    var id = menu.addMenu([
      DBusMenuItem({'label': DBusString('A')}, {}),
      DBusMenuItem({'label': DBusString('B')}, {}),
      DBusMenuItem({'label': DBusString('C')}, {}),
    ]);

    menu.updateMenuItems(id,
        position: 1,
        removeCount: 1,
        items: [DBusMenuItem({'label': DBusString('X')}, {})]);

    var response = await menu.handleMethodCall(DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Menus',
      name: 'Start',
      values: [DBusArray(DBusSignature('u'), [DBusUint32(0)])],
    ));

    var success = response as DBusMethodSuccessResponse;
    var groups = success.returnValues.first as DBusArray;
    var group = groups.children.single as DBusStruct;
    var items = group.children[2] as DBusArray;

    var labels = items.children.map((item) {
      var structure = item as DBusStruct;
      var attrs = structure.children[0] as DBusDict;
      var label = attrs.children[DBusString('label')]! as DBusVariant;
      return label.value.asString();
    }).toList();

    expect(labels, ['A', 'X', 'C']);
  });
}
