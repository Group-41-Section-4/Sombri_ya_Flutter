import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kOpenWeatherApiKey = "64a018d01eba547f998be6d43c606c80";

class ForecastBrief {
  final double pop;
  final int code;
  final double rainMm;
  final bool willRain;

  const ForecastBrief({
    required this.pop,
    required this.code,
    required this.rainMm,
    required this.willRain,
  });

  bool get suggestDarkTheme =>
      willRain || (code >= 200 && code < 800) || pop >= 0.5;

  Map<String, dynamic> toJson() => {
    'pop': pop,
    'code': code,
    'rainMm': rainMm,
    'willRain': willRain,
  };

  static ForecastBrief fromJson(Map<String, dynamic> j) => ForecastBrief(
    pop: (j['pop'] as num?)?.toDouble() ?? 0.0,
    code: (j['code'] as num?)?.toInt() ?? 800,
    rainMm: (j['rainMm'] as num?)?.toDouble() ?? 0.0,
    willRain: j['willRain'] == true,
  );
}

class WeatherService {
  final String apiKey;
  WeatherService({String? apiKey})
    : apiKey = (apiKey ?? kOpenWeatherApiKey).trim();

  static const _forecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast';

  static const _kForecastBrief = 'ow_forecast_brief_v1';
  static const _kForecastSavedAt = 'ow_forecast_saved_at_epoch';

  static String _mask(String k) {
    if (k.isEmpty) return '<EMPTY>';
    if (k.length <= 8) return '${k.characters.first}***${k.characters.last}';
    return '${k.substring(0, 4)}…${k.substring(k.length - 4)}';
  }

  Future<bool> willRainNextHour(double lat, double lng) async {
    final brief = await fetchAndCacheForecast(lat, lng);
    if (brief == null) return false;
    return brief.willRain;
  }

  Future<ForecastBrief?> fetchAndCacheForecast(double lat, double lng) async {
    final url = Uri.parse(_forecastUrl).replace(
      queryParameters: {
        'lat': '$lat',
        'lon': '$lng',
        'appid': apiKey,
        'lang': 'es',
        'units': 'metric',
      },
    );

    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        final body = resp.body;
        return null;
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final list = (data['list'] as List?) ?? const [];
      if (list.isEmpty) return null;

      final first = Map<String, dynamic>.from(list.first);
      final pop = (first['pop'] is num)
          ? (first['pop'] as num).toDouble()
          : 0.0;

      int code = 800;
      if (first['weather'] is List && (first['weather'] as List).isNotEmpty) {
        code = (first['weather'][0]['id'] as num?)?.toInt() ?? 800;
      }

      double rainMm = 0.0;
      if (first['rain'] is Map && first['rain']['3h'] != null) {
        final r = first['rain']['3h'];
        rainMm = (r is num)
            ? r.toDouble()
            : double.tryParse(r.toString()) ?? 0.0;
      }

      final will = pop >= 0.20 || rainMm > 0 || (code >= 200 && code < 600);
      final brief = ForecastBrief(
        pop: pop,
        code: code,
        rainMm: rainMm,
        willRain: will,
      );

      await _saveForecastBrief(brief);
      return brief;
    } catch (e) {
      return null;
    }
  }

  Future<ForecastBrief?> getCachedForecast() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kForecastBrief);
    if (raw == null) return null;
    try {
      return ForecastBrief.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<int?> getCachedForecastAgeSeconds() async {
    final sp = await SharedPreferences.getInstance();
    final ts = sp.getInt(_kForecastSavedAt);
    if (ts == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - ts;
  }

  Future<void> _saveForecastBrief(ForecastBrief brief) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kForecastBrief, json.encode(brief.toJson()));
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await sp.setInt(_kForecastSavedAt, now);
  }
}
