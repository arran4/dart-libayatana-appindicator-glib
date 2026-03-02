import 'package:dbus/dbus.dart';

/// Event arguments for scroll events.
class ScrollEvent {
  final int delta;
  final String orientation;

  const ScrollEvent(this.delta, this.orientation);
}

/// Event arguments for secondary activation.
class SecondaryActivateEvent {
  final int x;
  final int y;
  final int timestamp;

  const SecondaryActivateEvent(this.x, this.y, [this.timestamp = 0]);
}

/// Event arguments for primary activation.
class ActivateEvent {
  final int x;
  final int y;

  const ActivateEvent(this.x, this.y);
}

/// Event arguments for context menu activation.
class ContextMenuEvent {
  final int x;
  final int y;

  const ContextMenuEvent(this.x, this.y);
}

/// Event arguments for XAyatana primary activation.
class XAyatanaActivateEvent {
  final int x;
  final int y;
  final int timestamp;

  const XAyatanaActivateEvent(this.x, this.y, this.timestamp);
}

/// A structure representing a pixel map of an icon.
class IconPixmap {
  final int width;
  final int height;
  final List<int> argb32Bytes;

  const IconPixmap({
    required this.width,
    required this.height,
    required this.argb32Bytes,
  });

  DBusValue toDBus() {
    return DBusStruct([
      DBusInt32(width),
      DBusInt32(height),
      DBusArray.byte(argb32Bytes),
    ]);
  }
}
