import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';

import 'action_group.dart';
import 'enums.dart';
import 'menu.dart';
import 'status_notifier_item.dart';
import 'status_notifier_watcher.dart';

export 'action_group.dart' show DBusAction;
export 'enums.dart';
export 'menu.dart' show DBusMenuItem;

/// Event arguments for scroll events.
class ScrollEvent {
  final int delta;
  final String orientation;

  ScrollEvent(this.delta, this.orientation);
}

/// Event arguments for secondary activation (middle-click).
class SecondaryActivateEvent {
  final int x;
  final int y;
  final int timestamp;

  SecondaryActivateEvent(this.x, this.y, [this.timestamp = 0]);
}

/// Event arguments for primary activation (left click/tap).
class ActivateEvent {
  final int x;
  final int y;

  const ActivateEvent(this.x, this.y);
}

/// Event arguments for context-menu requests (typically right click).
class ContextMenuEvent {
  final int x;
  final int y;

  const ContextMenuEvent(this.x, this.y);
}

/// One icon frame encoded as ARGB32 bytes for the SNI pixmap properties.
class IconPixmap {
  final int width;
  final int height;
  final List<int> argb32Bytes;

  const IconPixmap({
    required this.width,
    required this.height,
    required this.argb32Bytes,
  });

  DBusStruct toDBus() {
    return DBusStruct([
      DBusInt32(width),
      DBusInt32(height),
      DBusArray.byte(argb32Bytes),
    ]);
  }
}

/// Event arguments for XAyatana primary activation.
class XAyatanaActivateEvent {
  final int x;
  final int y;
  final int timestamp;

  const XAyatanaActivateEvent(this.x, this.y, this.timestamp);
}

/// Error thrown when registering the status notifier item with the watcher fails.
class AppIndicatorRegistrationException implements Exception {
  final Object cause;
  final StackTrace stackTrace;

  AppIndicatorRegistrationException(this.cause, this.stackTrace);

  @override
  String toString() =>
      'AppIndicatorRegistrationException: Failed to register with watcher: $cause';
}

class AppIndicator {
  static const List<_WatcherEndpoint> _watcherEndpoints = [
    _WatcherEndpoint('org.kde.StatusNotifierWatcher', '/StatusNotifierWatcher'),
    _WatcherEndpoint(
        'org.freedesktop.StatusNotifierWatcher', '/StatusNotifierWatcher'),
    _WatcherEndpoint(
        'org.kde.StatusNotifierWatcher', '/org/kde/StatusNotifierWatcher'),
    _WatcherEndpoint('org.freedesktop.StatusNotifierWatcher',
        '/org/freedesktop/StatusNotifierWatcher'),
  ];

  final String id;
  late final String _serviceName;
  final DBusClient _client;
  final _AppIndicatorObject _object;
  StatusNotifierWatcher? _watcher;
  int? _menuGroupId;
  String? _registeredItemId;

  // Stream controllers
  final _scrollController = StreamController<ScrollEvent>.broadcast();
  final _secondaryActivateController =
      StreamController<SecondaryActivateEvent>.broadcast();
  final _activateController = StreamController<ActivateEvent>.broadcast();
  final _contextMenuController = StreamController<ContextMenuEvent>.broadcast();
  final _xAyatanaActivateController =
      StreamController<XAyatanaActivateEvent>.broadcast();
  bool _isConnected = false;
  final Set<_PendingSignal> _pendingSignals = <_PendingSignal>{};

  DateTime? _lastPrimaryActivateAt;
  Duration _doubleClickWindow = const Duration(milliseconds: 350);

  String _manualIconThemePath = '';
  String _iconName = '';
  String _attentionIconName = '';

  AppIndicator(
      {required this.id,
      String iconName = '',
      AppIndicatorCategory category = AppIndicatorCategory.applicationStatus})
      : _client = DBusClient.session(),
        _object = _AppIndicatorObject(
            DBusObjectPath('/org/ayatana/appindicator/${_cleanId(id)}')) {
    _serviceName = _buildServiceName(id);
    _object.id = id;
    _object.category = category.name;
    _object.menu = _object.path; // Menu is on the same object path
    _object.iconThemePath = '';
    _object.title = '';
    _object.status = AppIndicatorStatus.passive.name;
    _object.attentionIconName = '';

    this.iconName = iconName;

    // Connect object events to public streams
    _object.onScroll = (delta, orientation) {
      _scrollController.add(ScrollEvent(delta, orientation));
    };

    _object.onSecondaryActivate = (x, y) {
      _secondaryActivateController.add(SecondaryActivateEvent(x, y));
    };

    _object.onXAyatanaSecondaryActivate = (timestamp) {
      _secondaryActivateController.add(SecondaryActivateEvent(0, 0, timestamp));
    };

    _object.onActivate = (x, y) {
      _activateController.add(ActivateEvent(x, y));
      _maybeDispatchDoubleClick();
    };

    _object.onContextMenu = (x, y) {
      _contextMenuController.add(ContextMenuEvent(x, y));
    };

    _object.onXAyatanaActivate = (x, y, timestamp) {
      _xAyatanaActivateController.add(XAyatanaActivateEvent(x, y, timestamp));
      _maybeDispatchDoubleClick();
    };
  }

  set doubleClickWindow(Duration value) {
    _doubleClickWindow = value;
  }

  static String _cleanId(String id) {
    final sanitized = id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final collapsed = sanitized
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (collapsed.isEmpty) {
      return 'indicator_${_stableHash(id)}';
    }

    if (RegExp(r'^[0-9]').hasMatch(collapsed)) {
      return 'indicator_$collapsed';
    }

    return collapsed;
  }

  static String _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  static bool _looksLikePath(String value) {
    if (value.isEmpty) {
      return false;
    }
    if (value.startsWith('/')) {
      return true;
    }
    if (value.length > 2 && RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value)) {
      return true;
    }
    return value.contains('/');
  }

  static String _buildServiceName(String id) {
    final cleaned = _cleanId(id).toLowerCase();
    return 'org.ayatana.appindicator.$cleaned.p$pid';
  }

  // Properties setters
  AppIndicatorStatus get status {
    switch (_object.status) {
      case 'Active':
        return AppIndicatorStatus.active;
      case 'Attention':
        return AppIndicatorStatus.attention;
      case 'Passive':
      default:
        return AppIndicatorStatus.passive;
    }
  }

  set status(AppIndicatorStatus status) {
    _object.status = status.name;
    _updateIconThemePath();
    _queueSignal(_PendingSignal.newStatus);
  }

  String get iconName => _iconName;

  set iconName(String name) {
    _iconName = name;
    _updateIconProperties(name, isAttention: false);
  }

  set iconPixmaps(List<IconPixmap> pixmaps) {
    _object.iconPixmaps = pixmaps;
    _queueSignal(_PendingSignal.newIcon);
  }

  String get attentionIconName => _attentionIconName;

  set attentionIconName(String name) {
    _attentionIconName = name;
    _updateIconProperties(name, isAttention: true);
  }

  set overlayIconName(String name) {
    _object.overlayIconName = name;
    _queueSignal(_PendingSignal.newOverlayIcon);
  }

  set overlayIconPixmaps(List<IconPixmap> pixmaps) {
    _object.overlayIconPixmaps = pixmaps;
    _queueSignal(_PendingSignal.newOverlayIcon);
  }

  set attentionMovieName(String value) {
    _object.attentionMovieName = value;
    _queueSignal(_PendingSignal.newAttentionMovie);
  }

  set attentionIconPixmaps(List<IconPixmap> pixmaps) {
    _object.attentionIconPixmaps = pixmaps;
    _queueSignal(_PendingSignal.newAttentionIcon);
  }

  set iconAccessibleDesc(String description) {
    _object.iconAccessibleDesc = description;
  }

  set attentionAccessibleDesc(String description) {
    _object.attentionAccessibleDesc = description;
  }

  set overlayAccessibleDesc(String description) {
    _object.overlayAccessibleDesc = description;
  }

  String get title => _object.title;

  set title(String title) {
    _object.title = title;
    _queueSignal(_PendingSignal.newTitle);
  }

  String get label => _object.xAyatanaLabel;

  set label(String label) {
    _object.xAyatanaLabel = label;
    _queueSignal(_PendingSignal.newLabel);
  }

  String get labelGuide => _object.xAyatanaLabelGuide;

  set labelGuide(String guide) {
    _object.xAyatanaLabelGuide = guide;
    _queueSignal(_PendingSignal.newLabel);
  }

  int get orderingIndex => _object.xAyatanaOrderingIndex;

  set orderingIndex(int orderingIndex) {
    _object.xAyatanaOrderingIndex = orderingIndex;
  }

  String get iconThemePath => _object.iconThemePath;

  set iconThemePath(String path) {
    _manualIconThemePath = path;
    _updateIconThemePath();
  }

  void _updateIconProperties(String name, {required bool isAttention}) {
    if (isAttention) {
      if (_looksLikePath(name)) {
        final file = File(name);
        _object.attentionIconName = file.uri.pathSegments.last;
      } else {
        _object.attentionIconName = name;
      }
      _queueSignal(_PendingSignal.newAttentionIcon);
    } else {
      if (_looksLikePath(name)) {
        final file = File(name);
        _object.iconName = file.uri.pathSegments.last;
      } else {
        _object.iconName = name;
      }
      _queueSignal(_PendingSignal.newIcon);
    }
    _updateIconThemePath();
  }

  void _updateIconThemePath() {
    var path = _manualIconThemePath;

    String relevantIcon;
    if (status == AppIndicatorStatus.attention) {
      relevantIcon = _attentionIconName;
    } else {
      relevantIcon = _iconName;
    }

    if (_looksLikePath(relevantIcon)) {
      path = File(relevantIcon).parent.path;
    }

    if (_object.iconThemePath != path) {
      _object.iconThemePath = path;
      _queueSignal(_PendingSignal.newIconThemePath);
    }
  }

  set windowId(int value) {
    _object.windowId = value;
  }

  set itemIsMenu(bool value) {
    _object.itemIsMenu = value;
  }

  // Tooltip properties
  String get tooltipIconName => _object.toolTipIconName;

  set tooltipIconName(String name) {
    _object.toolTipIconName = name;
    _queueSignal(_PendingSignal.newToolTip);
  }

  String get tooltipTitle => _object.toolTipTitle;

  set tooltipTitle(String title) {
    _object.toolTipTitle = title;
    _queueSignal(_PendingSignal.newToolTip);
  }

  String get tooltipDescription => _object.toolTipDescription;

  set tooltipDescription(String description) {
    _object.toolTipDescription = description;
    _queueSignal(_PendingSignal.newToolTip);
  }

  void setMenu(List<DBusMenuItem> items) {
    if (_menuGroupId == null) {
      _menuGroupId = _object.menuImpl.addMenu(items);
      return;
    }
    _object.menuImpl.setMenu(_menuGroupId!, items);
  }

  int addSubMenu(List<DBusMenuItem> items) {
    return _object.menuImpl.addMenu(items);
  }

  void setMenuGroup(int groupId, List<DBusMenuItem> items) {
    _object.menuImpl.setMenu(groupId, items);
    if (groupId == 0) {
      _menuGroupId = groupId;
    }
  }

  void updateMenuItems(int groupId,
      {required int position,
      int removeCount = 0,
      List<DBusMenuItem> items = const <DBusMenuItem>[]}) {
    _object.menuImpl.updateMenuItems(groupId,
        position: position, removeCount: removeCount, items: items);
  }

  void setActions(List<DBusAction> actions) {
    _object.actionGroupImpl.clearActions();
    for (var action in actions) {
      _object.actionGroupImpl.addAction(action);
    }
  }

  void setSecondaryActivateTarget(String? actionName) {
    _object.secondaryActivateTarget = actionName;
  }

  void setPrimaryActivateTarget(String? actionName) {
    _object.primaryActivateTarget = actionName;
  }

  void setDoubleClickTarget(String? actionName) {
    _object.doubleClickTarget = actionName;
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
      {required int delta, required String orientation}) async {
    await _object.doScroll(delta, orientation);
  }

  Future<void> dispatchXAyatanaActivate(
      {int x = 0, int y = 0, int timestamp = 0}) async {
    await _object.doXAyatanaActivate(x, y, timestamp);
  }

  /// Returns true when a StatusNotifierWatcher backend was discovered.
  bool get isWatcherAvailable => _watcher != null;

  /// Returns whether the currently connected watcher reports a host.
  ///
  /// If no watcher is available, this returns false.
  Future<bool> isStatusNotifierHostRegistered() async {
    if (_watcher == null) {
      return false;
    }

    try {
      return await _watcher!.getIsStatusNotifierHostRegistered();
    } catch (_) {
      return false;
    }
  }

  Future<void> connect() async {
    await _client.registerObject(_object);
    await _client.requestName(_serviceName);
    _isConnected = true;
    await _flushPendingSignals();

    _object.menuImpl.client = _client;
    _object.actionGroupImpl.client = _client;

    for (final endpoint in _watcherEndpoints) {
      final candidate = StatusNotifierWatcher(_client, endpoint.destination,
          path: DBusObjectPath(endpoint.path));

      try {
        // Probe before registering so we can support backends on different names/paths.
        await candidate.getProtocolVersion();
        await _registerWithWatcher(candidate);
        _watcher = candidate;
        return;
      } catch (error, stackTrace) {
        if (_isWatcherUnavailable(error)) {
          // Try the next known watcher endpoint.
          continue;
        }
        throw AppIndicatorRegistrationException(error, stackTrace);
      }
    }

    // No known watcher backend is currently present. Keep the indicator available
    // on D-Bus and return without throwing.
    _watcher = null;
  }

  Future<void> _registerWithWatcher(StatusNotifierWatcher watcher) async {
    final registrationTargets = <String>[
      _serviceName,
      '$_serviceName${_object.path}',
      _object.path.toString(),
    ];

    Object? lastError;
    for (final target in registrationTargets) {
      try {
        await watcher.callRegisterStatusNotifierItem(target);
        _registeredItemId = target;
        return;
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  bool _isWatcherUnavailable(Object error) {
    if (error is DBusMethodResponseException) {
      final errorName = error.errorName;
      return errorName == 'org.freedesktop.DBus.Error.ServiceUnknown' ||
          errorName == 'org.freedesktop.DBus.Error.UnknownObject' ||
          errorName == 'org.freedesktop.DBus.Error.UnknownMethod';
    }

    return false;
  }

  Future<void> close() async {
    if (_watcher != null) {
      // The SNI watcher protocol does not define an explicit unregister call in
      // all implementations. Try a best-effort remote teardown first so modern
      // watchers can remove the item before we drop our DBus resources.
      try {
        await _watcher!.callMethod(
            'org.kde.StatusNotifierWatcher',
            'UnregisterStatusNotifierItem',
            [DBusString(_registeredItemId ?? _object.path.toString())],
            replySignature: DBusSignature(''));
      } catch (_) {
        // Fallback behavior for protocol variants without unregister support:
        // just continue with local teardown (object/resources first, client
        // connection last). Closing our DBus connection implicitly releases the
        // exported object and unique name ownership.
      }
      _watcher = null;
    }

    await _scrollController.close();
    await _secondaryActivateController.close();
    await _activateController.close();
    await _contextMenuController.close();
    await _xAyatanaActivateController.close();
    await _client.close();
  }

  void _maybeDispatchDoubleClick() {
    final now = DateTime.now();
    final previous = _lastPrimaryActivateAt;
    _lastPrimaryActivateAt = now;

    if (previous == null || now.difference(previous) > _doubleClickWindow) {
      return;
    }

    _object.handleDoubleClick();
  }

  void _queueSignal(_PendingSignal signal) {
    if (_isConnected) {
      unawaited(_emitSignal(signal));
      return;
    }

    _pendingSignals.add(signal);
  }

  Future<void> _flushPendingSignals() async {
    for (final signal in _PendingSignal.values) {
      if (_pendingSignals.remove(signal)) {
        await _emitSignal(signal);
      }
    }
  }

  Future<void> _emitSignal(_PendingSignal signal) {
    switch (signal) {
      case _PendingSignal.newStatus:
        return _object.emitNewStatus(_object.status);
      case _PendingSignal.newIcon:
        return _object.emitNewIcon();
      case _PendingSignal.newAttentionIcon:
        return _object.emitNewAttentionIcon();
      case _PendingSignal.newOverlayIcon:
        return _object
            .emitSignal('org.kde.StatusNotifierItem', 'NewOverlayIcon', []);
      case _PendingSignal.newTitle:
        return _object.emitNewTitle();
      case _PendingSignal.newLabel:
        return _object.emitXAyatanaNewLabel(
            _object.xAyatanaLabel, _object.xAyatanaLabelGuide);
      case _PendingSignal.newIconThemePath:
        return _object.emitNewIconThemePath(_object.iconThemePath);
      case _PendingSignal.newToolTip:
        return _object.emitNewToolTip();
      case _PendingSignal.newAttentionMovie:
        return _object
            .emitSignal('org.kde.StatusNotifierItem', 'NewAttentionMovie', []);
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

class _WatcherEndpoint {
  final String destination;
  final String path;

  const _WatcherEndpoint(this.destination, this.path);
}

class _AppIndicatorObject extends StatusNotifierItem {
  final DBusMenu menuImpl;
  final DBusActionGroup actionGroupImpl;

  // Tooltip
  String toolTipIconName = '';
  String toolTipTitle = '';
  String toolTipDescription = '';

  String? secondaryActivateTarget;
  String? primaryActivateTarget;
  String? doubleClickTarget;

  int windowId = 0;
  bool itemIsMenu = false;
  List<IconPixmap> iconPixmaps = const <IconPixmap>[];
  List<IconPixmap> attentionIconPixmaps = const <IconPixmap>[];
  String overlayIconName = '';
  String overlayAccessibleDesc = '';
  List<IconPixmap> overlayIconPixmaps = const <IconPixmap>[];
  String attentionMovieName = '';

  Function(int, String)? onScroll;
  Function(int, int)? onSecondaryActivate;
  Function(int)? onXAyatanaSecondaryActivate;
  Function(int, int)? onActivate;
  Function(int, int)? onContextMenu;
  Function(int, int, int)? onXAyatanaActivate;

  _AppIndicatorObject(DBusObjectPath path)
      : menuImpl = DBusMenu(path),
        actionGroupImpl = DBusActionGroup(path),
        super(path: path);

  // Overrides for StatusNotifierItem properties
  @override
  Future<DBusMethodResponse> getId() async =>
      DBusMethodSuccessResponse([DBusString(id)]);

  @override
  Future<DBusMethodResponse> getCategory() async =>
      DBusMethodSuccessResponse([DBusString(category)]);

  @override
  Future<DBusMethodResponse> getStatus() async =>
      DBusMethodSuccessResponse([DBusString(status)]);

  @override
  Future<DBusMethodResponse> getIconName() async =>
      DBusMethodSuccessResponse([DBusString(iconName)]);

  @override
  Future<DBusMethodResponse> getAttentionIconName() async =>
      DBusMethodSuccessResponse([DBusString(attentionIconName)]);

  @override
  Future<DBusMethodResponse> getIconAccessibleDesc() async =>
      DBusMethodSuccessResponse([DBusString(iconAccessibleDesc)]);

  @override
  Future<DBusMethodResponse> getAttentionAccessibleDesc() async =>
      DBusMethodSuccessResponse([DBusString(attentionAccessibleDesc)]);

  @override
  Future<DBusMethodResponse> getTitle() async =>
      DBusMethodSuccessResponse([DBusString(title)]);

  @override
  Future<DBusMethodResponse> getIconThemePath() async =>
      DBusMethodSuccessResponse([DBusString(iconThemePath)]);

  @override
  Future<DBusMethodResponse> getMenu() async =>
      DBusMethodSuccessResponse([menu]);

  @override
  Future<DBusMethodResponse> getXAyatanaLabel() async =>
      DBusMethodSuccessResponse([DBusString(xAyatanaLabel)]);

  @override
  Future<DBusMethodResponse> getXAyatanaLabelGuide() async =>
      DBusMethodSuccessResponse([DBusString(xAyatanaLabelGuide)]);

  @override
  Future<DBusMethodResponse> getXAyatanaOrderingIndex() async =>
      DBusMethodSuccessResponse([DBusUint32(xAyatanaOrderingIndex)]);

  @override
  Future<DBusMethodResponse> getToolTip() async {
    return DBusMethodSuccessResponse([
      DBusStruct([
        DBusString(toolTipIconName),
        DBusArray(DBusSignature('(iiay)'), []),
        DBusString(toolTipTitle),
        DBusString(toolTipDescription)
      ])
    ]);
  }

  Future<DBusMethodResponse> getWindowId() async =>
      DBusMethodSuccessResponse([DBusUint32(windowId)]);

  Future<DBusMethodResponse> getItemIsMenu() async =>
      DBusMethodSuccessResponse([DBusBoolean(itemIsMenu)]);

  Future<DBusMethodResponse> getIconPixmap() async =>
      DBusMethodSuccessResponse([
        DBusArray(
          DBusSignature('(iiay)'),
          iconPixmaps.map((frame) => frame.toDBus()).toList(),
        ),
      ]);

  Future<DBusMethodResponse> getAttentionIconPixmap() async =>
      DBusMethodSuccessResponse([
        DBusArray(
          DBusSignature('(iiay)'),
          attentionIconPixmaps.map((frame) => frame.toDBus()).toList(),
        ),
      ]);

  Future<DBusMethodResponse> getOverlayIconName() async =>
      DBusMethodSuccessResponse([DBusString(overlayIconName)]);

  Future<DBusMethodResponse> getOverlayIconAccessibleDesc() async =>
      DBusMethodSuccessResponse([DBusString(overlayAccessibleDesc)]);

  Future<DBusMethodResponse> getOverlayIconPixmap() async =>
      DBusMethodSuccessResponse([
        DBusArray(
          DBusSignature('(iiay)'),
          overlayIconPixmaps.map((frame) => frame.toDBus()).toList(),
        ),
      ]);

  Future<DBusMethodResponse> getAttentionMovieName() async =>
      DBusMethodSuccessResponse([DBusString(attentionMovieName)]);

  // Methods implementation
  @override
  Future<DBusMethodResponse> doScroll(int delta, String orientation) async {
    if (onScroll != null) onScroll!(delta, orientation);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doSecondaryActivate(int x, int y) async {
    _handleSecondaryAction();
    if (onSecondaryActivate != null) onSecondaryActivate!(x, y);
    return DBusMethodSuccessResponse([]);
  }

  @override
  Future<DBusMethodResponse> doXAyatanaSecondaryActivate(int timestamp) async {
    _handleSecondaryAction();
    if (onXAyatanaSecondaryActivate != null) {
      onXAyatanaSecondaryActivate!(timestamp);
    }
    return DBusMethodSuccessResponse([]);
  }

  Future<DBusMethodResponse> doActivate(int x, int y) async {
    _handlePrimaryAction();
    onActivate?.call(x, y);
    return DBusMethodSuccessResponse([]);
  }

  Future<DBusMethodResponse> doContextMenu(int x, int y) async {
    onContextMenu?.call(x, y);
    return DBusMethodSuccessResponse([]);
  }

  Future<DBusMethodResponse> doXAyatanaActivate(
      int x, int y, int timestamp) async {
    _handlePrimaryAction();
    onXAyatanaActivate?.call(x, y, timestamp);
    return DBusMethodSuccessResponse([]);
  }

  void _handlePrimaryAction() {
    if (primaryActivateTarget != null) {
      var action = actionGroupImpl.getAction(primaryActivateTarget!);
      if (action != null && action.enabled) {
        action.activate(null);
      }
    }
  }

  void handleDoubleClick() {
    if (doubleClickTarget != null) {
      var action = actionGroupImpl.getAction(doubleClickTarget!);
      if (action != null && action.enabled) {
        action.activate(null);
      }
    }
  }

  void _handleSecondaryAction() {
    if (secondaryActivateTarget != null) {
      var action = actionGroupImpl.getAction(secondaryActivateTarget!);
      if (action != null && action.enabled) {
        action.activate(null);
      }
    }
  }

  // Delegate other interfaces
  @override
  List<DBusIntrospectInterface> introspect() {
    final interfaces = super.introspect();
    final statusInterface = interfaces.firstWhere(
      (interface) => interface.name == 'org.kde.StatusNotifierItem',
    );

    statusInterface.methods.addAll([
      DBusIntrospectMethod(
        'Activate',
        args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'x'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'y'),
        ],
      ),
      DBusIntrospectMethod(
        'ContextMenu',
        args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'x'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'y'),
        ],
      ),
      DBusIntrospectMethod(
        'XAyatanaActivate',
        args: [
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'x'),
          DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
              name: 'y'),
          DBusIntrospectArgument(
            DBusSignature('u'),
            DBusArgumentDirection.in_,
            name: 'timestamp',
          ),
        ],
      ),
    ]);

    statusInterface.properties.addAll([
      DBusIntrospectProperty('WindowId', DBusSignature('u'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('ItemIsMenu', DBusSignature('b'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('IconPixmap', DBusSignature('a(iiay)'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('AttentionIconPixmap', DBusSignature('a(iiay)'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('OverlayIconName', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('OverlayIconAccessibleDesc', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('OverlayIconPixmap', DBusSignature('a(iiay)'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('AttentionMovieName', DBusSignature('s'),
          access: DBusPropertyAccess.read),
    ]);

    interfaces.addAll(menuImpl.introspect());
    interfaces.addAll(actionGroupImpl.introspect());
    return interfaces;
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierItem') {
      if (methodCall.name == 'Activate') {
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doActivate(
            methodCall.values[0].asInt32(), methodCall.values[1].asInt32());
      }
      if (methodCall.name == 'ContextMenu') {
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doContextMenu(
            methodCall.values[0].asInt32(), methodCall.values[1].asInt32());
      }
      if (methodCall.name == 'XAyatanaActivate') {
        if (methodCall.signature != DBusSignature('iiu')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doXAyatanaActivate(
          methodCall.values[0].asInt32(),
          methodCall.values[1].asInt32(),
          methodCall.values[2].asUint32(),
        );
      }
      return super.handleMethodCall(methodCall);
    } else if (methodCall.interface == 'org.gtk.Menus') {
      return menuImpl.handleMethodCall(methodCall);
    } else if (methodCall.interface == 'org.gtk.Actions') {
      return actionGroupImpl.handleMethodCall(methodCall);
    }
    return DBusMethodErrorResponse.unknownInterface();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.kde.StatusNotifierItem') {
      switch (name) {
        case 'WindowId':
          return getWindowId();
        case 'ItemIsMenu':
          return getItemIsMenu();
        case 'IconPixmap':
          return getIconPixmap();
        case 'AttentionIconPixmap':
          return getAttentionIconPixmap();
        case 'OverlayIconName':
          return getOverlayIconName();
        case 'OverlayIconAccessibleDesc':
          return getOverlayIconAccessibleDesc();
        case 'OverlayIconPixmap':
          return getOverlayIconPixmap();
        case 'AttentionMovieName':
          return getAttentionMovieName();
      }
    }

    return super.getProperty(interface, name);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    final response = await super.getAllProperties(interface);
    if (interface != 'org.kde.StatusNotifierItem') {
      return response;
    }

    final dict = Map<String, DBusValue>.from(
        response.returnValues[0].asStringVariantDict());
    dict['WindowId'] = (await getWindowId()).returnValues[0];
    dict['ItemIsMenu'] = (await getItemIsMenu()).returnValues[0];
    dict['IconPixmap'] = (await getIconPixmap()).returnValues[0];
    dict['AttentionIconPixmap'] =
        (await getAttentionIconPixmap()).returnValues[0];
    dict['OverlayIconName'] = (await getOverlayIconName()).returnValues[0];
    dict['OverlayIconAccessibleDesc'] =
        (await getOverlayIconAccessibleDesc()).returnValues[0];
    dict['OverlayIconPixmap'] = (await getOverlayIconPixmap()).returnValues[0];
    dict['AttentionMovieName'] =
        (await getAttentionMovieName()).returnValues[0];
    return DBusMethodSuccessResponse([DBusDict.stringVariant(dict)]);
  }
}
