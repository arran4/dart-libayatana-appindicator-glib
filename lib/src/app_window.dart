import 'dart:ffi';

import 'package:ffi/ffi.dart';

// Provide basic GTK window management via FFI.

typedef _GtkInitCheckC = Int32 Function(
    Pointer<Int32> argc, Pointer<Pointer<Pointer<Utf8>>> argv);
typedef _GtkInitCheckDart = int Function(
    Pointer<Int32> argc, Pointer<Pointer<Pointer<Utf8>>> argv);

typedef _GtkWindowNewC = Pointer<Void> Function(Int32 type);
typedef _GtkWindowNewDart = Pointer<Void> Function(int type);

typedef _GtkWidgetShowAllC = Void Function(Pointer<Void> widget);
typedef _GtkWidgetShowAllDart = void Function(Pointer<Void> widget);

typedef _GtkWidgetShowC = Void Function(Pointer<Void> widget);
typedef _GtkWidgetShowDart = void Function(Pointer<Void> widget);

typedef _GtkWidgetHideC = Void Function(Pointer<Void> widget);
typedef _GtkWidgetHideDart = void Function(Pointer<Void> widget);

typedef _GtkWindowCloseC = Void Function(Pointer<Void> window);
typedef _GtkWindowCloseDart = void Function(Pointer<Void> window);

typedef _GtkWindowMoveC = Void Function(Pointer<Void> window, Int32 x, Int32 y);
typedef _GtkWindowMoveDart = void Function(Pointer<Void> window, int x, int y);

class AppWindowException implements Exception {
  final String message;
  AppWindowException(this.message);
  @override
  String toString() => 'AppWindowException: $message';
}

/// A class for interacting with GTK AppWindow functionality via FFI.
/// This wraps native GTK calls to eliminate C/C++ code on the client side.
class AppWindow {
  late final DynamicLibrary _libGtk;
  late final Pointer<Void> _window;

  late final _GtkInitCheckDart _gtkInitCheck;
  late final _GtkWindowNewDart _gtkWindowNew;
  late final _GtkWidgetShowAllDart _gtkWidgetShowAll;
  late final _GtkWidgetShowDart _gtkWidgetShow;
  late final _GtkWidgetHideDart _gtkWidgetHide;
  late final _GtkWindowCloseDart _gtkWindowClose;
  late final _GtkWindowMoveDart _gtkWindowMove;

  AppWindow({Pointer<Void>? window}) {
    try {
      _libGtk = DynamicLibrary.open('libgtk-3.so.0');
    } catch (e) {
      throw AppWindowException('Failed to load libgtk-3.so.0: $e');
    }

    _gtkInitCheck = _libGtk
        .lookupFunction<_GtkInitCheckC, _GtkInitCheckDart>('gtk_init_check');
    _gtkWindowNew = _libGtk
        .lookupFunction<_GtkWindowNewC, _GtkWindowNewDart>('gtk_window_new');
    _gtkWidgetShowAll =
        _libGtk.lookupFunction<_GtkWidgetShowAllC, _GtkWidgetShowAllDart>(
            'gtk_widget_show_all');
    _gtkWidgetShow = _libGtk
        .lookupFunction<_GtkWidgetShowC, _GtkWidgetShowDart>('gtk_widget_show');
    _gtkWidgetHide = _libGtk
        .lookupFunction<_GtkWidgetHideC, _GtkWidgetHideDart>('gtk_widget_hide');
    _gtkWindowClose =
        _libGtk.lookupFunction<_GtkWindowCloseC, _GtkWindowCloseDart>(
            'gtk_window_close');
    _gtkWindowMove = _libGtk
        .lookupFunction<_GtkWindowMoveC, _GtkWindowMoveDart>('gtk_window_move');

    // Make sure gtk_init_check is called to gracefully handle headless
    if (_gtkInitCheck(nullptr, nullptr) == 0) {
      throw AppWindowException('gtk_init_check failed.');
    }

    if (window != null) {
      _window = window;
    } else {
      _window = _gtkWindowNew(0); // GTK_WINDOW_TOPLEVEL
    }
  }

  void show() {
    _gtkWidgetShow(_window);
  }

  void showAll() {
    _gtkWidgetShowAll(_window);
  }

  void hide() {
    _gtkWidgetHide(_window);
  }

  void close() {
    _gtkWindowClose(_window);
  }

  void move(int x, int y) {
    _gtkWindowMove(_window, x, y);
  }

  Pointer<Void> get pointer => _window;
}
