import 'package:dart_libayatana_appindicator/dart_libayatana_appindicator.dart';
import 'package:test/test.dart';

void main() {
  test('AppIndicatorRegistrationException toString includes cause', () {
    final cause = Exception('Test cause');
    final stackTrace = StackTrace.current;
    final exception = AppIndicatorRegistrationException(cause, stackTrace);

    expect(
      exception.toString(),
      'AppIndicatorRegistrationException: Failed to register with watcher: Exception: Test cause',
    );
  });
}
