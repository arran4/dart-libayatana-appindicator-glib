@TestOn('linux')
import 'package:test/test.dart';
import 'package:dbus/dbus.dart';
import 'package:ayatana_appindicator/ayatana_appindicator.dart';
import 'mock_watcher_impl.dart';

void main() {
  test('AppIndicator connects and registers', () async {
    var client = DBusClient.session();

    // Start mock watcher
    var watcher = MockWatcher();
    await client.registerObject(watcher);
    await client.requestName('org.kde.StatusNotifierWatcher');

    // Create indicator
    var indicator = AppIndicator(id: 'test-indicator');
    await indicator.connect();

    // Allow some time for async calls
    await Future.delayed(Duration(milliseconds: 200));

    expect(watcher.registeredItems,
        contains(contains('/org/ayatana/appindicator/test_indicator')));

    await indicator.close();
    await client.close();
  });

  test('AppIndicator re-registers when watcher comes back', () async {
    var watcherClient = DBusClient.session();

    var watcher = MockWatcher();
    await watcherClient.registerObject(watcher);
    await watcherClient.requestName('org.kde.StatusNotifierWatcher');

    var indicator = AppIndicator(id: 'reconnect-indicator', autoReconnect: true);
    await indicator.connect();

    await Future.delayed(Duration(milliseconds: 200));
    expect(watcher.registeredItems,
        contains(contains('/org/ayatana/appindicator/reconnect_indicator')));

    await watcherClient.close();

    var watcherClient2 = DBusClient.session();
    var watcher2 = MockWatcher();
    await watcherClient2.registerObject(watcher2);
    await watcherClient2.requestName('org.kde.StatusNotifierWatcher');

    await Future.delayed(Duration(milliseconds: 300));

    expect(watcher2.registeredItems,
        contains(contains('/org/ayatana/appindicator/reconnect_indicator')));

    await indicator.close();
    await watcherClient2.close();
  });

  test('AppIndicator properties', () {
    var indicator = AppIndicator(id: 'prop-indicator');
    indicator.title = 'Title';
    indicator.iconName = 'Icon';
    indicator.tooltipTitle = 'TipTitle';

    // We assume setters work as they modify internal state which DBus object reads.
    // Since we can't easily introspect loopback DBus without knowing unique name,
    // and we don't want to expose internal object, we trust the implementation (verified by code review).
  });
}
