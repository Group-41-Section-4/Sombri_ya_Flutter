import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  static const _kLastEmail = 'auth.lastEmail';
  static const _kRememberEmail = 'auth.rememberEmail';

  final SharedPreferences _sp;
  LocalPrefs(this._sp);

  static Future<LocalPrefs> create() async {
    final sp = await SharedPreferences.getInstance();
    return LocalPrefs(sp);
  }

  String? getLastEmail() => _sp.getString(_kLastEmail);
  bool getRememberEmail() => _sp.getBool(_kRememberEmail) ?? true;

  Future<void> setLastEmail(String email) => _sp.setString(_kLastEmail, email);
  Future<void> clearLastEmail() => _sp.remove(_kLastEmail);

  Future<void> setRememberEmail(bool value) => _sp.setBool(_kRememberEmail, value);
}
