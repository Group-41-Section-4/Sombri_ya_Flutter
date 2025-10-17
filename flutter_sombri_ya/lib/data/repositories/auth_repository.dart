import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;

import '../../core/providers/api_provider.dart';
import '../../core/services/secure_storage_service.dart';

class AuthRepository {
  final ApiProvider api;
  final SecureStorageService storage;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required this.api,
    required this.storage,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<({String token, String userId})> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final http.Response resp = await api.post(
      '/auth/login/password',
      body: {'email': email, 'password': password},
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final decoded = JwtDecoder.decode(token);
      final userId = decoded['sub'] as String;

      await storage.saveToken(token);
      await storage.saveUserId(userId);

      return (token: token, userId: userId);
    } else {
      throw AuthException('Correo o contraseña incorrectos');
    }
  }

  Future<({String token, String userId})> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Inicio con Google cancelado');
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw AuthException('No se obtuvo idToken de Google');
    }

    final http.Response resp = await api.post(
      '/auth/login/google',
      body: {'idToken': idToken},
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final decoded = JwtDecoder.decode(token);
      final userId = decoded['sub'] as String;

      await storage.saveToken(token);
      await storage.saveUserId(userId);

      return (token: token, userId: userId);
    } else {
      throw AuthException('Error al iniciar con Google (${resp.statusCode})');
    }
  }

  Future<void> register({
    required String email,
    required String name,
    required String password,
    required bool biometricEnabled,
  }) async {
    final http.Response resp = await api.post(
      '/auth/register',
      body: {
        'email': email,
        'name': name,
        'password': password,
        'biometric_enabled': biometricEnabled,
      },
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw AuthException('Error al registrarse, intenta nuevamente');
    }
  }

  Future<void> logout() => storage.clear();
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
