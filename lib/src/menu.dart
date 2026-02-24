import 'package:dbus/dbus.dart';

class DBusMenu extends DBusObject {
  final Map<int, List<DBusMenuItem>> _menus = {};
  int _nextMenuId = 0;

  DBusMenu(DBusObjectPath path) : super(path);

  int addMenu(List<DBusMenuItem> items) {
    var id = _nextMenuId++;
    _menus[id] = items;
    // Emit Changed signal? Ideally.
    return id;
  }

  void setMenu(int id, List<DBusMenuItem> items) {
    _menus[id] = items;
    // Emit Changed
  }

  void clear() {
    _menus.clear();
    _nextMenuId = 0;
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
    // var groups = parameters[0]; // au
    // Return all menus

    var menusList = <DBusValue>[];

    for (var entry in _menus.entries) {
      var menuId = entry.key;
      var items = entry.value;

      var dbusItems = items.map((item) => item.toDBus()).toList();

      menusList.add(DBusStruct([
        DBusUint32(0), // Group ID
        DBusUint32(menuId),
        DBusArray(DBusSignature('(a{sv}a{sv})'), dbusItems),
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
        attributes.map((k, v) => MapEntry(
            DBusString(k), v is DBusVariant ? v : DBusVariant(v))));

    var lnks = DBusDict(
        DBusSignature('s'),
        DBusSignature('v'),
        links.map((k, v) => MapEntry(
            DBusString(k), v is DBusVariant ? v : DBusVariant(v))));

    return DBusStruct([attrs, lnks]);
  }
}
