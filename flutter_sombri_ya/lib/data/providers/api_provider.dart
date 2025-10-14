import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String _baseUrl = 'https://sombri-ya-back-4def07fa1804.herokuapp.com';

  Future<dynamic> getWithParams(
    String endpoint,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl$endpoint',
    ).replace(queryParameters: params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
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

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(
        '[ApiProvider] Error: Received status ${response.statusCode} | Body: ${response.body}',
      );
      throw Exception('Failed to load data from API.');
    }
  }
}
