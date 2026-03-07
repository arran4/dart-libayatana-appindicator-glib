@TestOn('linux')
import 'dart:io';

import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';

void main() {
  late DBusClient client;

  setUpAll(() async {
    final addressStr = Platform.environment['DBUS_SESSION_BUS_ADDRESS'];
    client = addressStr != null
        ? DBusClient(DBusAddress(addressStr))
        : DBusClient.session();
  });

  tearDownAll(() async {
    await client.close();
  });

  test('AppIndicator splits icon path into name and theme path', () async {
    final tempDir = Directory.systemTemp.createTempSync('icon_test_');
    final iconFile = File('${tempDir.path}/icon.png');
    iconFile.createSync();

    var indicator = AppIndicator(id: 'path-test', client: client);
    await indicator.connect(
        watcherName: 'org.kde.StatusNotifierWatcher.NonExistent');

    // Set iconName to the full path
    indicator.iconName = iconFile.path;

    // Verify DBus exposed value
    final response = await client.callMethod(
      destination: client.uniqueName,
      path: DBusObjectPath('/org/ayatana/appindicator/path_test'),
      interface: 'org.freedesktop.DBus.Properties',
      name: 'Get',
      values: [
        DBusString('org.kde.StatusNotifierItem'),
        DBusString('IconName')
      ],
    );
    final val = response.values[0];
    final exposedIconName =
        val is DBusVariant ? val.value as DBusString : val as DBusString;
    expect(exposedIconName.value, equals('icon'),
        reason:
            'Exposed DBus IconName should be stripped of path and extension');

    // Verify that the getter returns the full path (what was set)
    expect(indicator.iconName, equals(iconFile.path),
        reason: 'IconName getter should return the full path set by user');

    // Verify that the computed theme path is correct
    expect(indicator.iconThemePath, equals(tempDir.path),
        reason: 'IconThemePath should be the directory of the icon file');

    await indicator.close();
    tempDir.deleteSync(recursive: true);
  });

  test('AppIndicator handles attentionIconName path and status change',
      () async {
    final tempDir = Directory.systemTemp.createTempSync('attn_test_');
    final iconFile = File('${tempDir.path}/icon.png');
    final attnDir = Directory('${tempDir.path}/attn');
    attnDir.createSync();
    final attnFile = File('${attnDir.path}/attn.png');
    iconFile.createSync();
    attnFile.createSync();

    var indicator = AppIndicator(id: 'attn-test', client: client);
    await indicator.connect(
        watcherName: 'org.kde.StatusNotifierWatcher.NonExistent');

    // Set iconName
    indicator.iconName = iconFile.path;
    expect(indicator.iconThemePath, equals(tempDir.path));

    // Set attentionIconName
    indicator.attentionIconName = attnFile.path;

    // Verify exposed DBus values
    final responseIcon = await client.callMethod(
      destination: client.uniqueName,
      path: DBusObjectPath('/org/ayatana/appindicator/attn_test'),
      interface: 'org.freedesktop.DBus.Properties',
      name: 'Get',
      values: [
        DBusString('org.kde.StatusNotifierItem'),
        DBusString('IconName')
      ],
    );
    final responseAttn = await client.callMethod(
      destination: client.uniqueName,
      path: DBusObjectPath('/org/ayatana/appindicator/attn_test'),
      interface: 'org.freedesktop.DBus.Properties',
      name: 'Get',
      values: [
        DBusString('org.kde.StatusNotifierItem'),
        DBusString('AttentionIconName')
      ],
    );

    final valIcon = responseIcon.values[0];
    final exposedIcon = valIcon is DBusVariant
        ? valIcon.value as DBusString
        : valIcon as DBusString;

    final valAttn = responseAttn.values[0];
    final exposedAttn = valAttn is DBusVariant
        ? valAttn.value as DBusString
        : valAttn as DBusString;

    expect(exposedIcon.value, equals('icon'));
    expect(exposedAttn.value, equals('attn'));

    // Status is Passive (default), so theme path should still be icon's path
    expect(indicator.status, equals(AppIndicatorStatus.passive));
    expect(indicator.iconThemePath, equals(tempDir.path));

    // Change status to Attention
    indicator.status = AppIndicatorStatus.attention;
    // Theme path should update to attention icon's path
    expect(indicator.iconThemePath, equals(attnDir.path));

    // Change status back to Active
    indicator.status = AppIndicatorStatus.active;
    expect(indicator.iconThemePath, equals(tempDir.path));

    await indicator.close();
    tempDir.deleteSync(recursive: true);
  });
}
