import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/gps_coord.dart';
import '../models/rental_model.dart';

class Api {
  static const String baseUrl =
      "https://sombri-ya-back-4def07fa1804.herokuapp.com";

  final storage = const FlutterSecureStorage();

  /// Método genérico para obtener headers con el token
  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: "auth_token");
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  /// Inicia una renta
  Future<Rental> startRental({
    required String userId,
    required String stationStartId,
    required GpsCoord startGps,
    required String authType,
  }) async {
    final url = Uri.parse("$baseUrl/rentals/start");
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "user_id": userId,
        "station_start_id": stationStartId,
        "start_gps": startGps.toJson(),
        "auth_type": authType,
      }),
    );

    print("📡 startRental status=${response.statusCode}");
    print("📡 startRental body=${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Rental.fromJson(data);
    } else {
      final msg = _safeMessage(response.body);
      throw Exception("Error al iniciar renta: $msg");
    }
  }

  /// Finaliza una renta
  Future<Rental> endRental({
    required String userId,
    required String stationEndId,
    required GpsCoord endGps,
  }) async {
    final url = Uri.parse("$baseUrl/rentals/end");
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'user_id': userId, 'station_end_id': stationEndId}),
    );

    print("📡 endRental status=${response.statusCode}");
    print("📡 endRental body=${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Rental.fromJson(data);
    } else {
      final msg = _safeMessage(response.body);
      throw Exception("Error al finalizar renta: $msg");
    }
  }

  /// Consultar las estaciones cercanas
  Future<List<dynamic>> getStationsNearby() async {
    final url = Uri.parse("$baseUrl/stations/nearby");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    print("📡 getStationsNearby status=${response.statusCode}");
    print("📡 getStationsNearby body=${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener estaciones: ${response.body}");
    }
  }

  /// Consultar renta activa del usuario
  Future<Rental?> getActiveRental(String userId) async {
    final url = Uri.parse("$baseUrl/rentals/user/$userId?status=ongoing");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    print("📡 getActiveRental status=${response.statusCode}");
    print("📡 getActiveRental body=${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isEmpty) return null;
      return Rental.fromJson(data.first);
    } else {
      throw Exception("Error al obtener renta activa: ${response.body}");
    }
  }

  String _safeMessage(String body) {
    try {
      final m = jsonDecode(body);
      return m['message']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }
}
