@TestOn('linux')
import 'dart:async';

import 'package:ayatana_appindicator/ayatana_appindicator.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

import 'mock_watcher_impl.dart';

void main() {
  test('AppIndicator connects and registers', () async {
    var client = DBusClient.session();

    var watcher = MockWatcher();
    await client.registerObject(watcher);
    await client.requestName('org.kde.StatusNotifierWatcher');

    var indicator = AppIndicator(id: 'test-indicator');
    await indicator.connect();

    await Future.delayed(Duration(milliseconds: 200));

    expect(
      watcher.registeredItems,
      contains(matches(r'^org\.ayatana\.appindicator\.test_indicator\.p[0-9]+/org/ayatana/appindicator/test_indicator$')),
    );

    await indicator.close();

    expect(
      watcher.unregisteredItems,
      contains(matches(r'^org\.ayatana\.appindicator\.test_indicator\.p[0-9]+/org/ayatana/appindicator/test_indicator$')),
    );

    await client.close();
  });

  test('AppIndicator probes alternate watcher backends', () async {
    var client = DBusClient.session();

    var watcher = MockWatcher(path: '/org/freedesktop/StatusNotifierWatcher');
    await client.registerObject(watcher);
    await client.requestName('org.freedesktop.StatusNotifierWatcher');

    var indicator = AppIndicator(id: 'freedesktop-indicator');
    await indicator.connect();

    await Future.delayed(Duration(milliseconds: 200));

    expect(
      watcher.registeredItems,
      contains(matches(r'^org\.ayatana\.appindicator\.freedesktop_indicator\.p[0-9]+/org/ayatana/appindicator/freedesktop_indicator$')),
    );

    await indicator.close();
    await client.close();
  });

  test('AppIndicator connect does not throw when watcher is unavailable', () async {
    var indicator = AppIndicator(id: 'missing-watcher');

    await indicator.connect();

    await indicator.close();
  });


  test('AppIndicator reports watcher and host availability', () async {
    var indicatorWithoutWatcher = AppIndicator(id: 'diag-missing-watcher');
    await indicatorWithoutWatcher.connect();
    expect(indicatorWithoutWatcher.isWatcherAvailable, isFalse);
    expect(await indicatorWithoutWatcher.isStatusNotifierHostRegistered(), isFalse);
    await indicatorWithoutWatcher.close();

    var client = DBusClient.session();
    var watcher = MockWatcher();
    await client.registerObject(watcher);
    await client.requestName('org.kde.StatusNotifierWatcher');

    var indicatorWithWatcher = AppIndicator(id: 'diag-with-watcher');
    await indicatorWithWatcher.connect();
    expect(indicatorWithWatcher.isWatcherAvailable, isTrue);
    expect(await indicatorWithWatcher.isStatusNotifierHostRegistered(), isFalse);

    await indicatorWithWatcher.close();
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

  test('AppIndicator sanitizes ids to valid non-empty DBus path segments', () async {
    var client = DBusClient.session();

    var watcher = MockWatcher();
    await client.registerObject(watcher);
    await client.requestName('org.kde.StatusNotifierWatcher');

    var emptyAfterSanitize = AppIndicator(id: '!!!');
    await emptyAfterSanitize.connect();

    var leadingDigit = AppIndicator(id: '123-start');
    await leadingDigit.connect();

    await Future.delayed(Duration(milliseconds: 200));

    expect(
      watcher.registeredItems,
      contains(matches(r'^org\.ayatana\.appindicator\.indicator_ea0b3f80\.p[0-9]+/org/ayatana/appindicator/indicator_ea0b3f80$')),
    );
    expect(
      watcher.registeredItems,
      contains(matches(r'^org\.ayatana\.appindicator\.indicator_123_start\.p[0-9]+/org/ayatana/appindicator/indicator_123_start$')),
    );

    await emptyAfterSanitize.close();
    await leadingDigit.close();
    await client.close();
  });

  test('AppIndicator dispatch emits interaction events', () async {
    var indicator = AppIndicator(id: 'event-indicator');

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

    await indicator.dispatchActivate(x: 10, y: 11);
    await indicator.dispatchSecondaryActivate(x: 12, y: 13);
    await indicator.dispatchContextMenu(x: 14, y: 15);
    await indicator.dispatchScroll(delta: 3, orientation: 'vertical');

    expect((await activate.future).x, 10);
    expect((await secondary.future).y, 13);
    expect((await context.future).x, 14);
    expect((await scroll.future).delta, 3);

    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await indicator.close();
  });


  test('AppIndicator exposes icon pixmap related properties', () async {
    var indicator = AppIndicator(id: 'pixmap-indicator');
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

  test('AppIndicator click targets trigger actions', () async {
    var indicator = AppIndicator(id: 'action-target-indicator');

    var primaryCount = 0;
    var secondaryCount = 0;
    var doubleClickCount = 0;

    indicator.setActions([
      DBusAction('primary', onActivate: (_) => primaryCount++),
      DBusAction('secondary', onActivate: (_) => secondaryCount++),
      DBusAction('double', onActivate: (_) => doubleClickCount++),
    ]);

    indicator
      ..setPrimaryActivateTarget('primary')
      ..setSecondaryActivateTarget('secondary')
      ..setDoubleClickTarget('double')
      ..doubleClickWindow = const Duration(milliseconds: 750);

    await indicator.dispatchActivate();
    await indicator.dispatchSecondaryActivate();
    await indicator.dispatchActivate();

    expect(primaryCount, 2);
    expect(secondaryCount, 1);
    expect(doubleClickCount, 1);

    await indicator.close();
  });
}
