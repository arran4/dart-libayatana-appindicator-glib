@TestOn('linux')
import 'dart:io';

import 'package:ayatana_appindicator/ayatana_appindicator.dart';
import 'package:test/test.dart';

void main() {
  test('AppIndicator splits icon path into name and theme path', () async {
    final tempDir = Directory.systemTemp.createTempSync('icon_test_');
    final iconFile = File('${tempDir.path}/icon.png');
    iconFile.createSync();

    var indicator = AppIndicator(id: 'path-test');

    // Set iconName to the full path
    indicator.iconName = iconFile.path;

    // Verify that the getter returns the full path (what was set)
    expect(indicator.iconName, equals(iconFile.path),
        reason: 'IconName getter should return the full path set by user');

    // Verify that the computed theme path is correct
    expect(indicator.iconThemePath, equals(tempDir.path),
        reason: 'IconThemePath should be the directory of the icon file');

    tempDir.deleteSync(recursive: true);
  });

  test('AppIndicator handles attentionIconName path and status change', () {
    final tempDir = Directory.systemTemp.createTempSync('attn_test_');
    final iconFile = File('${tempDir.path}/icon.png');
    final attnDir = Directory('${tempDir.path}/attn');
    attnDir.createSync();
    final attnFile = File('${attnDir.path}/attn.png');
    iconFile.createSync();
    attnFile.createSync();

    var indicator = AppIndicator(id: 'attn-test');

    // Set iconName
    indicator.iconName = iconFile.path;
    expect(indicator.iconThemePath, equals(tempDir.path));

    // Set attentionIconName
    indicator.attentionIconName = attnFile.path;
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

    tempDir.deleteSync(recursive: true);
  });
}
