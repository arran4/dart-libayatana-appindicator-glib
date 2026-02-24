import 'package:ayatana_appindicator/src/status_notifier_watcher_server.dart';
import 'package:dbus/dbus.dart';

class MockWatcher extends StatusNotifierWatcher {
  final List<String> registeredItems = [];
  final List<String> unregisteredItems = [];

  MockWatcher({String path = '/StatusNotifierWatcher'})
      : super(path: DBusObjectPath(path));

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierItem(
      String service) async {
    registeredItems.add(service);
    await emitStatusNotifierItemRegistered(service);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierHost(
      String service) async {
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierWatcher' &&
        methodCall.name == 'UnregisterStatusNotifierItem') {
      if (methodCall.signature != DBusSignature('s')) {
        return DBusMethodErrorResponse.invalidArgs();
      }

      final service = methodCall.values[0].asString();
      unregisteredItems.add(service);
      registeredItems.remove(service);
      await emitStatusNotifierItemUnregistered(service);
      return DBusMethodSuccessResponse([]);
    }

    return super.handleMethodCall(methodCall);
  }

  @override
  Future<DBusMethodResponse> getProtocolVersion() async {
    return DBusMethodSuccessResponse([DBusInt32(0)]);
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.kde.StatusNotifierWatcher') {
      if (name == 'ProtocolVersion') {
        return DBusMethodSuccessResponse([DBusVariant(DBusInt32(0))]);
      } else if (name == 'IsStatusNotifierHostRegistered') {
        return DBusMethodSuccessResponse([DBusVariant(DBusBoolean(false))]);
      } else if (name == 'RegisteredStatusNotifierItems') {
        return DBusMethodSuccessResponse(
            [DBusVariant(DBusArray.string(registeredItems))]);
      }
    }
    return super.getProperty(interface, name);
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
