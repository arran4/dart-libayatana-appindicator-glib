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

/// A singleton class that holds the FFI bindings to libgtk-3.so.0.
/// This ensures we only load the library and look up functions once, lazily.
class _GtkBindings {
  static final _GtkBindings _instance = _GtkBindings._internal();
  factory _GtkBindings() => _instance;

  late final DynamicLibrary _libGtk;
  late final _GtkInitCheckDart gtkInitCheck;
  late final _GtkWindowNewDart gtkWindowNew;
  late final _GtkWidgetShowAllDart gtkWidgetShowAll;
  late final _GtkWidgetShowDart gtkWidgetShow;
  late final _GtkWidgetHideDart gtkWidgetHide;
  late final _GtkWindowCloseDart gtkWindowClose;
  late final _GtkWindowMoveDart gtkWindowMove;

  _GtkBindings._internal() {
    try {
      _libGtk = DynamicLibrary.open('libgtk-3.so.0');
    } catch (e) {
      throw AppWindowException('Failed to load libgtk-3.so.0: $e');
    }

    gtkInitCheck = _libGtk
        .lookupFunction<_GtkInitCheckC, _GtkInitCheckDart>('gtk_init_check');
    gtkWindowNew = _libGtk
        .lookupFunction<_GtkWindowNewC, _GtkWindowNewDart>('gtk_window_new');
    gtkWidgetShowAll =
        _libGtk.lookupFunction<_GtkWidgetShowAllC, _GtkWidgetShowAllDart>(
            'gtk_widget_show_all');
    gtkWidgetShow = _libGtk
        .lookupFunction<_GtkWidgetShowC, _GtkWidgetShowDart>('gtk_widget_show');
    gtkWidgetHide = _libGtk
        .lookupFunction<_GtkWidgetHideC, _GtkWidgetHideDart>('gtk_widget_hide');
    gtkWindowClose =
        _libGtk.lookupFunction<_GtkWindowCloseC, _GtkWindowCloseDart>(
            'gtk_window_close');
    gtkWindowMove = _libGtk
        .lookupFunction<_GtkWindowMoveC, _GtkWindowMoveDart>('gtk_window_move');
  }
}

/// A class for interacting with GTK AppWindow functionality via FFI.
/// This wraps native GTK calls to eliminate C/C++ code on the client side.
class AppWindow {
  late final Pointer<Void> _window;
  final _GtkBindings _gtk = _GtkBindings();

  AppWindow({Pointer<Void>? window}) {
    // Make sure gtk_init_check is called to gracefully handle headless
    if (_gtk.gtkInitCheck(nullptr, nullptr) == 0) {
      throw AppWindowException('gtk_init_check failed.');
    }

    if (window != null) {
      _window = window;
    } else {
      _window = _gtk.gtkWindowNew(0); // GTK_WINDOW_TOPLEVEL
    }
  }

  void show() {
    _gtk.gtkWidgetShow(_window);
  }

  void showAll() {
    _gtk.gtkWidgetShowAll(_window);
  }

  void hide() {
    _gtk.gtkWidgetHide(_window);
  }

  void close() {
    _gtk.gtkWindowClose(_window);
  }

  void move(int x, int y) {
    _gtk.gtkWindowMove(_window, x, y);
  }

  Pointer<Void> get pointer => _window;
}
