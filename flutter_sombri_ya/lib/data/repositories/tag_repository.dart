import 'dart:convert';
import 'package:http/http.dart' as http;

class TagRepository {
  final String baseUrl;
  final String authToken;
  const TagRepository({required this.baseUrl, required this.authToken});

  /// GET /tags/{uid}/station  -> 200 => {place_name: ...}, 404 => no asociada
  Future<Map<String, dynamic>?> getTagStation(String uid) async {
    final url = Uri.parse('$baseUrl/tags/$uid/station');
    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $authToken',
    });
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    if (resp.statusCode == 404) return null;
    throw Exception('Error (${resp.statusCode}): ${resp.body}');
  }

  /// POST /stations/{stationId}/tags
  Future<void> assignTagToStation({
    required String uid,
    required String stationId,
  }) async {
    final url = Uri.parse('$baseUrl/stations/$stationId/tags');
    final body = jsonEncode({
      'tag_uid': uid,
      'tag_type': 'NFC-A',
      'meta': {'registered_from': 'app'},
    });
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: body,
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Error (${resp.statusCode}): ${resp.body}');
    }
  }
}
