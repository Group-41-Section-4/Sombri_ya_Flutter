import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  const SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: 'auth_token', value: token);
  Future<void> saveUserId(String userId) => _storage.write(key: 'user_id', value: userId);

  Future<String?> readToken() => _storage.read(key: 'auth_token');
  Future<String?> readUserId() => _storage.read(key: 'user_id');

  Future<void> clear() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
  }
}
