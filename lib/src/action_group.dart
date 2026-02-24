import 'package:dbus/dbus.dart';

class DBusActionGroup extends DBusObject {
  final Map<String, DBusAction> _actions = {};

  DBusActionGroup(DBusObjectPath path) : super(path);

  void addAction(DBusAction action) {
    action._onStateChanged =
        (state) => _emitActionStateChanged(action.name, state);
    action._onEnabledChanged =
        (enabled) => _emitActionEnabledChanged(action.name, enabled);
    _actions[action.name] = action;
    _emitActionAdded(action);
  }

  void clearActions() {
    if (_actions.isEmpty) {
      return;
    }

    var removed = _actions.keys.toList();
    _actions.clear();
    _emitActionsChanged(removed: removed);
  }

  DBusAction? getAction(String name) => _actions[name];

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'org.gtk.Actions',
        methods: [
          DBusIntrospectMethod('Describe', args: [
            DBusIntrospectArgument(
                DBusSignature('s'), DBusArgumentDirection.in_,
                name: 'action_name'),
            DBusIntrospectArgument(
                DBusSignature('(bgav)'), DBusArgumentDirection.out,
                name: 'description')
          ]),
          DBusIntrospectMethod('DescribeAll', args: [
            DBusIntrospectArgument(
                DBusSignature('a{s(bgav)}'), DBusArgumentDirection.out,
                name: 'descriptions')
          ]),
          DBusIntrospectMethod('SetState', args: [
            DBusIntrospectArgument(
                DBusSignature('s'), DBusArgumentDirection.in_,
                name: 'action_name'),
            DBusIntrospectArgument(
                DBusSignature('v'), DBusArgumentDirection.in_,
                name: 'value')
          ]),
          DBusIntrospectMethod('Activate', args: [
            DBusIntrospectArgument(
                DBusSignature('s'), DBusArgumentDirection.in_,
                name: 'action_name'),
            DBusIntrospectArgument(
                DBusSignature('av'), DBusArgumentDirection.in_,
                name: 'parameter'),
            DBusIntrospectArgument(
                DBusSignature('a{sv}'), DBusArgumentDirection.in_,
                name: 'platform_data')
          ]),
        ],
        signals: [
          DBusIntrospectSignal('Changed', args: [
            DBusIntrospectArgument(
                DBusSignature('as'), DBusArgumentDirection.out,
                name: 'removed'),
            DBusIntrospectArgument(
                DBusSignature('a{sb}'), DBusArgumentDirection.out,
                name: 'enabled_changed'),
            DBusIntrospectArgument(
                DBusSignature('a{sv}'), DBusArgumentDirection.out,
                name: 'state_changed'),
            DBusIntrospectArgument(
                DBusSignature('a{s(bgav)}'), DBusArgumentDirection.out,
                name: 'added'),
          ]),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.gtk.Actions') {
      if (methodCall.name == 'Describe') {
        if (methodCall.signature != DBusSignature('s')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return _handleDescribe(methodCall.values);
      } else if (methodCall.name == 'DescribeAll') {
        if (methodCall.signature != DBusSignature('')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return _handleDescribeAll(methodCall.values);
      } else if (methodCall.name == 'SetState') {
        if (methodCall.signature != DBusSignature('sv')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return _handleSetState(methodCall.values);
      } else if (methodCall.name == 'Activate') {
        if (methodCall.signature != DBusSignature('sava{sv}')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return _handleActivate(methodCall.values);
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    }
    return DBusMethodErrorResponse.unknownInterface();
  }

  Future<DBusMethodResponse> _handleDescribe(List<DBusValue> parameters) async {
    var name = parameters[0].asString();
    var action = _actions[name];
    if (action == null) {
      return DBusMethodErrorResponse.unknownMethod();
    }
    return DBusMethodSuccessResponse([
      DBusStruct([
        DBusBoolean(action.enabled),
        DBusSignature(action.parameterType ?? ''),
        DBusArray(DBusSignature('v'),
            action.state != null ? [DBusVariant(action.state!)] : []),
      ])
    ]);
  }

  Future<DBusMethodResponse> _handleDescribeAll(
      List<DBusValue> parameters) async {
    var descriptions = <DBusValue, DBusValue>{};
    for (var entry in _actions.entries) {
      descriptions[DBusString(entry.key)] = DBusStruct([
        DBusBoolean(entry.value.enabled),
        DBusSignature(entry.value.parameterType ?? ''),
        DBusArray(DBusSignature('v'),
            entry.value.state != null ? [DBusVariant(entry.value.state!)] : []),
      ]);
    }
    return DBusMethodSuccessResponse(
        [DBusDict(DBusSignature('s'), DBusSignature('(bgav)'), descriptions)]);
  }

  Future<DBusMethodResponse> _handleSetState(List<DBusValue> parameters) async {
    var name = parameters[0].asString();
    var value = parameters[1]; // variant

    var action = _actions[name];
    if (action == null) return DBusMethodErrorResponse.unknownMethod();
    if (action.state == null) return DBusMethodErrorResponse.invalidArgs();

    if (value is DBusVariant) {
      action.changeState(value.value);
    } else {
      return DBusMethodErrorResponse.invalidArgs();
    }

    return DBusMethodSuccessResponse([]);
  }

  Future<DBusMethodResponse> _handleActivate(List<DBusValue> parameters) async {
    var name = parameters[0].asString();
    var params = parameters[1]; // av - array of variants
    // var platformData = parameters[2]; // a{sv}

    var action = _actions[name];
    if (action == null) return DBusMethodErrorResponse.unknownMethod();

    DBusValue? param;
    if (params is DBusArray && params.children.isNotEmpty) {
      var v = params.children.first;
      if (v is DBusVariant) {
        param = v.value;
      } else {
        param = v;
      }
    }

    action.activate(param);
    return DBusMethodSuccessResponse([]);
  }

  Future<void> _emitActionAdded(DBusAction action) async {
    await _emitActionsChanged(added: {action.name: _describeAction(action)});
  }

  Future<void> _emitActionStateChanged(String name, DBusValue state) async {
    await _emitActionsChanged(stateChanged: {name: DBusVariant(state)});
  }

  Future<void> _emitActionEnabledChanged(String name, bool enabled) async {
    await _emitActionsChanged(enabledChanged: {name: DBusBoolean(enabled)});
  }

  DBusStruct _describeAction(DBusAction action) {
    return DBusStruct([
      DBusBoolean(action.enabled),
      DBusSignature(action.parameterType ?? ''),
      DBusArray(DBusSignature('v'),
          action.state != null ? [DBusVariant(action.state!)] : []),
    ]);
  }

  Future<void> _emitActionsChanged(
      {List<String> removed = const [],
      Map<String, DBusBoolean> enabledChanged = const {},
      Map<String, DBusVariant> stateChanged = const {},
      Map<String, DBusStruct> added = const {}}) async {
    await emitSignal('org.gtk.Actions', 'Changed', [
      DBusArray(
          DBusSignature('s'), removed.map((name) => DBusString(name)).toList()),
      DBusDict(DBusSignature('s'), DBusSignature('b'),
          enabledChanged.map((k, v) => MapEntry(DBusString(k), v))),
      DBusDict(DBusSignature('s'), DBusSignature('v'),
          stateChanged.map((k, v) => MapEntry(DBusString(k), v))),
      DBusDict(DBusSignature('s'), DBusSignature('(bgav)'),
          added.map((k, v) => MapEntry(DBusString(k), v))),
    ]);
  }
}

class DBusAction {
  final String name;
  bool enabled;
  final String? parameterType; // Signature string
  DBusValue? state;
  final Function(DBusValue?)? onActivate;
  final Function(DBusValue)? onStateChange;
  Function(DBusValue)? _onStateChanged;
  Function(bool)? _onEnabledChanged;

  DBusAction(this.name,
      {this.enabled = true,
      this.parameterType,
      this.state,
      this.onActivate,
      this.onStateChange});

  void activate(DBusValue? parameter) {
    if (onActivate != null) onActivate!(parameter);
  }

  void setEnabled(bool value) {
    enabled = value;
    if (_onEnabledChanged != null) {
      _onEnabledChanged!(value);
    }
  }

  void changeState(DBusValue newState) {
    if (state != null) {
      state = newState;
      if (onStateChange != null) onStateChange!(newState);
      if (_onStateChanged != null) _onStateChanged!(newState);
    }
  }
}
