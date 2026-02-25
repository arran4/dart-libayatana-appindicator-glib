import 'package:dbus/dbus.dart';

void main() {
  final s = DBusStruct([DBusString('test')]);
  print(s);
  // Try to find how to access it
  // print(s.values); // This failed analysis
  // Try children
  // print(s.children); 
}
