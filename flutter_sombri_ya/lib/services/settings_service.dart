import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kUnits = 'prefs:units';
  static const _kLang = 'prefs:lang';
  static const _kAutoDark = 'prefs:auto_dark';
  static const _kLastCity = 'prefs:last_city';

  Future<String> getUnits() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUnits) ?? 'metric';
  }

  Future<void> setUnits(String units) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUnits, units);
  }

  Future<String> getLanguage() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLang) ?? 'es';
  }

  Future<void> setLanguage(String lang) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLang, lang);
  }

  Future<bool> getAutoDark() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kAutoDark) ?? true;
  }

  Future<void> setAutoDark(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAutoDark, value);
  }

  Future<String?> getLastCity() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLastCity);
  }

  Future<void> setLastCity(String city) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastCity, city);
  }
}
