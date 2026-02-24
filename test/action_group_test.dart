import 'package:test/test.dart';
import 'package:dbus/dbus.dart';
import 'package:ayatana_appindicator/src/action_group.dart';

void main() {
  test('DBusActionGroup exports actions correctly', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));

    var activated = false;
    var action = DBusAction('test', onActivate: (_) => activated = true);
    group.addAction(action);

    // Test Describe
    var call = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'Describe',
      values: [DBusString('test')],
    );

    var response = await group.handleMethodCall(call);
    expect(response, isA<DBusMethodSuccessResponse>());
    var success = response as DBusMethodSuccessResponse;
    var result = success.returnValues[0];

    expect(result, isA<DBusStruct>());
    var s = result as DBusStruct;
    expect(s.children[0], DBusBoolean(true)); // enabled

    // Test Activate
    var activateCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'Activate',
      values: [DBusString('test'), DBusArray(DBusSignature('v'), []), DBusDict(DBusSignature('s'), DBusSignature('v'))],
    );

    await group.handleMethodCall(activateCall);
    expect(activated, isTrue);
  });
}
