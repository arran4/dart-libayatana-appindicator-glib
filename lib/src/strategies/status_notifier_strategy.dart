import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dbus/dbus.dart';

import '../common.dart';
import '../dbus_menu.dart' as dm;
import '../enums.dart';
import '../status_notifier_item.dart';
import '../status_notifier_watcher.dart';
import 'indicator_strategy.dart';

class StatusNotifierStrategy implements IndicatorStrategy {
  final String id;
  final DBusClient _client;
  final bool _ownsClient;
  final String _serviceName;
  final _StatusNotifierObject _object;
  String? _registeredItemId;
  bool _isConnected = false;
  final List<_PendingSignal> _pendingSignals = [];

  StatusNotifierStrategy({
    required this.id,
    required AppIndicatorCategory category,
    DBusClient? client,
    String? iconName,
  })  : _client = client ?? DBusClient.session(),
        _ownsClient = client == null,
        _object = _StatusNotifierObject(_buildObjectPath(id)),
        _serviceName = _buildServiceName(id) {
    _object.id = id;
    _object.category = category.name;
    _object.status = AppIndicatorStatus.passive.name;
    _object.attentionIconName = '';
    _object.menu = _object.path; // Canonical DBusMenu on same path
    _object.itemIsMenu = true;

    if (iconName != null) {
      updateIconName(iconName);
    }
  }

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

    stderr.writeln('[debug] StatusNotifierStrategy.connect: '
        'client=${_client.hashCode} service=$_serviceName');
    await _client.requestName(_serviceName);
    _isConnected = true;
    await _flushPendingSignals();
    await _object.emitNewIcon();

    _client.registerObject(_object);

    // Probe for StatusNotifierWatcher
    final watchers = <StatusNotifierWatcher>[];
    if (watcherName != null && watcherPath != null) {
      watchers.add(StatusNotifierWatcher(_client, watcherName,
          path: DBusObjectPath(watcherPath)));
    } else {
      watchers
          .add(StatusNotifierWatcher(_client, 'org.kde.StatusNotifierWatcher'));
      watchers.add(StatusNotifierWatcher(
          _client, 'org.freedesktop.StatusNotifierWatcher',
          path: const DBusObjectPath.unchecked(
              '/org/freedesktop/StatusNotifierWatcher')));
    }

    for (final watcher in watchers) {
      try {
        await _registerWithWatcher(watcher);
        return;
      } catch (e) {
        stderr.writeln('[warn] StatusNotifierStrategy: Failed to register with watcher ${watcher.name}: $e');
      }
    }
  }

  Future<void> _registerWithWatcher(StatusNotifierWatcher watcher) async {
    final pathStr = _object.path.value;
    final registrationTargets = <String>[
      _serviceName,
      pathStr,
      '$_serviceName$pathStr',
    ];

    Object? lastError;
    for (final target in registrationTargets) {
      try {
        await watcher.callRegisterStatusNotifierItem(target);
        _registeredItemId = target;
        return;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  @override
  Future<void> close() async {
    if (!_isConnected) return;

    _client.unregisterObject(_object);
    try {
      await _client.releaseName(_serviceName);
    } catch (_) {}

    if (_ownsClient) {
      await _client.close();
    }
    _isConnected = false;
  }

  void _queueSignal(_PendingSignal signal) {
    if (!_isConnected) {
      _pendingSignals.add(signal);
      return;
    }
    _emitSignal(signal);
  }

  Future<void> _flushPendingSignals() async {
    for (final signal in _pendingSignals) {
      await _emitSignal(signal);
    }
    _pendingSignals.clear();
  }

  Future<void> _emitSignal(_PendingSignal signal) async {
    switch (signal) {
      case _PendingSignal.newStatus:
        await _object.emitNewStatus(_object.status);
      case _PendingSignal.newIcon:
        await _object.emitNewIcon();
      case _PendingSignal.newAttentionIcon:
        await _object.emitNewAttentionIcon();
      case _PendingSignal.newOverlayIcon:
        await _object.emitNewOverlayIcon();
      case _PendingSignal.newAttentionMovie:
        await _object.emitNewAttentionMovie();
      case _PendingSignal.newTitle:
        await _object.emitNewTitle();
      case _PendingSignal.newLabel:
        await _object.emitXAyatanaNewLabel(
            _object.xAyatanaLabel, _object.xAyatanaLabelGuide);
      case _PendingSignal.newIconThemePath:
        await _object.emitNewIconThemePath(_object.iconThemePath);
      case _PendingSignal.newToolTip:
        await _object.emitNewToolTip();
    }
  }

  // Properties

  @override
  Future<void> updateStatus(AppIndicatorStatus status) async {
    _object.status = status.name;
    _queueSignal(_PendingSignal.newStatus);
  }

  @override
  Future<void> updateIconName(String iconName) async {
    _object.iconName = iconName;
    _queueSignal(_PendingSignal.newIcon);
  }

  @override
  Future<void> updateAttentionIconName(String iconName) async {
    _object.attentionIconName = iconName;
    _queueSignal(_PendingSignal.newAttentionIcon);
  }

  @override
  Future<void> updateIconThemePath(String iconThemePath) async {
    _object.iconThemePath = iconThemePath;
    _queueSignal(_PendingSignal.newIconThemePath);
  }

  @override
  Future<void> updateTitle(String title) async {
    _object.title = title;
    _queueSignal(_PendingSignal.newTitle);
  }

  @override
  Future<void> updateLabel(String label, String guide) async {
    _object.xAyatanaLabel = label;
    _object.xAyatanaLabelGuide = guide;
    _queueSignal(_PendingSignal.newLabel);
  }

  @override
  Future<void> updateTooltip(String title, String description) async {
    _object.toolTipTitle = title;
    _object.toolTipDescription = description;
    _queueSignal(_PendingSignal.newToolTip);
  }

  @override
  Future<void> updateItemIsMenu(bool itemIsMenu) async {
    _object.itemIsMenu = itemIsMenu;
  }

  @override
  Future<void> updateWindowId(int windowId) async {
    _object.windowId = windowId;
  }

  @override
  Future<void> updateIconPixmaps(List<IconPixmap> pixmaps) async {
    _object.iconPixmap = pixmaps.map((v) => v.toDBus()).toList();
    _queueSignal(_PendingSignal.newIcon);
  }

  @override
  Future<void> updateAttentionIconPixmaps(List<IconPixmap> pixmaps) async {
    _object.attentionIconPixmap = pixmaps.map((v) => v.toDBus()).toList();
    _queueSignal(_PendingSignal.newAttentionIcon);
  }

  @override
  Future<void> updateOverlayIconName(String iconName) async {
    _object.overlayIconName = iconName;
    _queueSignal(_PendingSignal.newOverlayIcon);
  }

  @override
  Future<void> updateOverlayIconPixmaps(List<IconPixmap> pixmaps) async {
    _object.overlayIconPixmap = pixmaps.map((v) => v.toDBus()).toList();
    _queueSignal(_PendingSignal.newOverlayIcon);
  }

  @override
  Future<void> updateAttentionMovieName(String movieName) async {
    _object.attentionMovieName = movieName;
    _queueSignal(_PendingSignal.newAttentionMovie);
  }

  @override
  void updateMenu(List<dm.DBusMenuItem> items) {
    _object.menuImpl.updateItems(items);
  }

  @override
  bool get isWatcherAvailable => _registeredItemId != null;

  @override
  Future<bool> isStatusNotifierHostRegistered() async {
    try {
      final response = await _client.callMethod(
        destination: 'org.freedesktop.DBus',
        path: DBusObjectPath('/org/freedesktop/DBus'),
        interface: 'org.freedesktop.DBus',
        name: 'NameHasOwner',
        values: [DBusString('org.kde.StatusNotifierWatcher')],
      );
      return response.values.first.asBoolean();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> validate() async {
    final errors = <String>[];
    if (_object.iconName.isEmpty) {
      errors.add('Icon name is empty');
    }
    return errors;
  }

  // Event setters
  @override
  set onScroll(void Function(int delta, String orientation)? callback) {
    _object.onScroll = callback;
  }

  @override
  set onSecondaryActivate(void Function(int x, int y)? callback) {
    _object.onSecondaryActivate = callback;
  }

  @override
  set onXAyatanaSecondaryActivate(void Function(int timestamp)? callback) {
    _object.onXAyatanaSecondaryActivate = callback;
  }

  @override
  set onActivate(void Function(int x, int y)? callback) {
    _object.onActivate = callback;
  }

  @override
  set onContextMenu(void Function(int x, int y)? callback) {
    _object.onContextMenu = callback;
  }

  @override
  set onXAyatanaActivate(void Function(int x, int y, int timestamp)? callback) {
    _object.onXAyatanaActivate = callback;
  }

  // Testing helpers
  @override
  Future<void> dispatchActivate({int x = 0, int y = 0}) async {
    await _object.doActivate(x, y);
  }

  @override
  Future<void> dispatchSecondaryActivate({int x = 0, int y = 0}) async {
    await _object.doSecondaryActivate(x, y);
  }

  @override
  Future<void> dispatchContextMenu({int x = 0, int y = 0}) async {
    await _object.doContextMenu(x, y);
  }

  @override
  Future<void> dispatchScroll(
      {int delta = 0, String orientation = 'vertical'}) async {
    await _object.doScroll(delta, orientation);
  }
}

enum _PendingSignal {
  newStatus,
  newIcon,
  newAttentionIcon,
  newOverlayIcon,
  newAttentionMovie,
  newTitle,
  newLabel,
  newIconThemePath,
  newToolTip,
}

class _StatusNotifierObject extends StatusNotifierItem {
  final dm.DBusMenu menuImpl;

  void Function(int, String)? onScroll;
  void Function(int, int)? onSecondaryActivate;
  void Function(int)? onXAyatanaSecondaryActivate;
  void Function(int, int)? onActivate;
  void Function(int, int)? onContextMenu;
  void Function(int, int, int)? onXAyatanaActivate;

  _StatusNotifierObject(DBusObjectPath path)
      : menuImpl = dm.DBusMenu(path, []),
        super(path: path);

  @override
  List<DBusIntrospectInterface> introspect() {
    final interfaces = super.introspect();
    interfaces.addAll(menuImpl.introspect());
    return interfaces;
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierItem' ||
        methodCall.interface == 'org.freedesktop.StatusNotifierItem') {
      return super.handleMethodCall(methodCall);
    } else if (methodCall.interface == 'com.canonical.dbusmenu') {
      return menuImpl.handleMethodCall(methodCall);
    }
    return DBusMethodErrorResponse.unknownInterface();
  }

  @override
  Future<DBusMethodResponse> doActivate(int x, int y) async {
    onActivate?.call(x, y);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doSecondaryActivate(int x, int y) async {
    onSecondaryActivate?.call(x, y);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doScroll(int delta, String orientation) async {
    onScroll?.call(delta, orientation);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doContextMenu(int x, int y) async {
    onContextMenu?.call(x, y);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doXAyatanaActivate(
      int x, int y, int timestamp) async {
    onXAyatanaActivate?.call(x, y, timestamp);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doXAyatanaSecondaryActivate(int timestamp) async {
    onXAyatanaSecondaryActivate?.call(timestamp);
    return DBusMethodSuccessResponse([]);
  }

  String get toolTipTitle => (toolTip.children[2] as DBusString).value;
  set toolTipTitle(String value) {
    toolTip = DBusStruct([
      toolTip.children[0],
      toolTip.children[1],
      DBusString(value),
      toolTip.children[3],
    ]);
  }

  String get toolTipDescription => (toolTip.children[3] as DBusString).value;
  set toolTipDescription(String value) {
    toolTip = DBusStruct([
      toolTip.children[0],
      toolTip.children[1],
      toolTip.children[2],
      DBusString(value),
    ]);
  }

  Future<void> emitNewOverlayIcon() async {
    await emitSignal('org.kde.StatusNotifierItem', 'NewOverlayIcon', []);
    await emitSignal(
        'org.freedesktop.StatusNotifierItem', 'NewOverlayIcon', []);
  }

  @override
  Future<void> emitNewAttentionIcon() async {
    await emitSignal('org.kde.StatusNotifierItem', 'NewAttentionIcon', []);
    await emitSignal(
        'org.freedesktop.StatusNotifierItem', 'NewAttentionIcon', []);
  }

  Future<void> emitNewAttentionMovie() async {
    await emitSignal('org.kde.StatusNotifierItem', 'NewAttentionMovie', []);
    await emitSignal(
        'org.freedesktop.StatusNotifierItem', 'NewAttentionMovie', []);
  }
}
