import 'package:dbus/dbus.dart';

class DBusMenu extends DBusObject {
  final List<DBusMenuItem> _rootItems;
  int _revision = 1;

  DBusMenu(DBusObjectPath path, this._rootItems) : super(path);

  List<DBusMenuItem> get items => _rootItems;

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'com.canonical.dbusmenu',
        methods: [
          DBusIntrospectMethod('GetLayout', args: [
            DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'parentId'),
            DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'recursionDepth'),
            DBusIntrospectArgument(DBusSignature('as'), DBusArgumentDirection.in_, name: 'propertyNames'),
            DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out, name: 'revision'),
            DBusIntrospectArgument(DBusSignature('(ia{sv}av)'), DBusArgumentDirection.out, name: 'layout'),
          ]),
          DBusIntrospectMethod('GetGroupProperties', args: [
            DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.in_, name: 'ids'),
            DBusIntrospectArgument(DBusSignature('as'), DBusArgumentDirection.in_, name: 'propertyNames'),
            DBusIntrospectArgument(DBusSignature('a(ia{sv})'), DBusArgumentDirection.out, name: 'properties'),
          ]),
          DBusIntrospectMethod('GetProperty', args: [
            DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'id'),
            DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'name'),
            DBusIntrospectArgument(DBusSignature('v'), DBusArgumentDirection.out, name: 'value'),
          ]),
          DBusIntrospectMethod('Event', args: [
            DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'id'),
            DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'eventId'),
            DBusIntrospectArgument(DBusSignature('v'), DBusArgumentDirection.in_, name: 'data'),
            DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.in_, name: 'timestamp'),
          ]),
          DBusIntrospectMethod('AboutToShow', args: [
            DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'id'),
            DBusIntrospectArgument(DBusSignature('b'), DBusArgumentDirection.out, name: 'needUpdate'),
          ]),
        ],
        signals: [
          DBusIntrospectSignal('LayoutUpdated', args: [
            DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out, name: 'revision'),
            DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.out, name: 'parentId'),
          ]),
        ],
        properties: [
          DBusIntrospectProperty('Version', DBusSignature('u'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Status', DBusSignature('s'), access: DBusPropertyAccess.read),
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
      return DBusMethodSuccessResponse([DBusArray(DBusSignature('(ia{sv})'), [])]);
    } else if (methodCall.name == 'AboutToShow') {
      return DBusMethodSuccessResponse([DBusBoolean(false)]);
    }

    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'com.canonical.dbusmenu') {
      if (name == 'Version') return DBusMethodSuccessResponse([DBusUint32(3)]);
      if (name == 'Status') return DBusMethodSuccessResponse([DBusString('normal')]);
    }
    return DBusMethodErrorResponse.unknownProperty();
  }

  Future<DBusMethodResponse> _getLayout(int parentId, int recursionDepth) async {
    final layout = _buildLayout(0);
    return DBusMethodSuccessResponse([DBusUint32(_revision), layout]);
  }

  DBusValue _buildLayout(int id) {
    var properties = <String, DBusValue>{};
    var children = <DBusValue>[];

    if (id == 0) {
      children = _rootItems.map((item) => _buildItem(item)).toList();
    }

    return DBusStruct([
      DBusInt32(id),
      DBusDict.stringVariant(properties),
      DBusArray(DBusSignature('v'), children.map((c) => DBusVariant(c)).toList()),
    ]);
  }

  DBusValue _buildItem(DBusMenuItem item) {
    return DBusStruct([
      DBusInt32(item.id),
      DBusDict.stringVariant(item.properties),
      DBusArray(DBusSignature('v'), item.children.map((c) => DBusVariant(_buildItem(c))).toList()),
    ]);
  }

  Future<DBusMethodResponse> _handleEvent(int id, String eventId) async {
    if (eventId == 'clicked') {
      final item = _findItemById(_rootItems, id);
      item?.onActivated?.call();
    }
    return DBusMethodSuccessResponse([]);
  }

  DBusMenuItem? _findItemById(List<DBusMenuItem> items, int id) {
    for (final item in items) {
      if (item.id == id) return item;
      final found = _findItemById(item.children, id);
      if (found != null) return found;
    }
    return null;
  }

  void updateItems(List<DBusMenuItem> items) {
    _rootItems.clear();
    _rootItems.addAll(items);
    _revision++;
    emitSignal('com.canonical.dbusmenu', 'LayoutUpdated', [DBusUint32(_revision), DBusInt32(0)]);
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

  factory DBusMenuItem.label(String label, {int id = 0, void Function()? onActivated}) {
    return DBusMenuItem(
      id: id,
      properties: {'label': DBusString(label)},
      onActivated: onActivated,
    );
  }
}
