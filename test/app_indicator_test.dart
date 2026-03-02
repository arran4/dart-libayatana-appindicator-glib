@TestOn('linux')
import 'dart:async';
import 'dart:io';

import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';
import 'package:dart_libayatana_appindicator/src/status_notifier_watcher_server.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

class MockWatcher extends StatusNotifierWatcher {
  final List<String> registeredItems = [];
  final List<String> unregisteredItems = [];

  MockWatcher({String path = '/StatusNotifierWatcher'})
      : super(path: DBusObjectPath(path));

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierItem(
      String service) async {
    if (!registeredItems.contains(service)) {
      registeredItems.add(service);
      await emitStatusNotifierItemRegistered(service);
    }
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierWatcher' &&
        methodCall.name == 'UnregisterStatusNotifierItem') {
      final service = methodCall.values[0].asString();
      if (!unregisteredItems.contains(service)) {
        unregisteredItems.add(service);
      }
    }
    return super.handleMethodCall(methodCall);
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

  setUp(() async {
    // No static state to clear
  });

  test('AppIndicator connects and registers', () async {
    const watcherName = 'org.kde.StatusNotifierWatcher.BasicTest';
    const watcherPath = '/StatusNotifierWatcher/BasicTest';

    final watcher = MockWatcher(path: watcherPath);
    await systemClient.registerObject(watcher);
    var reply = await systemClient.requestName(watcherName);
    if (reply != DBusRequestNameReply.primaryOwner) {
      throw 'Failed to request name $watcherName: $reply';
    }

    final sub = systemClient.nameOwnerChanged.listen((event) {
      if (event.newOwner == null || event.newOwner!.isEmpty) {
        if (!watcher.unregisteredItems.contains(event.name)) {
          watcher.unregisteredItems.add(event.name);
        }
      }
    });

    final indicator = AppIndicator(id: 'test-indicator', client: appClient);
    await indicator.connect(watcherName: watcherName, watcherPath: watcherPath);

    // Poll for registration
    for (var i = 0; i < 20; i++) {
      if (watcher.registeredItems.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (watcher.registeredItems.isEmpty) {
      throw Exception(
          'Registered items is empty! Actual: ${watcher.registeredItems}');
    }

    final found = watcher.registeredItems.any((item) => RegExp(
            r'^org\.ayatana\.appindicator\.test_indicator\.p[0-9]+\.v[0-9]+(/org/ayatana/appindicator/test_indicator)?$')
        .hasMatch(item));

    if (!found) {
      throw Exception(
          'Registered items did not contain match. Actual: ${watcher.registeredItems}');
    }

    await indicator.close();

    // Poll for unregistration
    for (var i = 0; i < 20; i++) {
      if (watcher.unregisteredItems.any((item) => RegExp(
              r'^org\.ayatana\.appindicator\.test_indicator\.p[0-9]+\.v[0-9]+(/org/ayatana/appindicator/test_indicator)?$')
          .hasMatch(item))) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    expect(
      watcher.unregisteredItems,
      contains(matches(
          r'^org\.ayatana\.appindicator\.test_indicator\.p[0-9]+\.v[0-9]+(/org/ayatana/appindicator/test_indicator)?$')),
    );

    await sub.cancel();
    await systemClient.releaseName(watcherName);
    systemClient.unregisterObject(watcher);
  });

  test('AppIndicator probes alternate watcher backends', () async {
    const watcherName = 'org.freedesktop.StatusNotifierWatcher.ProbeTest';
    const watcherPath = '/org/freedesktop/StatusNotifierWatcher/ProbeTest';

    final watcher = MockWatcher(path: watcherPath);
    await systemClient.registerObject(watcher);
    await systemClient.requestName(watcherName);

    final indicator =
        AppIndicator(id: 'freedesktop-indicator', client: appClient);
    await indicator.connect(watcherName: watcherName, watcherPath: watcherPath);

    // Poll for registration
    for (var i = 0; i < 20; i++) {
      if (watcher.registeredItems.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final found = watcher.registeredItems.any((item) => RegExp(
            r'^org\.ayatana\.appindicator\.freedesktop_indicator\.p[0-9]+\.v[0-9]+(/org/ayatana/appindicator/freedesktop_indicator)?$')
        .hasMatch(item));

    expect(found, isTrue,
        reason:
            'Registered items should contain match. Actual: ${watcher.registeredItems}');

    await indicator.close();
    await systemClient.releaseName(watcherName);
    systemClient.unregisterObject(watcher);
  });

  test('AppIndicator connect does not throw when watcher is unavailable',
      () async {
    final indicator = AppIndicator(id: 'missing-watcher', client: appClient);
    await indicator.connect(
        watcherName: 'org.kde.StatusNotifierWatcher.NonExistent');
    await indicator.close();
  });

  test('AppIndicator reports watcher and host availability', () async {
    const watcherName = 'org.kde.StatusNotifierWatcher.DiagTest';
    const watcherPath = '/StatusNotifierWatcher/DiagTest';

    final indicatorWithoutWatcher =
        AppIndicator(id: 'diag-missing-watcher', client: appClient);
    await indicatorWithoutWatcher.connect(
        watcherName: 'org.kde.StatusNotifierWatcher.None');
    expect(indicatorWithoutWatcher.isWatcherAvailable, isFalse);
    expect(await indicatorWithoutWatcher.isStatusNotifierHostRegistered(),
        isFalse);
    await indicatorWithoutWatcher.close();

    final watcher = MockWatcher(path: watcherPath);
    await systemClient.registerObject(watcher);
    await systemClient.requestName(watcherName);

    final indicatorWithWatcher =
        AppIndicator(id: 'diag-with-watcher', client: appClient);
    await indicatorWithWatcher.connect(
        watcherName: watcherName, watcherPath: watcherPath);
    expect(indicatorWithWatcher.isWatcherAvailable, isTrue);

    await indicatorWithWatcher.close();
    await systemClient.releaseName(watcherName);
    systemClient.unregisterObject(watcher);
  });

  test('AppIndicator sanitizes ids to valid non-empty DBus path segments',
      () async {
    const watcherName = 'org.kde.StatusNotifierWatcher.SanitizeTest';
    const watcherPath = '/StatusNotifierWatcher/SanitizeTest';

    final watcher = MockWatcher(path: watcherPath);
    await systemClient.registerObject(watcher);
    await systemClient.requestName(watcherName);

    final emptyAfterSanitize = AppIndicator(id: '!!!', client: appClient);
    await emptyAfterSanitize.connect(
        watcherName: watcherName, watcherPath: watcherPath);

    final leadingDigit = AppIndicator(id: '123-start', client: appClient);
    await leadingDigit.connect(
        watcherName: watcherName, watcherPath: watcherPath);

    // Poll for registration
    for (var i = 0; i < 20; i++) {
      if (watcher.registeredItems.length >= 2) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final found1 = watcher.registeredItems.any((item) => RegExp(
            r'^org\.ayatana\.appindicator\.indicator_6dd07555\.p[0-9]+\.v[0-9]+(/org/ayatana/appindicator/indicator_6dd07555)?$')
        .hasMatch(item));
    final found2 = watcher.registeredItems.any((item) => RegExp(
            r'^org\.ayatana\.appindicator\.indicator_123_start\.p[0-9]+\.v[0-9]+(/org/ayatana/appindicator/indicator_123_start)?$')
        .hasMatch(item));

    expect(found1, isTrue,
        reason:
            'Registered items should contain first match. Actual: ${watcher.registeredItems}');
    expect(found2, isTrue,
        reason:
            'Registered items should contain second match. Actual: ${watcher.registeredItems}');

    await emptyAfterSanitize.close();
    await leadingDigit.close();
    await systemClient.releaseName(watcherName);
    systemClient.unregisterObject(watcher);
  });

  test('AppIndicator dispatch emits interaction events', () async {
    const watcherName = 'org.kde.StatusNotifierWatcher.EventTest';
    const watcherPath = '/StatusNotifierWatcher/EventTest';

    final watcher = MockWatcher(path: watcherPath);
    await systemClient.registerObject(watcher);
    await systemClient.requestName(watcherName);

    final indicator = AppIndicator(id: 'event-indicator', client: appClient);
    await indicator.connect(
        watcherName: 'org.kde.StatusNotifierWatcher.NonExistent');

    final activate = Completer<ActivateEvent>();
    final secondary = Completer<SecondaryActivateEvent>();
    final context = Completer<ContextMenuEvent>();
    final scroll = Completer<ScrollEvent>();

    final subscriptions = [
      indicator.activateEvents.listen(activate.complete),
      indicator.secondaryActivateEvents.listen(secondary.complete),
      indicator.contextMenuEvents.listen(context.complete),
      indicator.scrollEvents.listen(scroll.complete),
    ];

    await indicator.connect(watcherName: watcherName, watcherPath: watcherPath);

    // Poll for registration to get the dynamically generated service name
    String? serviceName;
    for (var i = 0; i < 20; i++) {
      final match = watcher.registeredItems.cast<String?>().firstWhere(
            (item) =>
                item != null &&
                RegExp(r'^org\.ayatana\.appindicator\.event_indicator\.p[0-9]+\.v[0-9]+(/org/ayatana/appindicator/event_indicator)?$')
                    .hasMatch(item),
            orElse: () => null,
          );
      if (match != null) {
        serviceName = match.split('/')[0];
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (serviceName == null) {
      throw Exception(
          'Failed to find registered event-indicator. Actual items: ${watcher.registeredItems}');
    }

    final objectPath =
        DBusObjectPath('/org/ayatana/appindicator/event_indicator');

    await systemClient.callMethod(
      destination: serviceName,
      path: objectPath,
      interface: 'org.kde.StatusNotifierItem',
      name: 'Activate',
      values: [DBusInt32(10), DBusInt32(11)],
    );
    await systemClient.callMethod(
      destination: serviceName,
      path: objectPath,
      interface: 'org.kde.StatusNotifierItem',
      name: 'SecondaryActivate',
      values: [DBusInt32(12), DBusInt32(13)],
    );
    await systemClient.callMethod(
      destination: serviceName,
      path: objectPath,
      interface: 'org.kde.StatusNotifierItem',
      name: 'ContextMenu',
      values: [DBusInt32(14), DBusInt32(15)],
    );
    await systemClient.callMethod(
      destination: serviceName,
      path: objectPath,
      interface: 'org.kde.StatusNotifierItem',
      name: 'Scroll',
      values: [DBusInt32(3), DBusString('vertical')],
    );

    expect((await activate.future).x, 10);
    expect((await secondary.future).y, 13);
    expect((await context.future).x, 14);
    expect((await scroll.future).delta, 3);

    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await indicator.close();
    await systemClient.releaseName(watcherName);
    systemClient.unregisterObject(watcher);
  });

  test('AppIndicator exposes icon pixmap related properties', () async {
    final indicator = AppIndicator(id: 'pixmap-indicator', client: appClient);
    indicator
      ..itemIsMenu = true
      ..windowId = 77
      ..iconPixmaps = const [
        IconPixmap(width: 1, height: 1, argb32Bytes: [0xff, 0x00, 0x00, 0xff]),
      ]
      ..attentionIconPixmaps = const [
        IconPixmap(width: 1, height: 1, argb32Bytes: [0xff, 0xff, 0x00, 0x00]),
      ]
      ..overlayIconName = 'overlay-name'
      ..overlayIconPixmaps = const [
        IconPixmap(width: 1, height: 1, argb32Bytes: [0xff, 0x00, 0xff, 0x00]),
      ]
      ..attentionMovieName = 'attention-movie';

    await indicator.connect();
    await indicator.close();
  });
}
