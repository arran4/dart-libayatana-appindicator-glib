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

    expect(
      watcher.registeredItems,
      contains(contains('/org/ayatana/appindicator/test_indicator')),
    );

    await indicator.close();
    await client.close();
  });

  test('AppIndicator properties', () {
    var indicator = AppIndicator(id: 'prop-indicator');
    indicator.status = AppIndicatorStatus.attention;
    indicator.title = 'Title';
    indicator.iconName = 'Icon';
    indicator.label = 'Label';
    indicator.labelGuide = 'Guide';
    indicator.orderingIndex = 7;
    indicator.tooltipIconName = 'TipIcon';
    indicator.tooltipTitle = 'TipTitle';
    indicator.tooltipDescription = 'TipDescription';

    expect(indicator.status, equals(AppIndicatorStatus.attention));
    expect(indicator.title, equals('Title'));
    expect(indicator.iconName, equals('Icon'));
    expect(indicator.label, equals('Label'));
    expect(indicator.labelGuide, equals('Guide'));
    expect(indicator.orderingIndex, equals(7));
    expect(indicator.tooltipIconName, equals('TipIcon'));
    expect(indicator.tooltipTitle, equals('TipTitle'));
    expect(indicator.tooltipDescription, equals('TipDescription'));
  });
}
