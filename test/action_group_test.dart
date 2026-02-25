import 'package:dart_libayatana_appindicator/src/action_group.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

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
      values: [
        DBusString('test'),
        DBusArray(DBusSignature('v'), []),
        DBusDict(DBusSignature('s'), DBusSignature('v'))
      ],
    );

    await group.handleMethodCall(activateCall);
    expect(activated, isTrue);
  });

  test('DBusActionGroup clearActions removes all actions', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    group.addAction(DBusAction('one'));
    group.addAction(DBusAction('two'));

    group.clearActions();

    var describeCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'Describe',
      values: [DBusString('one')],
    );

    var response = await group.handleMethodCall(describeCall);
    expect(response, isA<DBusMethodErrorResponse>());
  });

  test('DBusAction setEnabled and changeState update action data', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    var action = DBusAction('toggle', state: DBusString('off'));
    group.addAction(action);

    action.setEnabled(false);
    action.changeState(DBusString('on'));

    var describeCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'Describe',
      values: [DBusString('toggle')],
    );

    var response = await group.handleMethodCall(describeCall);
    expect(response, isA<DBusMethodSuccessResponse>());
    var result =
        (response as DBusMethodSuccessResponse).returnValues[0] as DBusStruct;

    expect(result.children[0], DBusBoolean(false));
    var stateArray = result.children[2] as DBusArray;
    expect(stateArray.children.single, DBusVariant(DBusString('on')));
  });
}
