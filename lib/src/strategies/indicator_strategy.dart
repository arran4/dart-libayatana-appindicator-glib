import '../common.dart';
import '../dbus_menu.dart';
import '../enums.dart';

abstract class IndicatorStrategy {
  Future<void> connect({String? watcherName, String? watcherPath});
  Future<void> close();

  // Property updates
  Future<void> updateStatus(AppIndicatorStatus status);
  Future<void> updateIconName(String iconName);
  Future<void> updateAttentionIconName(String iconName);
  Future<void> updateIconThemePath(String iconThemePath);
  Future<void> updateTitle(String title);
  Future<void> updateLabel(String label, String guide);
  Future<void> updateTooltip(String title, String description);
  Future<void> updateItemIsMenu(bool itemIsMenu);
  Future<void> updateWindowId(int windowId);
  Future<void> updateIconPixmaps(List<IconPixmap> pixmaps);
  Future<void> updateAttentionIconPixmaps(List<IconPixmap> pixmaps);
  Future<void> updateOverlayIconName(String iconName);
  Future<void> updateOverlayIconPixmaps(List<IconPixmap> pixmaps);
  Future<void> updateAttentionMovieName(String movieName);

  // Menu updates
  void updateMenu(List<DBusMenuItem> items);

  // Queries
  bool get isWatcherAvailable;
  Future<bool> isStatusNotifierHostRegistered();

  // Validation
  Future<List<String>> validate();

  // Event callbacks
  set onScroll(void Function(int delta, String orientation)? callback);
  set onSecondaryActivate(void Function(int x, int y)? callback);
  set onXAyatanaSecondaryActivate(void Function(int timestamp)? callback);
  set onActivate(void Function(int x, int y)? callback);
  set onContextMenu(void Function(int x, int y)? callback);
  set onXAyatanaActivate(void Function(int x, int y, int timestamp)? callback);

  // Testing helpers
  Future<void> dispatchActivate({int x = 0, int y = 0});
  Future<void> dispatchSecondaryActivate({int x = 0, int y = 0});
  Future<void> dispatchContextMenu({int x = 0, int y = 0});
  Future<void> dispatchScroll({int delta = 0, String orientation = 'vertical'});
}
