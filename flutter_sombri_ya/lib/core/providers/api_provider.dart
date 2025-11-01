import 'dart:convert';
import 'package:http/http.dart' as http;

class _CacheEntry {
  final http.Response response;
  final DateTime ts;
  _CacheEntry(this.response) : ts = DateTime.now();
}

class ApiProvider {
  final String baseUrl;
  final _cache = <String, _CacheEntry>{};

  ApiProvider({required this.baseUrl});

  Future<http.Response> post(
      String path, {
        Map<String, String>? headers,
        Object? body,
      }) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.Response> getCached(
      String path, {
        Duration ttl = const Duration(minutes: 10),
        Map<String, String>? headers,
        bool forceRefresh = false,
      }) async {
    final url = '$baseUrl$path';
    final key = _cacheKey('GET', url, headers);

    if (!forceRefresh && _cache.containsKey(key)) {
      final entry = _cache[key]!;
      final fresh = DateTime.now().difference(entry.ts) < ttl;
      if (fresh) return entry.response;
    }

    final resp = await http.get(Uri.parse(url), headers: headers);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      _cache[key] = _CacheEntry(resp);
    }
    return resp;
  }

  void invalidate(String path, {Map<String, String>? headers}) {
    final key = _cacheKey('GET', '$baseUrl$path', headers);
    _cache.remove(key);
  }

  void clearCache() => _cache.clear();

  String _cacheKey(String method, String url, Map<String, String>? headers) {
    final auth = headers?['Authorization'] ?? '';
    return '$method $url #$auth';
  }
}
