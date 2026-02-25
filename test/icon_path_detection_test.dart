@TestOn('linux')
import 'dart:io';

import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';
import 'package:test/test.dart';

void main() {
  test('AppIndicator handles absolute path icon', () {
    final indicator = AppIndicator(id: 'abs-path-test');
    final absPath = '/tmp/icon.png';

    indicator.iconName = absPath;

    expect(indicator.iconThemePath, equals('/tmp'),
        reason: 'Should extract directory from absolute path');
  });

  test('AppIndicator handles relative path icon', () {
    final indicator = AppIndicator(id: 'rel-path-test');
    final relPath = 'assets/icon.png';

    indicator.iconName = relPath;

    // Calculate expected absolute path to 'assets'
    final expectedPath = File(relPath).absolute.parent.path;

    expect(indicator.iconThemePath, equals(expectedPath),
        reason: 'Should extract absolute directory from relative path');
  });

  test('AppIndicator ignores simple icon name', () {
    final indicator = AppIndicator(id: 'simple-name-test');
    final simpleName = 'my-app-icon';

    indicator.iconName = simpleName;

    expect(indicator.iconThemePath, isEmpty,
        reason: 'Should not set theme path for simple icon name');
  });

  test('AppIndicator handles icon in current directory', () {
    final indicator = AppIndicator(id: 'cwd-icon-test');
    final cwdIcon = 'icon.png';

    indicator.iconName = cwdIcon;

    // In current directory, parent path is current directory

    expect(indicator.iconThemePath, isEmpty,
        reason: 'Simple filename without path separators should be '
            'treated as icon name');
  });
}
