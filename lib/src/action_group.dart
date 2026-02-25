import 'package:dbus/dbus.dart';

class DBusActionGroup extends DBusObject {
  final Map<String, DBusAction> _actions = {};

  DBusActionGroup(DBusObjectPath path) : super(path);

  void addAction(DBusAction action) {
    _actions[action.name] = action;
  }

  void clearActions() {
    _actions.clear();
  }

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
                name: 'description'),
          ]),
          DBusIntrospectMethod('DescribeAll', args: [
            DBusIntrospectArgument(
                DBusSignature('a{s(bgav)}'), DBusArgumentDirection.out,
                name: 'descriptions'),
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
                name: 'platform_data'),
          ]),
          DBusIntrospectMethod('SetState', args: [
            DBusIntrospectArgument(
                DBusSignature('s'), DBusArgumentDirection.in_,
                name: 'action_name'),
            DBusIntrospectArgument(
                DBusSignature('v'), DBusArgumentDirection.in_,
                name: 'value'),
          ]),
        ],
      )
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.gtk.Actions') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (methodCall.name == 'SetState') {
      return _handleSetState(methodCall.values);
    } else if (methodCall.name == 'Describe') {
      final name = methodCall.values[0].asString();
      final action = _actions[name];
      if (action == null) {
        return DBusMethodErrorResponse
            .unknownMethod(); // Or a more specific error
      }
      return DBusMethodSuccessResponse([action.toDescription()]);
    } else if (methodCall.name == 'Activate') {
      final name = methodCall.values[0].asString();
      final parameter = methodCall.values[1] as DBusArray;
      final action = _actions[name];
      if (action != null) {
        action.onActivate?.call(parameter.children);
      }
      return DBusMethodSuccessResponse([]);
    }

    return DBusMethodErrorResponse.unknownMethod();
  }

  Future<DBusMethodResponse> _handleSetState(List<DBusValue> parameters) async {
    if (parameters.length != 2) {
      return DBusMethodErrorResponse.invalidArgs();
    }
    if (parameters[0] is! DBusString) {
      return DBusMethodErrorResponse.invalidArgs();
    }
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
}

class DBusAction {
  final String name;
  bool _enabled;
  DBusValue? _state;
  final void Function(List<DBusValue>)? onActivate;

  DBusAction(this.name,
      {bool enabled = true, DBusValue? state, this.onActivate})
      : _enabled = enabled,
        _state = state;

  DBusValue? get state => _state;

  void setEnabled(bool value) {
    _enabled = value;
  }

  void changeState(DBusValue value) {
    _state = value;
  }

  DBusValue toDescription() {
    final sigStr = _state?.signature.toString() ?? '';
    final match = RegExp(r"DBusSignature\('(.+)'\)").firstMatch(sigStr);
    final sig = match?.group(1) ?? '';
    return DBusStruct([
      DBusBoolean(_enabled),
      DBusSignature(sig),
      DBusArray(
          DBusSignature('v'), _state != null ? [DBusVariant(_state!)] : []),
    ]);
  }
}
