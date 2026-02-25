@TestOn('linux')
import 'dart:io';
import 'package:dart_libayatana_appindicator/src/dbus_menu.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  late DBusClient client;

  setUp(() async {
    // If running in dbus-run-session, use the session bus.
    // Otherwise fallback logic is handled by TestOn('linux').
    if (Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
      client = DBusClient.session();
    } else {
      // Fallback for environments without session bus if needed.
      client = DBusClient.session();
    }
  });

  tearDown(() async {
    await client.close();
  });

  test('DBusMenu Event method accepts 4 arguments', () async {
    var activated = false;
    var menu = DBusMenu(DBusObjectPath('/test/menu'), [
      DBusMenuItem(
          id: 1,
          properties: {'label': DBusString('Item 1')},
          onActivated: () {
            activated = true;
          })
    ]);

    await client.registerObject(menu);
    await client.requestName('org.example.MenuTest');

    // Call Event with 4 arguments
    await client.callMethod(
        destination: 'org.example.MenuTest',
        path: DBusObjectPath('/test/menu'),
        interface: 'com.canonical.dbusmenu',
        name: 'Event',
        values: [
          DBusInt32(1),
          DBusString('clicked'),
          DBusVariant(DBusString('some-data')),
          DBusUint32(1000),
        ],
        replySignature: DBusSignature(''));

    expect(activated, isTrue);
  });
}
