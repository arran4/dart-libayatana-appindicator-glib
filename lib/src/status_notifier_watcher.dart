// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object src/notification-watcher.xml

import 'package:dbus/dbus.dart';

/// Signal data for org.kde.StatusNotifierWatcher.StatusNotifierItemRegistered.
class StatusNotifierWatcherStatusNotifierItemRegistered extends DBusSignal {
  String get service => values[0].asString();

  StatusNotifierWatcherStatusNotifierItemRegistered(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}

/// Signal data for
/// org.kde.StatusNotifierWatcher.StatusNotifierItemUnregistered.
class StatusNotifierWatcherStatusNotifierItemUnregistered extends DBusSignal {
  String get service => values[0].asString();

  StatusNotifierWatcherStatusNotifierItemUnregistered(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}

/// Signal data for org.kde.StatusNotifierWatcher.StatusNotifierHostRegistered.
class StatusNotifierWatcherStatusNotifierHostRegistered extends DBusSignal {
  StatusNotifierWatcherStatusNotifierHostRegistered(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}

class StatusNotifierWatcher extends DBusRemoteObject {
  /// Stream of org.kde.StatusNotifierWatcher.StatusNotifierItemRegistered
  /// signals.
  late final Stream<StatusNotifierWatcherStatusNotifierItemRegistered>
      statusNotifierItemRegistered;

  /// Stream of org.kde.StatusNotifierWatcher.StatusNotifierItemUnregistered
  /// signals.
  late final Stream<StatusNotifierWatcherStatusNotifierItemUnregistered>
      statusNotifierItemUnregistered;

  /// Stream of org.kde.StatusNotifierWatcher.StatusNotifierHostRegistered
  /// signals.
  late final Stream<StatusNotifierWatcherStatusNotifierHostRegistered>
      statusNotifierHostRegistered;

  StatusNotifierWatcher(DBusClient client, String destination,
      {DBusObjectPath path =
          const DBusObjectPath.unchecked('/StatusNotifierWatcher')})
      : super(client, name: destination, path: path) {
    statusNotifierItemRegistered = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.kde.StatusNotifierWatcher',
            name: 'StatusNotifierItemRegistered',
            signature: DBusSignature('s'))
        .asBroadcastStream()
        .map((signal) =>
            StatusNotifierWatcherStatusNotifierItemRegistered(signal));

    statusNotifierItemUnregistered = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.kde.StatusNotifierWatcher',
            name: 'StatusNotifierItemUnregistered',
            signature: DBusSignature('s'))
        .asBroadcastStream()
        .map((signal) =>
            StatusNotifierWatcherStatusNotifierItemUnregistered(signal));

    statusNotifierHostRegistered = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.kde.StatusNotifierWatcher',
            name: 'StatusNotifierHostRegistered',
            signature: DBusSignature(''))
        .asBroadcastStream()
        .map((signal) =>
            StatusNotifierWatcherStatusNotifierHostRegistered(signal));
  }

  /// Gets org.kde.StatusNotifierWatcher.ProtocolVersion
  Future<int> getProtocolVersion() async {
    var value = await getProperty(
        'org.kde.StatusNotifierWatcher', 'ProtocolVersion',
        signature: DBusSignature('i'));
    return value.asInt32();
  }

  /// Gets org.kde.StatusNotifierWatcher.IsStatusNotifierHostRegistered
  Future<bool> getIsStatusNotifierHostRegistered() async {
    var value = await getProperty(
        'org.kde.StatusNotifierWatcher', 'IsStatusNotifierHostRegistered',
        signature: DBusSignature('b'));
    return value.asBoolean();
  }

  /// Gets org.kde.StatusNotifierWatcher.RegisteredStatusNotifierItems
  Future<List<String>> getRegisteredStatusNotifierItems() async {
    var value = await getProperty(
        'org.kde.StatusNotifierWatcher', 'RegisteredStatusNotifierItems',
        signature: DBusSignature('as'));
    return value.asStringArray().toList();
  }

  /// Invokes org.kde.StatusNotifierWatcher.RegisterStatusNotifierItem()
  Future<void> callRegisterStatusNotifierItem(String service,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.kde.StatusNotifierWatcher',
        'RegisterStatusNotifierItem', [DBusString(service)],
        replySignature: DBusSignature(''),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.StatusNotifierWatcher.RegisterStatusNotifierHost()
  Future<void> callRegisterStatusNotifierHost(String service,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.kde.StatusNotifierWatcher',
        'RegisterStatusNotifierHost', [DBusString(service)],
        replySignature: DBusSignature(''),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }
}
