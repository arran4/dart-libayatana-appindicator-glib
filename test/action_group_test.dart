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

  test('DBusActionGroup handles SetState correctly', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    var action = DBusAction('toggle', state: DBusString('off'));
    group.addAction(action);

    // Test valid SetState
    var setStateCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'SetState',
      values: [
        DBusString('toggle'),
        DBusVariant(DBusString('on')),
      ],
    );

    var response = await group.handleMethodCall(setStateCall);
    expect(response, isA<DBusMethodSuccessResponse>());
    expect(action.state, DBusString('on'));

    // Verify with Describe
    var describeCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'Describe',
      values: [DBusString('toggle')],
    );
    response = await group.handleMethodCall(describeCall);
    var result =
        (response as DBusMethodSuccessResponse).returnValues[0] as DBusStruct;
    var stateArray = result.children[2] as DBusArray;
    expect(stateArray.children.single, DBusVariant(DBusString('on')));
  });

  test('DBusActionGroup SetState error handling', () async {
    var group = DBusActionGroup(DBusObjectPath('/test'));
    group.addAction(DBusAction('stateless'));
    group.addAction(DBusAction('stateful', state: DBusBoolean(false)));

    // Unknown action
    var unknownCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'SetState',
      values: [
        DBusString('unknown'),
        DBusVariant(DBusString('val')),
      ],
    );
    var response = await group.handleMethodCall(unknownCall);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName,
        'org.freedesktop.DBus.Error.UnknownMethod');

    // Stateless action
    var statelessCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'SetState',
      values: [
        DBusString('stateless'),
        DBusVariant(DBusString('val')),
      ],
    );
    response = await group.handleMethodCall(statelessCall);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName,
        'org.freedesktop.DBus.Error.InvalidArgs');

    // Invalid value (not a variant)
    var invalidArgsCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'SetState',
      values: [
        DBusString('stateful'),
        DBusString('not a variant'),
      ],
    );
    response = await group.handleMethodCall(invalidArgsCall);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName,
        'org.freedesktop.DBus.Error.InvalidArgs');

    // Missing arguments
    var missingArgsCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'SetState',
      values: [DBusString('stateful')],
    );
    response = await group.handleMethodCall(missingArgsCall);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName,
        'org.freedesktop.DBus.Error.InvalidArgs');

    // Wrong type for name
    var wrongTypeCall = DBusMethodCall(
      sender: 'sender',
      interface: 'org.gtk.Actions',
      name: 'SetState',
      values: [
        DBusBoolean(true),
        DBusVariant(DBusString('val')),
      ],
    );
    response = await group.handleMethodCall(wrongTypeCall);
    expect(response, isA<DBusMethodErrorResponse>());
    expect((response as DBusMethodErrorResponse).errorName,
        'org.freedesktop.DBus.Error.InvalidArgs');
  });
}
