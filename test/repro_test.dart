@TestOn('linux')
import 'dart:async';
import 'dart:io';

import 'package:dart_libayatana_appindicator/src/status_notifier_watcher_server.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

class MockWatcher extends StatusNotifierWatcher {
  final List<String> registeredItems = [];

  MockWatcher({String path = '/StatusNotifierWatcher'})
      : super(path: DBusObjectPath(path));

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierItem(
      String service) async {
    print('REPRO: Received Register($service)');
    registeredItems.add(service);
    return DBusMethodSuccessResponse([]);
  }
}

void main() {
  late DBusClient systemClient;
  late DBusClient appClient;

  setUpAll(() async {
    final addressStr = Platform.environment['DBUS_SESSION_BUS_ADDRESS']!;
    final address = DBusAddress(addressStr);
    systemClient = DBusClient(address);
    appClient = DBusClient(address);
  });

  tearDownAll(() async {
    await systemClient.close();
    await appClient.close();
  });

  test('Repro: Direct DBus call populates list', () async {
    const watcherName = 'org.kde.StatusNotifierWatcher.Repro';
    const watcherPath = '/StatusNotifierWatcher/Repro';

    final watcher = MockWatcher(path: watcherPath);
    await systemClient.registerObject(watcher);
    await systemClient.requestName(watcherName);

    // Call directly
    await appClient.callMethod(
      destination: watcherName,
      path: DBusObjectPath(watcherPath),
      interface: 'org.kde.StatusNotifierWatcher',
      name: 'RegisterStatusNotifierItem',
      values: [DBusString('service.1')],
    );

    expect(watcher.registeredItems, contains('service.1'));
  });
}
