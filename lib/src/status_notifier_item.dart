// This file was generated using the following command and may be overwritten.
// dart-dbus generate-object notification-item.xml

import 'package:dbus/dbus.dart';

class StatusNotifierItem extends DBusObject {
  static const kInterface = 'org.kde.StatusNotifierItem';
  static const kFreedesktopInterface = 'org.freedesktop.StatusNotifierItem';

  /// Creates a new object to expose on [path].
  StatusNotifierItem(
      {DBusObjectPath path =
          const DBusObjectPath.unchecked('/StatusNotifierItem')})
      : super(path);

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
  int windowId = 0;
  bool itemIsMenu = false;
  List<DBusValue> iconPixmap = [];
  List<DBusValue> attentionIconPixmap = [];
  String overlayIconName = '';
  String overlayIconAccessibleDesc = '';
  List<DBusValue> overlayIconPixmap = [];
  String attentionMovieName = '';

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

  /// Gets value of property org.kde.StatusNotifierItem.WindowId
  Future<DBusMethodResponse> getWindowId() async {
    return DBusMethodSuccessResponse([DBusUint32(windowId)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.ItemIsMenu
  Future<DBusMethodResponse> getItemIsMenu() async {
    return DBusMethodSuccessResponse([DBusBoolean(itemIsMenu)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.IconPixmap
  Future<DBusMethodResponse> getIconPixmap() async {
    return DBusMethodSuccessResponse(
        [DBusArray(DBusSignature('(iiay)'), iconPixmap)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.AttentionIconPixmap
  Future<DBusMethodResponse> getAttentionIconPixmap() async {
    return DBusMethodSuccessResponse(
        [DBusArray(DBusSignature('(iiay)'), attentionIconPixmap)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.OverlayIconName
  Future<DBusMethodResponse> getOverlayIconName() async {
    return DBusMethodSuccessResponse([DBusString(overlayIconName)]);
  }

  /// Gets value of property
  /// org.kde.StatusNotifierItem.OverlayIconAccessibleDesc
  Future<DBusMethodResponse> getOverlayIconAccessibleDesc() async {
    return DBusMethodSuccessResponse([DBusString(overlayIconAccessibleDesc)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.OverlayIconPixmap
  Future<DBusMethodResponse> getOverlayIconPixmap() async {
    return DBusMethodSuccessResponse(
        [DBusArray(DBusSignature('(iiay)'), overlayIconPixmap)]);
  }

  /// Gets value of property org.kde.StatusNotifierItem.AttentionMovieName
  Future<DBusMethodResponse> getAttentionMovieName() async {
    return DBusMethodSuccessResponse([DBusString(attentionMovieName)]);
  }

  /// Implementation of org.kde.StatusNotifierItem.Activate()
  Future<DBusMethodResponse> doActivate(int x, int y) async {
    return DBusMethodSuccessResponse([]);
  }

  /// Implementation of org.kde.StatusNotifierItem.ContextMenu()
  Future<DBusMethodResponse> doContextMenu(int x, int y) async {
    return DBusMethodSuccessResponse([]);
  }

  /// Implementation of org.kde.StatusNotifierItem.XAyatanaActivate()
  Future<DBusMethodResponse> doXAyatanaActivate(
      int x, int y, int timestamp) async {
    return DBusMethodSuccessResponse([]);
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
    await emitSignal(StatusNotifierItem.kInterface, 'NewIcon', []);
    await emitSignal(StatusNotifierItem.kFreedesktopInterface, 'NewIcon', []);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewIconThemePath
  Future<void> emitNewIconThemePath(String iconThemePath) async {
    await emitSignal(StatusNotifierItem.kInterface, 'NewIconThemePath',
        [DBusString(iconThemePath)]);
    await emitSignal(StatusNotifierItem.kFreedesktopInterface, 'NewIconThemePath',
        [DBusString(iconThemePath)]);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewAttentionIcon
  Future<void> emitNewAttentionIcon() async {
    await emitSignal(StatusNotifierItem.kInterface, 'NewAttentionIcon', []);
    await emitSignal(
        StatusNotifierItem.kFreedesktopInterface, 'NewAttentionIcon', []);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewStatus
  Future<void> emitNewStatus(String status) async {
    await emitSignal(
        StatusNotifierItem.kInterface, 'NewStatus', [DBusString(status)]);
    await emitSignal(StatusNotifierItem.kFreedesktopInterface, 'NewStatus',
        [DBusString(status)]);
  }

  /// Emits signal org.kde.StatusNotifierItem.XAyatanaNewLabel
  Future<void> emitXAyatanaNewLabel(String label, String guide) async {
    await emitSignal(StatusNotifierItem.kInterface, 'XAyatanaNewLabel',
        [DBusString(label), DBusString(guide)]);
    await emitSignal(StatusNotifierItem.kFreedesktopInterface, 'XAyatanaNewLabel',
        [DBusString(label), DBusString(guide)]);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewTitle
  Future<void> emitNewTitle() async {
    await emitSignal(StatusNotifierItem.kInterface, 'NewTitle', []);
    await emitSignal(StatusNotifierItem.kFreedesktopInterface, 'NewTitle', []);
  }

  /// Emits signal org.kde.StatusNotifierItem.NewToolTip
  Future<void> emitNewToolTip() async {
    await emitSignal(StatusNotifierItem.kInterface, 'NewToolTip', []);
    await emitSignal(StatusNotifierItem.kFreedesktopInterface, 'NewToolTip', []);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    final kdeInterface =
        DBusIntrospectInterface(StatusNotifierItem.kInterface, methods: [
      DBusIntrospectMethod('Scroll', args: [
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'delta'),
        DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_,
            name: 'orientation')
      ]),
      DBusIntrospectMethod('SecondaryActivate', args: [
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'x'),
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'y')
      ]),
      DBusIntrospectMethod('XAyatanaSecondaryActivate', args: [
        DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.in_,
            name: 'timestamp')
      ]),
      DBusIntrospectMethod('Activate', args: [
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'x'),
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'y')
      ]),
      DBusIntrospectMethod('ContextMenu', args: [
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'x'),
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'y')
      ]),
      DBusIntrospectMethod('XAyatanaActivate', args: [
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'x'),
        DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_,
            name: 'y'),
        DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.in_,
            name: 'timestamp')
      ])
    ], signals: [
      DBusIntrospectSignal('NewIcon'),
      DBusIntrospectSignal('NewIconThemePath', args: [
        DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out,
            name: 'icon_theme_path')
      ]),
      DBusIntrospectSignal('NewAttentionIcon'),
      DBusIntrospectSignal('NewStatus', args: [
        DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out,
            name: 'status')
      ]),
      DBusIntrospectSignal('XAyatanaNewLabel', args: [
        DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out,
            name: 'label'),
        DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out,
            name: 'guide')
      ]),
      DBusIntrospectSignal('NewTitle'),
      DBusIntrospectSignal('NewToolTip')
    ], properties: [
      DBusIntrospectProperty('Id', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('Category', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('Status', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('IconName', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('IconAccessibleDesc', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('AttentionIconName', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('AttentionAccessibleDesc', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('Title', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('IconThemePath', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('Menu', DBusSignature('o'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('XAyatanaLabel', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('XAyatanaLabelGuide', DBusSignature('s'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('XAyatanaOrderingIndex', DBusSignature('u'),
          access: DBusPropertyAccess.read),
      DBusIntrospectProperty('ToolTip', DBusSignature('(sa(iiay)ss)'),
          access: DBusPropertyAccess.read),
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
          access: DBusPropertyAccess.read)
    ]);
    return [
      kdeInterface,
      DBusIntrospectInterface(StatusNotifierItem.kFreedesktopInterface,
          methods: kdeInterface.methods,
          signals: kdeInterface.signals,
          properties: kdeInterface.properties)
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == StatusNotifierItem.kInterface ||
        methodCall.interface == StatusNotifierItem.kFreedesktopInterface) {
      if (methodCall.name == 'Scroll') {
        if (methodCall.signature != DBusSignature('is')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doScroll(
            methodCall.values[0].asInt32(), methodCall.values[1].asString());
      } else if (methodCall.name == 'SecondaryActivate') {
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doSecondaryActivate(
            methodCall.values[0].asInt32(), methodCall.values[1].asInt32());
      } else if (methodCall.name == 'XAyatanaSecondaryActivate') {
        if (methodCall.signature != DBusSignature('u')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doXAyatanaSecondaryActivate(methodCall.values[0].asUint32());
      } else if (methodCall.name == 'Activate') {
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doActivate(
            methodCall.values[0].asInt32(), methodCall.values[1].asInt32());
      } else if (methodCall.name == 'ContextMenu') {
        if (methodCall.signature != DBusSignature('ii')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doContextMenu(
            methodCall.values[0].asInt32(), methodCall.values[1].asInt32());
      } else if (methodCall.name == 'XAyatanaActivate') {
        if (methodCall.signature != DBusSignature('iiu')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doXAyatanaActivate(methodCall.values[0].asInt32(),
            methodCall.values[1].asInt32(), methodCall.values[2].asUint32());
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    } else {
      return super.handleMethodCall(methodCall);
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == StatusNotifierItem.kInterface ||
        interface == StatusNotifierItem.kFreedesktopInterface) {
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
      } else if (name == 'WindowId') {
        return getWindowId();
      } else if (name == 'ItemIsMenu') {
        return getItemIsMenu();
      } else if (name == 'IconPixmap') {
        return getIconPixmap();
      } else if (name == 'AttentionIconPixmap') {
        return getAttentionIconPixmap();
      } else if (name == 'OverlayIconName') {
        return getOverlayIconName();
      } else if (name == 'OverlayIconAccessibleDesc') {
        return getOverlayIconAccessibleDesc();
      } else if (name == 'OverlayIconPixmap') {
        return getOverlayIconPixmap();
      } else if (name == 'AttentionMovieName') {
        return getAttentionMovieName();
      } else {
        return DBusMethodErrorResponse.unknownProperty();
      }
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> setProperty(
      String interface, String name, DBusValue value) async {
    if (interface == StatusNotifierItem.kInterface ||
        interface == StatusNotifierItem.kFreedesktopInterface) {
      if (name == 'Id' ||
          name == 'Category' ||
          name == 'Status' ||
          name == 'IconName' ||
          name == 'IconAccessibleDesc' ||
          name == 'AttentionIconName' ||
          name == 'AttentionAccessibleDesc' ||
          name == 'Title' ||
          name == 'IconThemePath' ||
          name == 'Menu' ||
          name == 'XAyatanaLabel' ||
          name == 'XAyatanaLabelGuide' ||
          name == 'XAyatanaOrderingIndex' ||
          name == 'ToolTip' ||
          name == 'WindowId' ||
          name == 'ItemIsMenu' ||
          name == 'IconPixmap' ||
          name == 'AttentionIconPixmap' ||
          name == 'OverlayIconName' ||
          name == 'OverlayIconAccessibleDesc' ||
          name == 'OverlayIconPixmap' ||
          name == 'AttentionMovieName') {
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
    if (interface == StatusNotifierItem.kInterface ||
        interface == StatusNotifierItem.kFreedesktopInterface) {
      properties['Id'] = (await getId()).returnValues[0];
      properties['Category'] = (await getCategory()).returnValues[0];
      properties['Status'] = (await getStatus()).returnValues[0];
      properties['IconName'] = (await getIconName()).returnValues[0];
      properties['IconAccessibleDesc'] =
          (await getIconAccessibleDesc()).returnValues[0];
      properties['AttentionIconName'] =
          (await getAttentionIconName()).returnValues[0];
      properties['AttentionAccessibleDesc'] =
          (await getAttentionAccessibleDesc()).returnValues[0];
      properties['Title'] = (await getTitle()).returnValues[0];
      properties['IconThemePath'] = (await getIconThemePath()).returnValues[0];
      properties['Menu'] = (await getMenu()).returnValues[0];
      properties['XAyatanaLabel'] = (await getXAyatanaLabel()).returnValues[0];
      properties['XAyatanaLabelGuide'] =
          (await getXAyatanaLabelGuide()).returnValues[0];
      properties['XAyatanaOrderingIndex'] =
          (await getXAyatanaOrderingIndex()).returnValues[0];
      properties['ToolTip'] = (await getToolTip()).returnValues[0];
      properties['WindowId'] = (await getWindowId()).returnValues[0];
      properties['ItemIsMenu'] = (await getItemIsMenu()).returnValues[0];
      properties['IconPixmap'] = (await getIconPixmap()).returnValues[0];
      properties['AttentionIconPixmap'] =
          (await getAttentionIconPixmap()).returnValues[0];
      properties['OverlayIconName'] =
          (await getOverlayIconName()).returnValues[0];
      properties['OverlayIconAccessibleDesc'] =
          (await getOverlayIconAccessibleDesc()).returnValues[0];
      properties['OverlayIconPixmap'] =
          (await getOverlayIconPixmap()).returnValues[0];
      properties['AttentionMovieName'] =
          (await getAttentionMovieName()).returnValues[0];
    }
    return DBusMethodSuccessResponse([DBusDict.stringVariant(properties)]);
  }
}
