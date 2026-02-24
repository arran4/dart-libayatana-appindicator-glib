// This file was generated using the following command and may be overwritten.
// dart-dbus generate-object notification-item.xml

import 'package:dbus/dbus.dart';

class StatusNotifierItem extends DBusObject {
  /// Creates a new object to expose on [path].
  StatusNotifierItem({DBusObjectPath path = const DBusObjectPath.unchecked('/StatusNotifierItem')}) : super(path);

  String id = '';
  String category = '';
  String status = '';
  String iconName = '';
  String iconAccessibleDesc = '';
  String attentionIconName = '';
  String attentionAccessibleDesc = '';
  String title = '';
  String iconThemePath = '';
  DBusObjectPath menu = DBusObjectPath.root;
  String xAyatanaLabel = '';
  String xAyatanaLabelGuide = '';
  int xAyatanaOrderingIndex = 0;
  DBusStruct toolTip = DBusStruct([
    DBusString(''),
    DBusArray(DBusSignature('(iiay)'), []),
    DBusString(''),
    DBusString(''),
  ]);

  /// Gets value of property org.kde.StatusNotifierItem.Id
  Future<DBusMethodResponse> getId() async {
    return DBusMethodSuccessResponse([DBusString(id)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.Category
  Future<DBusMethodResponse> getCategory() async {
    return DBusMethodSuccessResponse([DBusString(category)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.Status
  Future<DBusMethodResponse> getStatus() async {
    return DBusMethodSuccessResponse([DBusString(status)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.IconName
  Future<DBusMethodResponse> getIconName() async {
    return DBusMethodSuccessResponse([DBusString(iconName)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.IconAccessibleDesc
  Future<DBusMethodResponse> getIconAccessibleDesc() async {
    return DBusMethodSuccessResponse([DBusString(iconAccessibleDesc)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.AttentionIconName
  Future<DBusMethodResponse> getAttentionIconName() async {
    return DBusMethodSuccessResponse([DBusString(attentionIconName)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.AttentionAccessibleDesc
  Future<DBusMethodResponse> getAttentionAccessibleDesc() async {
    return DBusMethodSuccessResponse([DBusString(attentionAccessibleDesc)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.Title
  Future<DBusMethodResponse> getTitle() async {
    return DBusMethodSuccessResponse([DBusString(title)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.IconThemePath
  Future<DBusMethodResponse> getIconThemePath() async {
    return DBusMethodSuccessResponse([DBusString(iconThemePath)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.Menu
  Future<DBusMethodResponse> getMenu() async {
    return DBusMethodSuccessResponse([menu]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.XAyatanaLabel
  Future<DBusMethodResponse> getXAyatanaLabel() async {
    return DBusMethodSuccessResponse([DBusString(xAyatanaLabel)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.XAyatanaLabelGuide
  Future<DBusMethodResponse> getXAyatanaLabelGuide() async {
    return DBusMethodSuccessResponse([DBusString(xAyatanaLabelGuide)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.XAyatanaOrderingIndex
  Future<DBusMethodResponse> getXAyatanaOrderingIndex() async {
    return DBusMethodSuccessResponse([DBusUint32(xAyatanaOrderingIndex)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.ToolTip
  Future<DBusMethodResponse> getToolTip() async {
    return DBusMethodSuccessResponse([toolTip]);
  }

  /// Implementation of org.kde.StatusNotifierItem.Scroll()
  Future<DBusMethodResponse> doScroll(int delta, String orientation) async {
    return DBusMethodSuccessResponse([]);
  }

  /// Implementation of org.kde.StatusNotifierItem.SecondaryActivate()
  Future<DBusMethodResponse> doSecondaryActivate(int x, int y) async {
    return DBusMethodSuccessResponse([]);
  }

  /// Implementation of org.kde.StatusNotifierItem.XAyatanaSecondaryActivate()
  Future<DBusMethodResponse> doXAyatanaSecondaryActivate(int timestamp) async {
    return DBusMethodSuccessResponse([]);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewIcon
  Future<void> emitNewIcon() async {
     await emitSignal('org.kde.StatusNotifierItem', 'NewIcon', []);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewIconThemePath
  Future<void> emitNewIconThemePath(String icon_theme_path) async {
     await emitSignal('org.kde.StatusNotifierItem', 'NewIconThemePath', [DBusString(icon_theme_path)]);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewAttentionIcon
  Future<void> emitNewAttentionIcon() async {
     await emitSignal('org.kde.StatusNotifierItem', 'NewAttentionIcon', []);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewStatus
  Future<void> emitNewStatus(String status) async {
     await emitSignal('org.kde.StatusNotifierItem', 'NewStatus', [DBusString(status)]);
  }

  /// Emits signal org.kde.StatusNotifierItem.XAyatanaNewLabel
  Future<void> emitXAyatanaNewLabel(String label, String guide) async {
     await emitSignal('org.kde.StatusNotifierItem', 'XAyatanaNewLabel', [DBusString(label), DBusString(guide)]);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewTitle
  Future<void> emitNewTitle() async {
     await emitSignal('org.kde.StatusNotifierItem', 'NewTitle', []);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewToolTip
  Future<void> emitNewToolTip() async {
     await emitSignal('org.kde.StatusNotifierItem', 'NewToolTip', []);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [DBusIntrospectInterface('org.kde.StatusNotifierItem', methods: [DBusIntrospectMethod('Scroll', args: [DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'delta'), DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'orientation')]), DBusIntrospectMethod('SecondaryActivate', args: [DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'x'), DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'y')]), DBusIntrospectMethod('XAyatanaSecondaryActivate', args: [DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.in_, name: 'timestamp')])], signals: [DBusIntrospectSignal('NewIcon'), DBusIntrospectSignal('NewIconThemePath', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out, name: 'icon_theme_path')]), DBusIntrospectSignal('NewAttentionIcon'), DBusIntrospectSignal('NewStatus', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out, name: 'status')]), DBusIntrospectSignal('XAyatanaNewLabel', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out, name: 'label'), DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out, name: 'guide')]), DBusIntrospectSignal('NewTitle'), DBusIntrospectSignal('NewToolTip')], properties: [DBusIntrospectProperty('Id', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('Category', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('Status', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('IconName', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('IconAccessibleDesc', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('AttentionIconName', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('AttentionAccessibleDesc', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('Title', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('IconThemePath', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('Menu', DBusSignature('o'), access: DBusPropertyAccess.read), DBusIntrospectProperty('XAyatanaLabel', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('XAyatanaLabelGuide', DBusSignature('s'), access: DBusPropertyAccess.read), DBusIntrospectProperty('XAyatanaOrderingIndex', DBusSignature('u'), access: DBusPropertyAccess.read), DBusIntrospectProperty('ToolTip', DBusSignature('(sa(iiay)ss)'), access: DBusPropertyAccess.read)])];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierItem') {
      if (methodCall.name == 'Scroll') {
        if (methodCall.signature != DBusSignature('is')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doScroll(methodCall.values[0].asInt32(), methodCall.values[1].asString());
      } else if (methodCall.name == 'SecondaryActivate') {
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doSecondaryActivate(methodCall.values[0].asInt32(), methodCall.values[1].asInt32());
      } else if (methodCall.name == 'XAyatanaSecondaryActivate') {
        if (methodCall.signature != DBusSignature('u')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doXAyatanaSecondaryActivate(methodCall.values[0].asUint32());
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.kde.StatusNotifierItem') {
      if (name == 'Id') {
        return getId();
      } else if (name == 'Category') {
        return getCategory();
      } else if (name == 'Status') {
        return getStatus();
      } else if (name == 'IconName') {
        return getIconName();
      } else if (name == 'IconAccessibleDesc') {
        return getIconAccessibleDesc();
      } else if (name == 'AttentionIconName') {
        return getAttentionIconName();
      } else if (name == 'AttentionAccessibleDesc') {
        return getAttentionAccessibleDesc();
      } else if (name == 'Title') {
        return getTitle();
      } else if (name == 'IconThemePath') {
        return getIconThemePath();
      } else if (name == 'Menu') {
        return getMenu();
      } else if (name == 'XAyatanaLabel') {
        return getXAyatanaLabel();
      } else if (name == 'XAyatanaLabelGuide') {
        return getXAyatanaLabelGuide();
      } else if (name == 'XAyatanaOrderingIndex') {
        return getXAyatanaOrderingIndex();
      } else if (name == 'ToolTip') {
        return getToolTip();
      } else {
        return DBusMethodErrorResponse.unknownProperty();
      }
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> setProperty(String interface, String name, DBusValue value) async {
    if (interface == 'org.kde.StatusNotifierItem') {
      if (name == 'Id') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'Category') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'Status') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'IconName') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'IconAccessibleDesc') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'AttentionIconName') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'AttentionAccessibleDesc') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'Title') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'IconThemePath') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'Menu') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'XAyatanaLabel') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'XAyatanaLabelGuide') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'XAyatanaOrderingIndex') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else if (name == 'ToolTip') {
        return DBusMethodErrorResponse.propertyReadOnly();
      } else {
        return DBusMethodErrorResponse.unknownProperty();
      }
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{};
    if (interface == 'org.kde.StatusNotifierItem') {
      properties['Id'] = (await getId()).returnValues[0];
      properties['Category'] = (await getCategory()).returnValues[0];
      properties['Status'] = (await getStatus()).returnValues[0];
      properties['IconName'] = (await getIconName()).returnValues[0];
      properties['IconAccessibleDesc'] = (await getIconAccessibleDesc()).returnValues[0];
      properties['AttentionIconName'] = (await getAttentionIconName()).returnValues[0];
      properties['AttentionAccessibleDesc'] = (await getAttentionAccessibleDesc()).returnValues[0];
      properties['Title'] = (await getTitle()).returnValues[0];
      properties['IconThemePath'] = (await getIconThemePath()).returnValues[0];
      properties['Menu'] = (await getMenu()).returnValues[0];
      properties['XAyatanaLabel'] = (await getXAyatanaLabel()).returnValues[0];
      properties['XAyatanaLabelGuide'] = (await getXAyatanaLabelGuide()).returnValues[0];
      properties['XAyatanaOrderingIndex'] = (await getXAyatanaOrderingIndex()).returnValues[0];
      properties['ToolTip'] = (await getToolTip()).returnValues[0];
    }
    return DBusMethodSuccessResponse([DBusDict.stringVariant(properties)]);
  }
}
