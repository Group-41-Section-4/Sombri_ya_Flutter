import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProfileRepository {
  static const _base = 'https://sombri-ya-back-4def07fa1804.herokuapp.com';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final uri = Uri.parse('$_base/auth/me');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception('Error getProfile: ${resp.statusCode} ${resp.body}');
    }
    return (json.decode(resp.body) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateField({
    required String userId,
    required String fieldKey,
    required String newValue,
  }) async {
    final uri = Uri.parse('$_base/users/$userId');
    final resp = await http.put(
      uri,
      headers: await _headers(),
      body: json.encode({fieldKey: newValue}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Error updateField: ${resp.statusCode} ${resp.body}');
    }
    return (json.decode(resp.body) as Map).cast<String, dynamic>();
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_base/users/change-password');
    final resp = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode({
        'user_id': userId,
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Error changePassword: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<double> getTotalDistance(String userId) async {
    final uri = Uri.parse('$_base/users/$userId/total-distance');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
        'Error getTotalDistance: ${resp.statusCode} ${resp.body}',
      );
    }
    final map = (json.decode(resp.body) as Map).cast<String, dynamic>();
    return (map['totalDistanceKm'] as num).toDouble();
  }

  Future<void> addPedometerDistance(double distanceKm) async {
    final uri = Uri.parse('$_base/users/me/add-distance');

    final resp = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode({'distanceKm': distanceKm}),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Error addPedometerDistance: ${resp.statusCode} ${resp.body}',
      );
    }
  }
}
