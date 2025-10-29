import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../providers/api_provider.dart';
import '../models/rental_model.dart';

class RentalRepository {
  final ApiProvider _apiProvider = ApiProvider();
  final FlutterSecureStorage storage;

  RentalRepository({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();

  Future<List<Rental>> getOngoingRentals(String userId) async {
    return _fetchRentals(userId, 'ongoing');
  }

  Future<List<Rental>> getCompletedRentals(String userId) async {
    return _fetchRentals(userId, 'completed');
  }

  Future<List<Rental>> _fetchRentals(String userId, String status) async {
    final List<dynamic> data = await _apiProvider.getWithParams(
      '/rentals', 
      {'user_id': userId, 'status': status},
    );
    return data.map((json) => Rental.fromJson(json)).toList();
  }

  Future<String?> readUserId() => storage.read(key: "user_id");
  Future<String?> readLocalRentalId() => storage.read(key: "rental_id");

  Future<void> writeLocalRentalId(String id) =>
      storage.write(key: "rental_id", value: id);

  Future<void> clearLocalRentalId() => storage.delete(key: "rental_id");

  Future<String?> syncLocalWithBackend() async {
    final userId = await readUserId();
    if (userId == null) return null;

    final backId = await getActiveRentalIdFromBackend(userId);
    if (backId != null) {
      await writeLocalRentalId(backId);
      return backId;
    } else {
      await clearLocalRentalId();
      return null;
    }
  }

  Future<String?> getActiveRentalIdFromBackend(String userId) async {
    try {
      final dynamic data = await _apiProvider.getWithParams(
        '/rentals',
        {'user_id': userId, 'status': 'ongoing'},
      );

      if (data is List && data.isNotEmpty) {
        final first = data.first;
        final id = (first is Map && first['id'] != null) ? first['id'].toString() : null;
        return (id != null && id.isNotEmpty) ? id : null;
      }
      return null; 
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('404') || msg.contains('not found')) return null;
      rethrow;
    }
  }

  Future<String> startRentalWithStation({
    required String userId,
    required String stationId,
    required String authType, 
  }) async {
    try {
      final dynamic data = await _apiProvider.post(
        '/rentals/start',
        body: {
          'user_id': userId,
          'station_start_id': stationId,
          'auth_type': authType,
        },
      );

      String? id;
      if (data is Map && data['id'] != null) {
        id = data['id'].toString();
      }
      if (id == null || id.isEmpty) {
        id = await getActiveRentalIdFromBackend(userId);
      }
      if (id == null || id.isEmpty) {
        throw Exception('No pude obtener el ID de la renta desde el backend.');
      }
      return id;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final alreadyActive = msg.contains('already has an active rental');
      final notFound404 = msg.contains('http 404') || msg.contains('"statuscode":404') || msg.contains('not found');

      if (alreadyActive || notFound404) {
        final existing = await getActiveRentalIdFromBackend(userId);
        if (existing != null && existing.isNotEmpty) {
          await writeLocalRentalId(existing);
          return existing;
        }
        throw Exception('El usuario ya tiene una renta activa, pero no pude leer su ID.');
      }

      rethrow;
    }
  }


  Future<String?> stationIdByTagUid(String uid) async {

    final token = await storage.read(key: 'auth_token');
    final url = Uri.parse('${_apiProvider.baseUrl}/tags/$uid/station');

    final resp = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);

      final id = (data is Map && data['id'] != null) ? data['id'].toString() : null;
      return (id != null && id.isNotEmpty) ? id : null;
    }
    if (resp.statusCode == 404) {
      return null;
    }
    throw Exception('Error resolviendo tag ($uid): ${resp.statusCode} ${resp.body}');
  }

  Future<void> endRental({
    required String userId,
    required String stationEndId,
  }) async {
    await _apiProvider.post(
      '/rentals/end',
      body: {
        'user_id': userId,
        'station_end_id': stationEndId,
      },
    );
  }
}
