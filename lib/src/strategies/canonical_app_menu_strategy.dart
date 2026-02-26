import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dbus/dbus.dart';

import '../common.dart';
import '../dbus_menu.dart' as dm;
import '../enums.dart';
import 'indicator_strategy.dart';

class CanonicalAppMenuStrategy implements IndicatorStrategy {
  final String id;
  final DBusClient _client;
  final bool _ownsClient;
  final String _serviceName;
  final dm.DBusMenu _menu;
  bool _isConnected = false;
  int _windowId = 0;

  CanonicalAppMenuStrategy({
    required this.id,
    DBusClient? client,
  })  : _client = client ?? DBusClient.session(),
        _ownsClient = client == null,
        _menu = dm.DBusMenu(_buildObjectPath(id), []),
        _serviceName = _buildServiceName(id);

  static String _sanitizeId(String id) {
    var sanitized = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    if (sanitized.isEmpty || sanitized.replaceAll('_', '').isEmpty) {
      final hash = md5.convert(utf8.encode(id)).toString().substring(0, 8);
      return 'indicator_$hash';
    }
    if (sanitized.startsWith(RegExp(r'[0-9]'))) {
      return 'indicator_$sanitized';
    }
    return sanitized;
  }

  static DBusObjectPath _buildObjectPath(String id) {
    return DBusObjectPath('/org/ayatana/appindicator/${_sanitizeId(id)}');
  }

  static String _buildServiceName(String id) {
    final rand = Random().nextInt(1000000);
    return 'org.ayatana.appindicator.${_sanitizeId(id)}.p$pid.v$rand';
  }

  @override
  Future<void> connect({String? watcherName, String? watcherPath}) async {
    if (_isConnected) return;

    stderr.writeln('[debug] CanonicalAppMenuStrategy.connect: '
        'client=${_client.hashCode} service=$_serviceName windowId=$_windowId');
    await _client.requestName(_serviceName);
    _isConnected = true;

    _client.registerObject(_menu);

    if (_windowId > 0) {
      await _registerWithRegistrar();
    }
  }

  Future<void> _registerWithRegistrar() async {
    try {
      await _client.callMethod(
        destination: 'com.canonical.AppMenu.Registrar',
        path: DBusObjectPath('/com/canonical/AppMenu/Registrar'),
        interface: 'com.canonical.AppMenu.Registrar',
        name: 'RegisterWindow',
        values: [DBusUint32(_windowId), _menu.path],
      );
    } catch (e) {
      stderr.writeln(
          '[warn] CanonicalAppMenuStrategy: Failed to register with Registrar: $e');
    }
  }

  @override
  Future<void> close() async {
    if (!_isConnected) return;

    // Unregister window?
    if (_windowId > 0) {
      try {
        await _client.callMethod(
          destination: 'com.canonical.AppMenu.Registrar',
          path: DBusObjectPath('/com/canonical/AppMenu/Registrar'),
          interface: 'com.canonical.AppMenu.Registrar',
          name: 'UnregisterWindow',
          values: [DBusUint32(_windowId)],
        );
      } catch (_) {}
    }

    _client.unregisterObject(_menu);
    try {
      await _client.releaseName(_serviceName);
    } catch (_) {}

    if (_ownsClient) {
      await _client.close();
    }
    _isConnected = false;
  }

  @override
  Future<void> updateWindowId(int windowId) async {
    if (_windowId == windowId) return;

    // Unregister old window if connected
    if (_isConnected && _windowId > 0) {
       try {
        await _client.callMethod(
          destination: 'com.canonical.AppMenu.Registrar',
          path: DBusObjectPath('/com/canonical/AppMenu/Registrar'),
          interface: 'com.canonical.AppMenu.Registrar',
          name: 'UnregisterWindow',
          values: [DBusUint32(_windowId)],
        );
      } catch (_) {}
    }

    _windowId = windowId;

    // Register new window if connected
    if (_isConnected && _windowId > 0) {
      await _registerWithRegistrar();
    }
  }

  // Ignored properties
  @override
  Future<void> updateStatus(AppIndicatorStatus status) async {}
  @override
  Future<void> updateIconName(String iconName) async {}
  @override
  Future<void> updateAttentionIconName(String iconName) async {}
  @override
  Future<void> updateIconThemePath(String iconThemePath) async {}
  @override
  Future<void> updateTitle(String title) async {}
  @override
  Future<void> updateLabel(String label, String guide) async {}
  @override
  Future<void> updateTooltip(String title, String description) async {}
  @override
  Future<void> updateItemIsMenu(bool itemIsMenu) async {}

  @override
  Future<void> updateIconPixmaps(List<IconPixmap> pixmaps) async {}
  @override
  Future<void> updateAttentionIconPixmaps(List<IconPixmap> pixmaps) async {}
  @override
  Future<void> updateOverlayIconName(String iconName) async {}
  @override
  Future<void> updateOverlayIconPixmaps(List<IconPixmap> pixmaps) async {}
  @override
  Future<void> updateAttentionMovieName(String movieName) async {}

  @override
  void updateMenu(List<dm.DBusMenuItem> items) {
    _menu.updateItems(items);
  }

  @override
  bool get isWatcherAvailable => false;

  @override
  Future<bool> isStatusNotifierHostRegistered() async {
    return false;
  }

  @override
  Future<List<String>> validate() async {
    final errors = <String>[];
    if (_menu.items.isEmpty) {
      errors.add('Menu is empty');
    }
    if (_windowId <= 0) {
      errors.add('Window ID is invalid');
    }
    return errors;
  }

  @override
  set onScroll(void Function(int delta, String orientation)? callback) {}
  @override
  set onSecondaryActivate(void Function(int x, int y)? callback) {}
  @override
  set onXAyatanaSecondaryActivate(void Function(int timestamp)? callback) {}
  @override
  set onActivate(void Function(int x, int y)? callback) {}
  @override
  set onContextMenu(void Function(int x, int y)? callback) {}
  @override
  set onXAyatanaActivate(void Function(int x, int y, int timestamp)? callback) {}

  @override
  Future<void> dispatchActivate({int x = 0, int y = 0}) async {}
  @override
  Future<void> dispatchSecondaryActivate({int x = 0, int y = 0}) async {}
  @override
  Future<void> dispatchContextMenu({int x = 0, int y = 0}) async {}
  @override
  Future<void> dispatchScroll(
      {int delta = 0, String orientation = 'vertical'}) async {}
}
