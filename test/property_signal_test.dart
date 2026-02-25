@TestOn('linux')
import 'dart:async';

import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

import 'mock_watcher_impl.dart';

void main() {
  late DBusClient client;
  late DBusClient listenerClient;
  late AppIndicator indicator;
  late MockWatcher watcher;

  setUp(() async {
    client = DBusClient.session();
    listenerClient = DBusClient.session();

    MockWatcher.registeredItems.clear();
    watcher = MockWatcher(path: '/StatusNotifierWatcher/PropertyTest');
    await client.registerObject(watcher);
    await client.requestName('org.kde.StatusNotifierWatcher.PropertyTest');

    indicator = AppIndicator(id: 'test', client: client);
    await indicator.connect(
      watcherName: 'org.kde.StatusNotifierWatcher.PropertyTest',
      watcherPath: '/StatusNotifierWatcher/PropertyTest',
    );
  });

  tearDown(() async {
    await indicator.close();
    await client.releaseName('org.kde.StatusNotifierWatcher.PropertyTest');
    client.unregisterObject(watcher);
    await client.close();
    await listenerClient.close();
  });

  test('Property updates emit signals and update values', () async {
    // Wait for registration
    int retries = 0;
    while (MockWatcher.registeredItems.isEmpty && retries < 10) {
      await Future.delayed(Duration(milliseconds: 100));
      retries++;
    }
    expect(MockWatcher.registeredItems, isNotEmpty,
        reason: 'Service not registered');

    final serviceName = MockWatcher.registeredItems.last;

    final remoteObject = DBusRemoteObject(
      listenerClient,
      name: serviceName,
      path: DBusObjectPath('/org/ayatana/appindicator/test'),
    );

    // Streams for signals
    final newTitleStream = DBusRemoteObjectSignalStream(
      object: remoteObject,
      interface: 'org.kde.StatusNotifierItem',
      name: 'NewTitle',
      signature: DBusSignature(''),
    );
    final newStatusStream = DBusRemoteObjectSignalStream(
      object: remoteObject,
      interface: 'org.kde.StatusNotifierItem',
      name: 'NewStatus',
      signature: DBusSignature('s'),
    );
    final newIconStream = DBusRemoteObjectSignalStream(
      object: remoteObject,
      interface: 'org.kde.StatusNotifierItem',
      name: 'NewIcon',
      signature: DBusSignature(''),
    );
    final newToolTipStream = DBusRemoteObjectSignalStream(
      object: remoteObject,
      interface: 'org.kde.StatusNotifierItem',
      name: 'NewToolTip',
      signature: DBusSignature(''),
    );

    final newTitleFuture = newTitleStream.first;
    final newStatusFuture = newStatusStream.first;
    final newIconFuture = newIconStream.first;
    final newToolTipFuture = newToolTipStream.first;

    // Wait for signal match rules to propagate
    await Future.delayed(Duration(seconds: 1));

    // Test Title
    indicator.title = 'Updated Title';
    expect(indicator.title, 'Updated Title');
    await newTitleFuture.timeout(Duration(seconds: 2));

    // Test Status
    indicator.status = AppIndicatorStatus.active;
    expect(indicator.status, AppIndicatorStatus.active);
    await newStatusFuture.timeout(Duration(seconds: 2));

    // Test Icon
    indicator.iconName = 'new-icon';
    expect(indicator.iconName, 'new-icon');
    await newIconFuture.timeout(Duration(seconds: 2));

    // Test Tooltip
    indicator.tooltipTitle = 'New Tooltip';
    expect(indicator.tooltipTitle, 'New Tooltip');
    await newToolTipFuture.timeout(Duration(seconds: 2));
  });
}
