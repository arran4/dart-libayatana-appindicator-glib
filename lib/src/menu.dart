import 'package:dbus/dbus.dart';

class DBusMenu extends DBusObject {
  final Map<int, List<DBusMenuItem>> _menus = {};
  int _nextMenuId = 0;

  DBusMenu(DBusObjectPath path) : super(path);

  int addMenu(List<DBusMenuItem> items) {
    var id = _nextMenuId++;
    _menus[id] = items;
    _emitMenuChanged(id, 0, 0, items);
    return id;
  }

  void setMenu(int id, List<DBusMenuItem> items) {
    var previousItems = _menus[id] ?? const <DBusMenuItem>[];
    _menus[id] = items;
    _emitMenuChanged(id, 0, previousItems.length, items);
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
    _emitMenuChanged(id, position, removeCount, items);
  }

  void clear() {
    _menus.clear();
    _nextMenuId = 0;
  }

  Future<void> _emitMenuChanged(
      int menuId, int position, int removedCount, List<DBusMenuItem> items) async {
    await emitSignal('org.gtk.Menus', 'Changed', [
      DBusArray(DBusSignature('(uuuua(a{sv}a{sv}))'), [
        DBusStruct([
          DBusUint32(0), // group id
          DBusUint32(menuId),
          DBusUint32(position),
          DBusUint32(removedCount),
          DBusArray(DBusSignature('(a{sv}a{sv})'),
              items.map((item) => item.toDBus()).toList()),
        ])
      ])
    ]);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'org.gtk.Menus',
        methods: [
          DBusIntrospectMethod('Start', args: [
            DBusIntrospectArgument(DBusSignature('au'),
                DBusArgumentDirection.in_, name: 'groups'),
            DBusIntrospectArgument(DBusSignature('a(uua(a{sv}a{sv}))'),
                DBusArgumentDirection.out, name: 'state')
          ]),
          DBusIntrospectMethod('End', args: [
            DBusIntrospectArgument(DBusSignature('au'),
                DBusArgumentDirection.in_, name: 'groups')
          ]),
        ],
        signals: [
          DBusIntrospectSignal('Changed', args: [
            DBusIntrospectArgument(DBusSignature('a(uuuua(a{sv}a{sv}))'),
                DBusArgumentDirection.out, name: 'changes'),
          ]),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.gtk.Menus') {
      if (methodCall.name == 'Start') {
        if (methodCall.signature != DBusSignature('au')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return _handleStart(methodCall.values);
      } else if (methodCall.name == 'End') {
        if (methodCall.signature != DBusSignature('au')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return _handleEnd(methodCall.values);
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    }
    return DBusMethodErrorResponse.unknownInterface();
  }

  Future<DBusMethodResponse> _handleStart(List<DBusValue> parameters) async {
    var requestedGroups = parameters[0].asUint32Array().toSet();
    var menusList = <DBusValue>[];

    for (var entry in _menus.entries) {
      var menuId = entry.key;
      if (requestedGroups.isNotEmpty && !requestedGroups.contains(0)) {
        continue;
      }

      var items = entry.value;
      menusList.add(DBusStruct([
        DBusUint32(0), // Group ID
        DBusUint32(menuId),
        DBusArray(
            DBusSignature('(a{sv}a{sv})'), items.map((item) => item.toDBus()).toList()),
      ]));
    }

    return DBusMethodSuccessResponse(
        [DBusArray(DBusSignature('(uua(a{sv}a{sv}))'), menusList)]);
  }

  Future<DBusMethodResponse> _handleEnd(List<DBusValue> parameters) async {
    return DBusMethodSuccessResponse([]);
  }
}

class DBusMenuItem {
  final Map<String, DBusValue> attributes;
  final Map<String, DBusValue> links;

  DBusMenuItem(this.attributes, this.links);

  DBusValue toDBus() {
    var attrs = DBusDict(
        DBusSignature('s'),
        DBusSignature('v'),
        attributes.map((k, v) =>
            MapEntry(DBusString(k), v is DBusVariant ? v : DBusVariant(v))));

    var lnks = DBusDict(
        DBusSignature('s'),
        DBusSignature('v'),
        links.map((k, v) =>
            MapEntry(DBusString(k), v is DBusVariant ? v : DBusVariant(v))));

    return DBusStruct([attrs, lnks]);
  }
}
