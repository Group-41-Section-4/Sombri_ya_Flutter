import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String _baseUrl = 'https://sombri-ya-back-4def07fa1804.herokuapp.com';
  static const _timeout = Duration(seconds: 15);

  String get baseUrl => _baseUrl;

  dynamic decodeJson(String bdy) => json.decode(bdy);

  /// GET genérico con query params opcionales
  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? queryParameters,
      }) async {
    final uri = Uri.parse('$_baseUrl$endpoint')
        .replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  /// Mantengo getWithParams por compatibilidad, pero ahora usa get()
  Future<dynamic> getWithParams(
      String endpoint,
      Map<String, String> params,
      ) {
    return get(endpoint, queryParameters: params);
  }

  Future<dynamic> getWithBody(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final request = http.Request('GET', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = json.encode(body);

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<dynamic> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final mergedHeaders = <String, String>{
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      };

      final response = await http
          .post(
        uri,
        headers: mergedHeaders,
        body: body == null ? null : json.encode(body),
      )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
