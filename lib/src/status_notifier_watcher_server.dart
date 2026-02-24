// This file was generated using the following command and may be overwritten.
// dart-dbus generate-object notification-watcher.xml

import 'package:dbus/dbus.dart';

class StatusNotifierWatcher extends DBusObject {
  /// Creates a new object to expose on [path].
  StatusNotifierWatcher({DBusObjectPath path = const DBusObjectPath.unchecked('/StatusNotifierWatcher')}) : super(path);

  /// Gets value of property org.kde.StatusNotifierWatcher.ProtocolVersion
  Future<DBusMethodResponse> getProtocolVersion() async {
    return DBusMethodErrorResponse.failed('Get org.kde.StatusNotifierWatcher.ProtocolVersion not implemented');
  }

  /// Gets value of property org.kde.StatusNotifierWatcher.IsStatusNotifierHostRegistered
  Future<DBusMethodResponse> getIsStatusNotifierHostRegistered() async {
    return DBusMethodErrorResponse.failed('Get org.kde.StatusNotifierWatcher.IsStatusNotifierHostRegistered not implemented');
  }

  /// Gets value of property org.kde.StatusNotifierWatcher.RegisteredStatusNotifierItems
  Future<DBusMethodResponse> getRegisteredStatusNotifierItems() async {
    return DBusMethodErrorResponse.failed('Get org.kde.StatusNotifierWatcher.RegisteredStatusNotifierItems not implemented');
  }

  /// Implementation of org.kde.StatusNotifierWatcher.RegisterStatusNotifierItem()
  Future<DBusMethodResponse> doRegisterStatusNotifierItem(String service) async {
    return DBusMethodErrorResponse.failed('org.kde.StatusNotifierWatcher.RegisterStatusNotifierItem() not implemented');
  }

  /// Implementation of org.kde.StatusNotifierWatcher.RegisterStatusNotifierHost()
  Future<DBusMethodResponse> doRegisterStatusNotifierHost(String service) async {
    return DBusMethodErrorResponse.failed('org.kde.StatusNotifierWatcher.RegisterStatusNotifierHost() not implemented');
  }

  /// Emits signal org.kde.StatusNotifierWatcher.StatusNotifierItemRegistered
  Future<void> emitStatusNotifierItemRegistered(String service) async {
     await emitSignal('org.kde.StatusNotifierWatcher', 'StatusNotifierItemRegistered', [DBusString(service)]);
  }

  /// Emits signal org.kde.StatusNotifierWatcher.StatusNotifierItemUnregistered
  Future<void> emitStatusNotifierItemUnregistered(String service) async {
     await emitSignal('org.kde.StatusNotifierWatcher', 'StatusNotifierItemUnregistered', [DBusString(service)]);
  }

  /// Emits signal org.kde.StatusNotifierWatcher.StatusNotifierHostRegistered
  Future<void> emitStatusNotifierHostRegistered() async {
     await emitSignal('org.kde.StatusNotifierWatcher', 'StatusNotifierHostRegistered', []);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [DBusIntrospectInterface('org.kde.StatusNotifierWatcher', methods: [DBusIntrospectMethod('RegisterStatusNotifierItem', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'service')]), DBusIntrospectMethod('RegisterStatusNotifierHost', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'service')])], signals: [DBusIntrospectSignal('StatusNotifierItemRegistered', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out, name: 'service')]), DBusIntrospectSignal('StatusNotifierItemUnregistered', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out, name: 'service')]), DBusIntrospectSignal('StatusNotifierHostRegistered')], properties: [DBusIntrospectProperty('ProtocolVersion', DBusSignature('i'), access: DBusPropertyAccess.read), DBusIntrospectProperty('IsStatusNotifierHostRegistered', DBusSignature('b'), access: DBusPropertyAccess.read), DBusIntrospectProperty('RegisteredStatusNotifierItems', DBusSignature('as'), access: DBusPropertyAccess.read)])];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierWatcher') {
      if (methodCall.name == 'RegisterStatusNotifierItem') {
        if (methodCall.signature != DBusSignature('s')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doRegisterStatusNotifierItem(methodCall.values[0].asString());
      } else if (methodCall.name == 'RegisterStatusNotifierHost') {
        if (methodCall.signature != DBusSignature('s')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doRegisterStatusNotifierHost(methodCall.values[0].asString());
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.kde.StatusNotifierWatcher') {
      if (name == 'ProtocolVersion') {
        return getProtocolVersion();
      } else if (name == 'IsStatusNotifierHostRegistered') {
        return getIsStatusNotifierHostRegistered();
      } else if (name == 'RegisteredStatusNotifierItems') {
        return getRegisteredStatusNotifierItems();
      } else {
        return DBusMethodErrorResponse.unknownProperty();
      }
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> setProperty(String interface, String name, DBusValue value) async {
    if (interface == 'org.kde.StatusNotifierWatcher') {
      if (name == 'ProtocolVersion') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'IsStatusNotifierHostRegistered') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'RegisteredStatusNotifierItems') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else {
        return DBusMethodErrorResponse.unknownProperty();
      }
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{};
    if (interface == 'org.kde.StatusNotifierWatcher') {
      properties['ProtocolVersion'] = (await getProtocolVersion()).returnValues[0];
      properties['IsStatusNotifierHostRegistered'] = (await getIsStatusNotifierHostRegistered()).returnValues[0];
      properties['RegisteredStatusNotifierItems'] = (await getRegisteredStatusNotifierItems()).returnValues[0];
    }
    return DBusMethodSuccessResponse([DBusDict.stringVariant(properties)]);
  }
}
