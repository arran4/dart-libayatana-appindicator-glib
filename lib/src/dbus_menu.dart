import 'package:dbus/dbus.dart';

class DBusMenu extends DBusObject {
  final List<DBusMenuItem> _rootItems;
  final Map<int, List<DBusMenuItem>> _menus = {};
  final Map<int, DBusMenuItem> _itemCache = {};
  int _revision = 1;

  DBusMenu(DBusObjectPath path, this._rootItems) : super(path) {
    _rebuildMenus();
  }

  List<DBusMenuItem> get items => _rootItems;

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'com.canonical.dbusmenu',
        methods: [
          DBusIntrospectMethod('GetLayout', args: [
            DBusIntrospectArgument(
                DBusSignature('i'), DBusArgumentDirection.in_,
                name: 'parentId'),
            DBusIntrospectArgument(
                DBusSignature('i'), DBusArgumentDirection.in_,
                name: 'recursionDepth'),
            DBusIntrospectArgument(
                DBusSignature('as'), DBusArgumentDirection.in_,
                name: 'propertyNames'),
            DBusIntrospectArgument(
                DBusSignature('u'), DBusArgumentDirection.out,
                name: 'revision'),
            DBusIntrospectArgument(
                DBusSignature('(ia{sv}av)'), DBusArgumentDirection.out,
                name: 'layout'),
          ]),
          DBusIntrospectMethod('GetGroupProperties', args: [
            DBusIntrospectArgument(
                DBusSignature('ai'), DBusArgumentDirection.in_,
                name: 'ids'),
            DBusIntrospectArgument(
                DBusSignature('as'), DBusArgumentDirection.in_,
                name: 'propertyNames'),
            DBusIntrospectArgument(
                DBusSignature('a(ia{sv})'), DBusArgumentDirection.out,
                name: 'properties'),
          ]),
          DBusIntrospectMethod('GetProperty', args: [
            DBusIntrospectArgument(
                DBusSignature('i'), DBusArgumentDirection.in_,
                name: 'id'),
            DBusIntrospectArgument(
                DBusSignature('s'), DBusArgumentDirection.in_,
                name: 'name'),
            DBusIntrospectArgument(
                DBusSignature('v'), DBusArgumentDirection.out,
                name: 'value'),
          ]),
          DBusIntrospectMethod('Event', args: [
            DBusIntrospectArgument(
                DBusSignature('i'), DBusArgumentDirection.in_,
                name: 'id'),
            DBusIntrospectArgument(
                DBusSignature('s'), DBusArgumentDirection.in_,
                name: 'eventId'),
            DBusIntrospectArgument(
                DBusSignature('v'), DBusArgumentDirection.in_,
                name: 'data'),
            DBusIntrospectArgument(
                DBusSignature('u'), DBusArgumentDirection.in_,
                name: 'timestamp'),
          ]),
          DBusIntrospectMethod('AboutToShow', args: [
            DBusIntrospectArgument(
                DBusSignature('i'), DBusArgumentDirection.in_,
                name: 'id'),
            DBusIntrospectArgument(
                DBusSignature('b'), DBusArgumentDirection.out,
                name: 'needUpdate'),
          ]),
        ],
        signals: [
          DBusIntrospectSignal('LayoutUpdated', args: [
            DBusIntrospectArgument(
                DBusSignature('u'), DBusArgumentDirection.out,
                name: 'revision'),
            DBusIntrospectArgument(
                DBusSignature('i'), DBusArgumentDirection.out,
                name: 'parentId'),
          ]),
        ],
        properties: [
          DBusIntrospectProperty('Version', DBusSignature('u'),
              access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Status', DBusSignature('s'),
              access: DBusPropertyAccess.read),
        ],
      )
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'com.canonical.dbusmenu') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (methodCall.name == 'GetLayout') {
      final parentId = methodCall.values[0].asInt32();
      final recursionDepth = methodCall.values[1].asInt32();
      return _getLayout(parentId, recursionDepth);
    } else if (methodCall.name == 'Event') {
      final id = methodCall.values[0].asInt32();
      final eventId = methodCall.values[1].asString();
      return _handleEvent(id, eventId);
    } else if (methodCall.name == 'GetGroupProperties') {
      return DBusMethodSuccessResponse(
          [DBusArray(DBusSignature('(ia{sv})'), [])]);
    } else if (methodCall.name == 'AboutToShow') {
      return DBusMethodSuccessResponse([DBusBoolean(false)]);
    }

    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'com.canonical.dbusmenu') {
      if (name == 'Version') {
        return DBusMethodSuccessResponse([DBusUint32(3)]);
      }
      if (name == 'Status') {
        return DBusMethodSuccessResponse([DBusString('normal')]);
      }
    }
    return DBusMethodErrorResponse.unknownProperty();
  }

  Future<DBusMethodResponse> _getLayout(
      int parentId, int recursionDepth) async {
    final layout = _buildLayout(parentId, recursionDepth);
    return DBusMethodSuccessResponse([DBusUint32(_revision), layout]);
  }

  DBusValue _buildLayout(int id, int recursionDepth) {
    var properties = <String, DBusValue>{};
    var childrenVariants = <DBusVariant>[];

    if (id == 0) {
      if (recursionDepth != 0) {
        int nextDepth = recursionDepth == -1 ? -1 : recursionDepth - 1;
        childrenVariants = _rootItems
            .map((item) => DBusVariant(_buildItem(item, nextDepth)))
            .toList();
      }
    } else {
      var item = _itemCache[id];
      if (item != null) {
        return _buildItem(item, recursionDepth);
      }
    }

    return DBusStruct([
      DBusInt32(id),
      DBusDict.stringVariant(properties),
      DBusArray(DBusSignature('v'), childrenVariants),
    ]);
  }

  DBusValue _buildItem(DBusMenuItem item, int recursionDepth) {
    var childrenVariants = <DBusVariant>[];

    if (recursionDepth != 0) {
      int nextDepth = recursionDepth == -1 ? -1 : recursionDepth - 1;
      childrenVariants = item.children
          .map((c) => DBusVariant(_buildItem(c, nextDepth)))
          .toList();
    }

    return DBusStruct([
      DBusInt32(item.id),
      DBusDict.stringVariant(item.properties),
      DBusArray(DBusSignature('v'), childrenVariants),
    ]);
  }

  Future<DBusMethodResponse> _handleEvent(int id, String eventId) async {
    if (eventId == 'clicked') {
      final item = _itemCache[id];
      item?.onActivated?.call();
    }
    return DBusMethodSuccessResponse([]);
  }

  void updateItems(List<DBusMenuItem> items) {
    _rootItems.clear();
    _rootItems.addAll(items);
    _revision++;
    _rebuildMenus();
    emitSignal('com.canonical.dbusmenu', 'LayoutUpdated',
        [DBusUint32(_revision), DBusInt32(0)]);
  }

  void _rebuildMenus() {
    _menus.clear();
    _itemCache.clear();
    _menus[0] = _rootItems;
    for (var item in _rootItems) {
      _registerItem(item);
    }
  }

  void _registerItem(DBusMenuItem item) {
    _menus[item.id] = item.children;
    _itemCache[item.id] = item;
    for (var child in item.children) {
      _registerItem(child);
    }
  }

  void updateMenuItems(int id,
      {required int position,
      int removeCount = 0,
      List<DBusMenuItem> items = const <DBusMenuItem>[]}) {
    var menuItems = _menus[id];
    if (menuItems == null) {
      throw ArgumentError('Menu group $id does not exist');
    }

    if (position < 0 || position > menuItems.length) {
      throw RangeError.range(position, 0, menuItems.length, 'position');
    }

    if (removeCount < 0 || removeCount > menuItems.length - position) {
      throw RangeError.range(
          removeCount, 0, menuItems.length - position, 'removeCount');
    }

    menuItems.replaceRange(position, position + removeCount, items);

    for (var item in items) {
      _registerItem(item);
    }

    _emitMenuChanged(id, position, removeCount, items);
  }

  void _emitMenuChanged(
      int id, int position, int removeCount, List<DBusMenuItem> items) {
    _revision++;
    emitSignal('com.canonical.dbusmenu', 'LayoutUpdated',
        [DBusUint32(_revision), DBusInt32(id)]);
  }
}

class DBusMenuItem {
  final int id;
  final Map<String, DBusValue> properties;
  final List<DBusMenuItem> children;
  final void Function()? onActivated;

  DBusMenuItem({
    this.id = 0,
    required this.properties,
    this.children = const [],
    this.onActivated,
  });

  factory DBusMenuItem.label(String label,
      {int id = 0, void Function()? onActivated}) {
    return DBusMenuItem(
      id: id,
      properties: {'label': DBusString(label)},
      onActivated: onActivated,
    );
  }
}
