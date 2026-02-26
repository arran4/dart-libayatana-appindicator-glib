import 'dart:async';

import 'package:dbus/dbus.dart';

import 'common.dart';
import 'dbus_menu.dart' as dm;
import 'enums.dart';
import 'strategies/canonical_app_menu_strategy.dart';
import 'strategies/dbus_menu_strategy.dart';
import 'strategies/indicator_strategy.dart';
import 'strategies/status_notifier_strategy.dart';

export 'common.dart';
export 'dbus_menu.dart' show DBusMenuItem;
export 'enums.dart';

/// A port of Ayatana AppIndicator to Dart.
class AppIndicator {
  final String id;
  final AppIndicatorCategory category;
  final AppIndicatorProtocol protocol;

  final DBusClient _client;
  final bool _ownsClient;
  late final IndicatorStrategy _strategy;

  // Local state
  AppIndicatorStatus _status = AppIndicatorStatus.passive;
  String _iconName = '';
  String _attentionIconName = '';
  String _manualIconThemePath = '';
  String _title = '';
  String _label = '';
  String _labelGuide = '';
  String _tooltipTitle = '';
  String _tooltipDescription = '';
  bool _itemIsMenu = true;
  int _windowId = 0;
  List<IconPixmap> _iconPixmaps = [];
  List<IconPixmap> _attentionIconPixmaps = [];
  String _overlayIconName = '';
  List<IconPixmap> _overlayIconPixmaps = [];
  String _attentionMovieName = '';

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
    this.protocol = AppIndicatorProtocol.gtk,
  })  : _client = client ?? DBusClient.session(),
        _ownsClient = client == null {
    _iconName = iconName;

    switch (protocol) {
      case AppIndicatorProtocol.gtk:
      case AppIndicatorProtocol.statusNotifier:
        // We handle iconName setting via property setter to trigger path logic
        _strategy = StatusNotifierStrategy(
          id: id,
          category: category,
          client: _client,
        );
        break;
      case AppIndicatorProtocol.dbusMenu:
        _strategy = DBusMenuStrategy(id: id, client: _client);
        break;
      case AppIndicatorProtocol.appMenu:
        _strategy = CanonicalAppMenuStrategy(id: id, client: _client);
        break;
    }

    _setupStrategyEvents();

    // Apply initial icon name which triggers strategy update
    if (iconName.isNotEmpty) {
      this.iconName = iconName;
    }
  }

  void _setupStrategyEvents() {
    _strategy.onScroll = (delta, orientation) {
      onScroll?.call(delta, orientation);
      _scrollController.add(ScrollEvent(delta, orientation));
    };

    _strategy.onSecondaryActivate = (x, y) {
      onSecondaryActivate?.call(x, y);
      _secondaryActivateController.add(SecondaryActivateEvent(x, y));
    };

    _strategy.onXAyatanaSecondaryActivate = (timestamp) {
      onSecondaryActivate?.call(0, 0);
      _secondaryActivateController.add(SecondaryActivateEvent(0, 0, timestamp));
    };

    _strategy.onActivate = (x, y) {
      onActivate?.call(x, y);
      _activateController.add(ActivateEvent(x, y));
    };

    _strategy.onContextMenu = (x, y) {
      onContextMenu?.call(x, y);
      _contextMenuController.add(ContextMenuEvent(x, y));
    };

    _strategy.onXAyatanaActivate = (x, y, timestamp) {
      onActivate?.call(x, y);
      _xAyatanaActivateController.add(XAyatanaActivateEvent(x, y, timestamp));
    };
  }

  Future<void> connect({String? watcherName, String? watcherPath}) async {
    await _strategy.connect(watcherName: watcherName, watcherPath: watcherPath);
  }

  Future<void> close() async {
    await _strategy.close();
    if (_ownsClient) {
      await _client.close();
    }
  }

  Future<List<String>> validate() {
    return _strategy.validate();
  }

  // Path handling logic
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

  String? _getThemePathFromIcon(String name) {
    if (name.startsWith('/')) {
      final lastSlash = name.lastIndexOf('/');
      return name.substring(0, lastSlash);
    }
    return null;
  }

  void _updateStrategyIconPaths() {
    final currentIcon = (_status == AppIndicatorStatus.attention)
        ? (_attentionIconName.isNotEmpty ? _attentionIconName : _iconName)
        : _iconName;

    final derivedPath = _getThemePathFromIcon(currentIcon);
    if (derivedPath != null) {
      _strategy.updateIconThemePath(derivedPath);
    } else if (_manualIconThemePath.isNotEmpty) {
      _strategy.updateIconThemePath(_manualIconThemePath);
    } else {
      // Should we clear it? Original code didn't clear explicitly unless overwritten.
      // But if we switched from path-icon to name-icon, we might want to revert to empty or manual.
      _strategy.updateIconThemePath('');
    }
  }

  // Properties mapping
  String get title => _title;
  set title(String value) {
    _title = value;
    _strategy.updateTitle(value);
  }

  String get label => _label;
  set label(String value) {
    _label = value;
    _strategy.updateLabel(value, _labelGuide);
  }

  String get labelGuide => _labelGuide;
  set labelGuide(String value) {
    _labelGuide = value;
    _strategy.updateLabel(_label, value);
  }

  AppIndicatorStatus get status => _status;
  set status(AppIndicatorStatus value) {
    _status = value;
    _strategy.updateStatus(value);
    _updateStrategyIconPaths();
  }

  String get iconName => _iconName;
  set iconName(String value) {
    _iconName = value;
    _strategy.updateIconName(_processIconName(value));
    _updateStrategyIconPaths();
  }

  String get attentionIconName => _attentionIconName;
  set attentionIconName(String value) {
    _attentionIconName = value;
    _strategy.updateAttentionIconName(_processIconName(value));
    _updateStrategyIconPaths();
  }

  String get iconThemePath => _manualIconThemePath.isNotEmpty
      ? _manualIconThemePath
      : _getThemePathFromIcon(_status == AppIndicatorStatus.attention
              ? (_attentionIconName.isNotEmpty ? _attentionIconName : _iconName)
              : _iconName) ??
          '';

  set iconThemePath(String value) {
    _manualIconThemePath = value;
    // We update strategy with the manual path, unless current icon dictates a path.
    // Wait, if manual path is set, it overrides?
    // In original code: getter prefers manual. DBus object gets overwritten by icon path.
    // So if icon dictates path, strategy gets icon path.
    // If icon is name, strategy gets manual path.
    _updateStrategyIconPaths();
  }

  String get tooltipTitle => _tooltipTitle;
  set tooltipTitle(String value) {
    _tooltipTitle = value;
    _strategy.updateTooltip(value, _tooltipDescription);
  }

  String get tooltipDescription => _tooltipDescription;
  set tooltipDescription(String value) {
    _tooltipDescription = value;
    _strategy.updateTooltip(_tooltipTitle, value);
  }

  bool get itemIsMenu => _itemIsMenu;
  set itemIsMenu(bool value) {
    _itemIsMenu = value;
    _strategy.updateItemIsMenu(value);
  }

  int get windowId => _windowId;
  set windowId(int value) {
    _windowId = value;
    _strategy.updateWindowId(value);
  }

  List<IconPixmap> get iconPixmaps => _iconPixmaps;
  set iconPixmaps(List<IconPixmap> value) {
    _iconPixmaps = value;
    _strategy.updateIconPixmaps(value);
  }

  List<IconPixmap> get attentionIconPixmaps => _attentionIconPixmaps;
  set attentionIconPixmaps(List<IconPixmap> value) {
    _attentionIconPixmaps = value;
    _strategy.updateAttentionIconPixmaps(value);
  }

  String get overlayIconName => _overlayIconName;
  set overlayIconName(String value) {
    _overlayIconName = value;
    _strategy.updateOverlayIconName(value);
  }

  List<IconPixmap> get overlayIconPixmaps => _overlayIconPixmaps;
  set overlayIconPixmaps(List<IconPixmap> value) {
    _overlayIconPixmaps = value;
    _strategy.updateOverlayIconPixmaps(value);
  }

  String get attentionMovieName => _attentionMovieName;
  set attentionMovieName(String value) {
    _attentionMovieName = value;
    _strategy.updateAttentionMovieName(value);
  }

  void setMenu(List<dm.DBusMenuItem> items) {
    _strategy.updateMenu(items);
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
    await _strategy.dispatchActivate(x: x, y: y);
  }

  Future<void> dispatchSecondaryActivate({int x = 0, int y = 0}) async {
    await _strategy.dispatchSecondaryActivate(x: x, y: y);
  }

  Future<void> dispatchContextMenu({int x = 0, int y = 0}) async {
    await _strategy.dispatchContextMenu(x: x, y: y);
  }

  Future<void> dispatchScroll(
      {int delta = 0, String orientation = 'vertical'}) async {
    await _strategy.dispatchScroll(delta: delta, orientation: orientation);
  }

  bool get isWatcherAvailable => _strategy.isWatcherAvailable;

  Future<bool> isStatusNotifierHostRegistered() async {
    return _strategy.isStatusNotifierHostRegistered();
  }
}
