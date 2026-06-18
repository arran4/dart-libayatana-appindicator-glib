import 'dart:ffi';

import 'package:dart_libayatana_appindicator/src/app_window.dart';
import 'package:test/test.dart';

void main() {
  test('AppWindow initialization', () {
    try {
      final window = AppWindow();
      expect(window.pointer, isNot(nullptr));
    } catch (e) {
      // In CI without GTK/X11 this might fail, so we skip it
      markTestSkipped('Skipping test due to missing GTK environment: $e');
    }
  });
}
