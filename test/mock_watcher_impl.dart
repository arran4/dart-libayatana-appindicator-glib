import 'package:dbus/dbus.dart';
import 'package:ayatana_appindicator/src/status_notifier_watcher_server.dart';

class MockWatcher extends StatusNotifierWatcher {
  final List<String> registeredItems = [];

  MockWatcher() : super(path: DBusObjectPath('/StatusNotifierWatcher'));

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierItem(String service) async {
    registeredItems.add(service);
    await emitStatusNotifierItemRegistered(service);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierHost(String service) async {
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> getProtocolVersion() async {
    return DBusMethodSuccessResponse([DBusInt32(0)]);
  }

  @override
  Future<DBusMethodResponse> getIsStatusNotifierHostRegistered() async {
    return DBusMethodSuccessResponse([DBusBoolean(false)]);
  }

  @override
  Future<DBusMethodResponse> getRegisteredStatusNotifierItems() async {
    return DBusMethodSuccessResponse([DBusArray.string(registeredItems)]);
  }
}

class FlakyMockWatcher extends MockWatcher {
  int remainingFailures;

  FlakyMockWatcher({required this.remainingFailures});

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierItem(String service) async {
    if (remainingFailures > 0) {
      remainingFailures--;
      return DBusMethodErrorResponse(
          'org.freedesktop.DBus.Error.NoReply',
          values: [DBusString('Temporary failure')]);
    }

    return super.doRegisterStatusNotifierItem(service);
  }
}
