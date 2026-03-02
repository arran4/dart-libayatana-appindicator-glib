import 'dart:async';
import 'package:dbus/dbus.dart';

void main() async {
  final client = DBusClient.session();
  try {
     await client.requestName('org.test.foo');
     print('success');
  } catch (e) {
     print('fail: $e');
  } finally {
     await client.close();
  }
}
