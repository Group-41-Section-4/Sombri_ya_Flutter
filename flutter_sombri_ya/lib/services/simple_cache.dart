import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleCache {
  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> getJson(String key) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(key);
    return (s == null) ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> remove(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(key);
  }
}
