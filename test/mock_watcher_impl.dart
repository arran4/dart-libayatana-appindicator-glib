import 'dart:io';

import 'package:dart_libayatana_appindicator/src/status_notifier_watcher_server.dart';
import 'package:dbus/dbus.dart';

class MockWatcher extends StatusNotifierWatcher {
  static final List<String> registeredItems = [];
  static final List<String> unregisteredItems = [];

  MockWatcher({String path = '/StatusNotifierWatcher'})
      : super(path: DBusObjectPath(path));

  @override
  Future<DBusMethodResponse> doRegisterStatusNotifierItem(
      String service) async {
    stderr.writeln('[debug] MockWatcher: Received Register($service)');
    if (!registeredItems.contains(service)) {
      registeredItems.add(service);
      await emitStatusNotifierItemRegistered(service);
    }
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierWatcher' &&
        methodCall.name == 'UnregisterStatusNotifierItem') {
      final service = methodCall.values[0].asString();
      if (!unregisteredItems.contains(service)) {
        unregisteredItems.add(service);
      }
    }
    return super.handleMethodCall(methodCall);
  }
}
