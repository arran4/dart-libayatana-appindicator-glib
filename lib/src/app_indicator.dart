import 'dart:async';
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
    _WatcherEndpoint('org.freedesktop.StatusNotifierWatcher', '/StatusNotifierWatcher'),
    _WatcherEndpoint('org.kde.StatusNotifierWatcher', '/org/kde/StatusNotifierWatcher'),
    _WatcherEndpoint(
        'org.freedesktop.StatusNotifierWatcher', '/org/freedesktop/StatusNotifierWatcher'),
  ];

  final String id;
  final DBusClient _client;
  final _AppIndicatorObject _object;
  StatusNotifierWatcher? _watcher;
  int? _menuGroupId;

  // Stream controllers
  final _scrollController = StreamController<ScrollEvent>.broadcast();
  final _secondaryActivateController =
      StreamController<SecondaryActivateEvent>.broadcast();
  bool _isConnected = false;
  final Set<_PendingSignal> _pendingSignals = <_PendingSignal>{};

  AppIndicator(
      {required this.id,
      String iconName = '',
      AppIndicatorCategory category = AppIndicatorCategory.applicationStatus})
      : _client = DBusClient.session(),
        _object =
            _AppIndicatorObject(DBusObjectPath('/org/ayatana/appindicator/${_cleanId(id)}')) {
    _object.id = id;
    _object.iconName = iconName;
    _object.category = category.name;
    _object.menu = _object.path; // Menu is on the same object path
    _object.iconThemePath = '';
    _object.title = '';
    _object.status = AppIndicatorStatus.passive.name;
    _object.attentionIconName = '';

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
  }

  static String _cleanId(String id) {
    final sanitized = id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final collapsed = sanitized.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

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
    _queueSignal(_PendingSignal.newStatus);
  }

  String get iconName => _object.iconName;

  set iconName(String name) {
    _object.iconName = name;
    _queueSignal(_PendingSignal.newIcon);
  }

  set attentionIconName(String name) {
    _object.attentionIconName = name;
    _queueSignal(_PendingSignal.newAttentionIcon);
  }

  set iconAccessibleDesc(String description) {
    _object.iconAccessibleDesc = description;
  }

  set attentionAccessibleDesc(String description) {
    _object.attentionAccessibleDesc = description;
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

  set iconThemePath(String path) {
    _object.iconThemePath = path;
    _queueSignal(_PendingSignal.newIconThemePath);
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

  // Events
  Stream<ScrollEvent> get scrollEvents => _scrollController.stream;
  Stream<SecondaryActivateEvent> get secondaryActivateEvents =>
      _secondaryActivateController.stream;

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
        await candidate.callRegisterStatusNotifierItem(_object.path.toString());
        _watcher = candidate;
        return;
    } catch (error, stackTrace) {
      throw AppIndicatorRegistrationException(error, stackTrace);
      } catch (_) {
        // Try the next known watcher endpoint.
      }
    }

    // No known watcher backend is currently present. Keep the indicator available
    // on D-Bus and return without throwing.
    _watcher = null;
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
            [DBusString(_object.path.toString())],
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
    await _client.close();
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
      case _PendingSignal.newTitle:
        return _object.emitNewTitle();
      case _PendingSignal.newLabel:
        return _object.emitXAyatanaNewLabel(
            _object.xAyatanaLabel, _object.xAyatanaLabelGuide);
      case _PendingSignal.newIconThemePath:
        return _object.emitNewIconThemePath(_object.iconThemePath);
      case _PendingSignal.newToolTip:
        return _object.emitNewToolTip();
    }
  }
}

enum _PendingSignal {
  newStatus,
  newIcon,
  newAttentionIcon,
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

  Function(int, String)? onScroll;
  Function(int, int)? onSecondaryActivate;
  Function(int)? onXAyatanaSecondaryActivate;

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
    if (onXAyatanaSecondaryActivate != null) onXAyatanaSecondaryActivate!(timestamp);
    return DBusMethodSuccessResponse([]);
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
    var interfaces = super.introspect();
    interfaces.addAll(menuImpl.introspect());
    interfaces.addAll(actionGroupImpl.introspect());
    return interfaces;
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierItem') {
      return super.handleMethodCall(methodCall);
    } else if (methodCall.interface == 'org.gtk.Menus') {
      return menuImpl.handleMethodCall(methodCall);
    } else if (methodCall.interface == 'org.gtk.Actions') {
      return actionGroupImpl.handleMethodCall(methodCall);
    }
    return DBusMethodErrorResponse.unknownInterface();
  }
}
