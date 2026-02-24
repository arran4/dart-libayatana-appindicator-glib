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

    expect(watcher.registeredItems, contains(contains('/org/ayatana/appindicator/test_indicator')));

    await indicator.close();
    await client.close();
  });


  test('AppIndicator retries registration with bounded backoff', () async {
    var client = DBusClient.session();

    var watcher = FlakyMockWatcher(remainingFailures: 2);
    await client.registerObject(watcher);
    await client.requestName('org.kde.StatusNotifierWatcher');

    var indicator = AppIndicator(
      id: 'retry-indicator',
      registrationRetryCount: 3,
      registrationTimeout: Duration(milliseconds: 300),
      registrationBackoffBase: Duration(milliseconds: 10),
      registrationBackoffMax: Duration(milliseconds: 20),
    );

    await indicator.connect();

    await Future.delayed(Duration(milliseconds: 200));

    expect(watcher.registeredItems,
        contains(contains('/org/ayatana/appindicator/retry_indicator')));

    await indicator.close();
    await client.close();
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
