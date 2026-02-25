import 'package:dart_libayatana_appindicator/src/action_group.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  test('DBusActionGroup Describe returns invalidArgs for incorrect signature (empty)', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'Describe',
      values: [], // Missing argument
    );
    var response = await group.handleMethodCall(call);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName, 'org.freedesktop.DBus.Error.InvalidArgs');
  });

  test('DBusActionGroup Describe returns invalidArgs for incorrect signature (wrong type)', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'Describe',
      values: [DBusInt32(123)], // Wrong argument type
    );
    var response = await group.handleMethodCall(call);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName, 'org.freedesktop.DBus.Error.InvalidArgs');
  });

  test('DBusActionGroup DescribeAll returns invalidArgs for incorrect signature', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'DescribeAll',
      values: [DBusString('extra')], // Extra argument
    );
    var response = await group.handleMethodCall(call);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName, 'org.freedesktop.DBus.Error.InvalidArgs');
  });

  test('DBusActionGroup DescribeAll returns descriptions for all actions', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    group.addAction(DBusAction('action1', enabled: true));
    group.addAction(DBusAction('action2', enabled: false));

    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'DescribeAll',
      values: [],
    );
    var response = await group.handleMethodCall(call);
    expect(response, isA<DBusMethodSuccessResponse>());
    var result = (response as DBusMethodSuccessResponse).returnValues[0];
    expect(result, isA<DBusDict>());
    var dict = result as DBusDict;
    expect(dict.children.length, 2);
    expect(dict.children[DBusString('action1')], isNotNull);
    expect(dict.children[DBusString('action2')], isNotNull);
  });
}
