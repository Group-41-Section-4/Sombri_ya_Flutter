import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String baseUrl;
  ApiProvider({required this.baseUrl});

  Future<http.Response> post(String path, {Map<String, String>? headers, Object? body}) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }


}
