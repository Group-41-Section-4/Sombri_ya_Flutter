import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final storage = const FlutterSecureStorage();
  final baseUrl = "https://TU-BACKEND.herokuapp.com";

  Future<http.Response> getStations() async {
    final token = await storage.read(key: "auth_token");

    return http.get(
      Uri.parse("$baseUrl/stations"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }
}
