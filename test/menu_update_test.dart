@TestOn('linux')
import 'package:dart_libayatana_appindicator/src/dbus_menu.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  test('updateMenuItems error handling', () async {
    // Create a mutable list for root items
    var children = <DBusMenuItem>[
      DBusMenuItem(id: 1, properties: {'label': DBusString('Item 1')})
    ];

    var menu = DBusMenu(const DBusObjectPath.unchecked('/test'), children);

    // Test 1: Invalid ID (ArgumentError)
    // ID 999 does not exist.
    expect(() => menu.updateMenuItems(999, position: 0), throwsArgumentError);

    // Test 2: Position < 0 (RangeError)
    // ID 0 exists (root items).
    expect(() => menu.updateMenuItems(0, position: -1), throwsRangeError);

    // Test 3: Position > length (RangeError)
    // Length is 1. Position 2 is invalid. Position 1 is valid (append).
    expect(() => menu.updateMenuItems(0, position: 2), throwsRangeError);

    // Test 4: RemoveCount < 0 (RangeError)
    expect(() => menu.updateMenuItems(0, position: 0, removeCount: -1),
        throwsRangeError);

    // Test 5: RemoveCount > length - position (RangeError)
    // Length 1. Position 0. Max removeCount is 1.
    expect(() => menu.updateMenuItems(0, position: 0, removeCount: 2),
        throwsRangeError);

    // Test 6: Happy Path - Update root items
    // Replace item at position 0.
    var newItem =
        DBusMenuItem(id: 2, properties: {'label': DBusString('Item 2')});
    menu.updateMenuItems(0, position: 0, removeCount: 1, items: [newItem]);

    expect(menu.items.length, 1);
    expect((menu.items[0].properties['label'] as DBusString).value, 'Item 2');

    // Test 7: Happy Path - Update sub-menu
    // Create an item with children (must be mutable list)
    var subChildren = <DBusMenuItem>[
      DBusMenuItem(id: 4, properties: {'label': DBusString('SubItem 1')})
    ];
    var parentItem = DBusMenuItem(
        id: 3,
        properties: {'label': DBusString('Parent')},
        children: subChildren);

    // Update root items to include parentItem
    menu.updateItems([parentItem]);

    // Now ID 3 should be in _menus and mapped to subChildren.
    // Update children of ID 3.
    var newSubItem =
        DBusMenuItem(id: 5, properties: {'label': DBusString('SubItem 2')});
    menu.updateMenuItems(3, position: 0, removeCount: 1, items: [newSubItem]);

    expect(parentItem.children.length, 1);
    expect((parentItem.children[0].properties['label'] as DBusString).value,
        'SubItem 2');

    // Test 8: Ensure new items are registered
    // We just added ID 5. It has no children.
    // But if we added an item WITH children, they should be registered.
    var deepChildren = <DBusMenuItem>[
      DBusMenuItem(id: 7, properties: {'label': DBusString('DeepItem')})
    ];
    var midItem = DBusMenuItem(
        id: 6,
        properties: {'label': DBusString('Mid')},
        children: deepChildren);

    // Add midItem to parentItem (ID 3)
    menu.updateMenuItems(3, position: 1, items: [midItem]);

    // Now ID 6 should be registered.
    // We can test this by trying to update ID 6.
    var deepItemReplacement =
        DBusMenuItem(id: 8, properties: {'label': DBusString('DeepItem 2')});

    // This should NOT throw ArgumentError if ID 6 is registered.
    menu.updateMenuItems(6,
        position: 0, removeCount: 1, items: [deepItemReplacement]);

    expect(deepChildren.length, 1);
    expect((deepChildren[0].properties['label'] as DBusString).value,
        'DeepItem 2');
  });
}
