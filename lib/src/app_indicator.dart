import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dbus/dbus.dart';

import 'dbus_menu.dart' as dm;
import 'enums.dart';
import 'status_notifier_item.dart';
import 'status_notifier_watcher.dart';

export 'dbus_menu.dart' show DBusMenuItem;
export 'enums.dart';

/// Event arguments for scroll events.
class ScrollEvent {
  final int delta;
  final String orientation;

  const ScrollEvent(this.delta, this.orientation);
}

/// Event arguments for secondary activation.
class SecondaryActivateEvent {
  final int x;
  final int y;
  final int timestamp;

  const SecondaryActivateEvent(this.x, this.y, [this.timestamp = 0]);
}

/// Event arguments for primary activation.
class ActivateEvent {
  final int x;
  final int y;

  const ActivateEvent(this.x, this.y);
}

/// Event arguments for context menu activation.
class ContextMenuEvent {
  final int x;
  final int y;

  const ContextMenuEvent(this.x, this.y);
}

/// Event arguments for XAyatana primary activation.
class XAyatanaActivateEvent {
  final int x;
  final int y;
  final int timestamp;

  const XAyatanaActivateEvent(this.x, this.y, this.timestamp);
}

/// A structure representing a pixel map of an icon.
class IconPixmap {
  final int width;
  final int height;
  final List<int> argb32Bytes;

  const IconPixmap({
    required this.width,
    required this.height,
    required this.argb32Bytes,
  });

  DBusValue toDBus() {
    return DBusStruct([
      DBusInt32(width),
      DBusInt32(height),
      DBusArray.byte(argb32Bytes),
    ]);
  }
}

/// A port of Ayatana AppIndicator to Dart.
class AppIndicator {
  final String id;
  final AppIndicatorCategory category;

  final String _serviceName;
  bool _isConnected = false;
  final List<_PendingSignal> _pendingSignals = [];

  final DBusClient _client;
  final bool _ownsClient;
  final _AppIndicatorObject _object;
  String? _registeredItemId;

  String _rawIconName = '';
  String _rawAttentionIconName = '';
  String _manualIconThemePath = '';

  // Stream controllers
  final _scrollController = StreamController<ScrollEvent>.broadcast();
  final _secondaryActivateController =
      StreamController<SecondaryActivateEvent>.broadcast();
  final _activateController = StreamController<ActivateEvent>.broadcast();
  final _contextMenuController = StreamController<ContextMenuEvent>.broadcast();
  final _xAyatanaActivateController =
      StreamController<XAyatanaActivateEvent>.broadcast();

  // Callbacks
  void Function(int x, int y)? onActivate;
  void Function(int x, int y)? onSecondaryActivate;
  void Function(int x, int y)? onContextMenu;
  void Function(int delta, String orientation)? onScroll;

  AppIndicator({
    required this.id,
    String iconName = '',
    this.category = AppIndicatorCategory.applicationStatus,
    DBusClient? client,
  })  : _client = client ?? DBusClient.session(),
        _ownsClient = client == null,
        _object = _AppIndicatorObject(_buildObjectPath(id)),
        _serviceName = _buildServiceName(id) {
    _object.id = id;
    _object.category = category.name;
    _object.status = AppIndicatorStatus.passive.name;
    _object.attentionIconName = '';
    _object.menu = _object.path; // Canonical DBusMenu on same path
    _object.itemIsMenu = true;

    this.iconName = iconName;

    // Connect object events to public streams and callbacks
    _object.onScroll = (delta, orientation) {
      onScroll?.call(delta, orientation);
      _scrollController.add(ScrollEvent(delta, orientation));
    };

    _object.onSecondaryActivate = (x, y) {
      onSecondaryActivate?.call(x, y);
      _secondaryActivateController.add(SecondaryActivateEvent(x, y));
    };

    _object.onXAyatanaSecondaryActivate = (timestamp) {
      onSecondaryActivate?.call(0, 0);
      _secondaryActivateController.add(SecondaryActivateEvent(0, 0, timestamp));
    };

    _object.onActivate = (x, y) {
      onActivate?.call(x, y);
      _activateController.add(ActivateEvent(x, y));
    };

    _object.onContextMenu = (x, y) {
      onContextMenu?.call(x, y);
      _contextMenuController.add(ContextMenuEvent(x, y));
    };

    _object.onXAyatanaActivate = (x, y, timestamp) {
      onActivate?.call(x, y);
      _xAyatanaActivateController.add(XAyatanaActivateEvent(x, y, timestamp));
    };
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

  Future<void> connect({String? watcherName, String? watcherPath}) async {
    if (_isConnected) return;

    stderr.writeln('[debug] AppIndicator.connect: '
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
      } catch (_) {
        // Fallback to next watcher
      }
    }
  }

  Future<void> _registerWithWatcher(StatusNotifierWatcher watcher) async {
    final pathStr = _object.path
        .toString()
        .replaceAll('DBusObjectPath(\'', '')
        .replaceAll('\')', '');
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

  Future<void> close() async {
    if (!_isConnected) return;

    // Unregister object and release name instead of closing client if we don't
    // own it
    _client.unregisterObject(_object);
    try {
      await _client.releaseName(_serviceName);
    } catch (_) {}

    if (_ownsClient) {
      await _client.close();
    }
    _isConnected = false;
  }

  // Properties mapping
  String get title => _object.title;
  set title(String value) {
    _object.title = value;
    _queueSignal(_PendingSignal.newTitle);
  }

  String get label => _object.xAyatanaLabel;
  set label(String value) {
    _object.xAyatanaLabel = value;
    _queueSignal(_PendingSignal.newLabel);
  }

  String get labelGuide => _object.xAyatanaLabelGuide;
  set labelGuide(String value) {
    _object.xAyatanaLabelGuide = value;
    _queueSignal(_PendingSignal.newLabel);
  }

  AppIndicatorStatus get status =>
      AppIndicatorStatus.values.firstWhere((e) => e.name == _object.status);
  set status(AppIndicatorStatus value) {
    _object.status = value.name;
    _updatePaths();
    _queueSignal(_PendingSignal.newStatus);
  }

  String get iconName => _rawIconName;
  set iconName(String value) {
    _rawIconName = value;
    _updatePaths();
    _queueSignal(_PendingSignal.newIcon);
  }

  String get attentionIconName => _rawAttentionIconName;
  set attentionIconName(String value) {
    _rawAttentionIconName = value;
    _updatePaths();
    _queueSignal(_PendingSignal.newAttentionIcon);
  }

  String get iconThemePath => _manualIconThemePath.isNotEmpty
      ? _manualIconThemePath
      : _object.iconThemePath;
  set iconThemePath(String value) {
    _manualIconThemePath = value;
    _object.iconThemePath = value;
    _queueSignal(_PendingSignal.newIconThemePath);
  }

  void _updatePaths() {
    final currentIcon = (status == AppIndicatorStatus.attention)
        ? (_rawAttentionIconName.isNotEmpty
            ? _rawAttentionIconName
            : _rawIconName)
        : _rawIconName;

    if (currentIcon.startsWith('/')) {
      final lastSlash = currentIcon.lastIndexOf('/');
      final dir = currentIcon.substring(0, lastSlash);
      _object.iconThemePath = dir;
    }

    // Update DBus names
    _object.iconName = _processIconName(_rawIconName);
    _object.attentionIconName = _processIconName(_rawAttentionIconName);
  }

  String _processIconName(String name) {
    if (name.startsWith('/')) {
      final lastSlash = name.lastIndexOf('/');
      var base = name.substring(lastSlash + 1);
      if (base.contains('.')) {
        base = base.substring(0, base.lastIndexOf('.'));
      }
      return base;
    }
    return name;
  }

  String get tooltipTitle => _object.toolTipTitle;
  set tooltipTitle(String value) {
    _object.toolTipTitle = value;
    _queueSignal(_PendingSignal.newToolTip);
  }

  String get tooltipDescription => _object.toolTipDescription;
  set tooltipDescription(String description) {
    _object.toolTipDescription = description;
    _queueSignal(_PendingSignal.newToolTip);
  }

  bool get itemIsMenu => _object.itemIsMenu;
  set itemIsMenu(bool value) {
    _object.itemIsMenu = value;
  }

  int get windowId => _object.windowId;
  set windowId(int value) {
    _object.windowId = value;
  }

  List<IconPixmap> get iconPixmaps => _object.iconPixmap.map((v) {
        final s = v as DBusStruct;
        return IconPixmap(
          width: s.children[0].asInt32(),
          height: s.children[1].asInt32(),
          argb32Bytes: s.children[2].asByteArray().toList(),
        );
      }).toList();
  set iconPixmaps(List<IconPixmap> value) {
    _object.iconPixmap = value.map((v) => v.toDBus()).toList();
    _queueSignal(_PendingSignal.newIcon);
  }

  List<IconPixmap> get attentionIconPixmaps =>
      _object.attentionIconPixmap.map((v) {
        final s = v as DBusStruct;
        return IconPixmap(
          width: s.children[0].asInt32(),
          height: s.children[1].asInt32(),
          argb32Bytes: s.children[2].asByteArray().toList(),
        );
      }).toList();
  set attentionIconPixmaps(List<IconPixmap> value) {
    _object.attentionIconPixmap = value.map((v) => v.toDBus()).toList();
    _queueSignal(_PendingSignal.newAttentionIcon);
  }

  String get overlayIconName => _object.overlayIconName;
  set overlayIconName(String value) {
    _object.overlayIconName = value;
    _queueSignal(_PendingSignal.newOverlayIcon);
  }

  List<IconPixmap> get overlayIconPixmaps => _object.overlayIconPixmap.map((v) {
        final s = v as DBusStruct;
        return IconPixmap(
          width: s.children[0].asInt32(),
          height: s.children[1].asInt32(),
          argb32Bytes: s.children[2].asByteArray().toList(),
        );
      }).toList();
  set overlayIconPixmaps(List<IconPixmap> value) {
    _object.overlayIconPixmap = value.map((v) => v.toDBus()).toList();
    _queueSignal(_PendingSignal.newOverlayIcon);
  }

  String get attentionMovieName => _object.attentionMovieName;
  set attentionMovieName(String value) {
    _object.attentionMovieName = value;
    _queueSignal(_PendingSignal.newAttentionMovie);
  }

  void setMenu(List<dm.DBusMenuItem> items) {
    _object.menuImpl.updateItems(items);
  }

  // Events
  Stream<ScrollEvent> get scrollEvents => _scrollController.stream;
  Stream<SecondaryActivateEvent> get secondaryActivateEvents =>
      _secondaryActivateController.stream;
  Stream<ActivateEvent> get activateEvents => _activateController.stream;
  Stream<ContextMenuEvent> get contextMenuEvents =>
      _contextMenuController.stream;
  Stream<XAyatanaActivateEvent> get xAyatanaActivateEvents =>
      _xAyatanaActivateController.stream;

  // Testing helpers
  Future<void> dispatchActivate({int x = 0, int y = 0}) async {
    await _object.doActivate(x, y);
  }

  Future<void> dispatchSecondaryActivate({int x = 0, int y = 0}) async {
    await _object.doSecondaryActivate(x, y);
  }

  Future<void> dispatchContextMenu({int x = 0, int y = 0}) async {
    await _object.doContextMenu(x, y);
  }

  Future<void> dispatchScroll(
      {int delta = 0, String orientation = 'vertical'}) async {
    await _object.doScroll(delta, orientation);
  }

  bool get isWatcherAvailable => _registeredItemId != null;

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

class _AppIndicatorObject extends StatusNotifierItem {
  final dm.DBusMenu menuImpl;

  Function(int, String)? onScroll;
  Function(int, int)? onSecondaryActivate;
  Function(int)? onXAyatanaSecondaryActivate;
  Function(int, int)? onActivate;
  Function(int, int)? onContextMenu;
  Function(int, int, int)? onXAyatanaActivate;

  _AppIndicatorObject(DBusObjectPath path)
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

  Future<void> _emitSignalToBoth(String name,
      [List<DBusValue> values = const []]) async {
    await emitSignal('org.kde.StatusNotifierItem', name, values);
    await emitSignal('org.freedesktop.StatusNotifierItem', name, values);
  }

  Future<void> emitNewOverlayIcon() async {
    await _emitSignalToBoth('NewOverlayIcon');
  }

  @override
  Future<void> emitNewAttentionIcon() async {
    await _emitSignalToBoth('NewAttentionIcon');
  }

  Future<void> emitNewAttentionMovie() async {
    await _emitSignalToBoth('NewAttentionMovie');
  }
}
