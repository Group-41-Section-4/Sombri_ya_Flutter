
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_sombri_ya/config/openweather_config.dart';
import '../data/models/weather_models.dart';

class WeatherService {
  final String apiKey;
  WeatherService({required this.apiKey});

  static const _baseUrl = 'https://api.openweathermap.org/data/3.0/onecall';

  Future<bool> willRainNextHour(double lat, double lng) async {
    if (OpenWeatherConfig.weatherTestingForceRain) return false;

    final uri = Uri.parse(
      '$_baseUrl?lat=$lat&lon=$lng&exclude=current,daily,alerts&units=metric&appid=$apiKey',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return false;

    final data = json.decode(resp.body);
    if (data['minutely'] is List) {
      final mins = List<Map<String, dynamic>>.from(data['minutely']);
      final anyPrecip = mins.take(60).any((m) {
        final p = (m['precipitation'] ?? 0);
        if (p is num) return p > 0;
        if (p is String) return double.tryParse(p) != null && double.parse(p) > 0;
        return false;
      });
      if (anyPrecip) return true;
    }
    if (data['hourly'] is List && (data['hourly'] as List).isNotEmpty) {
      final h0 = Map<String, dynamic>.from(data['hourly'][0]);
      final pop = (h0['pop'] is num) ? (h0['pop'] as num).toDouble() : 0.0;
      if (pop >= 0.20) return true;
      if (h0['weather'] is List && (h0['weather'] as List).isNotEmpty) {
        final code = (h0['weather'][0]['id'] as num?)?.toInt() ?? 0;
        if (code >= 200 && code < 600) return true;
      }
      if (h0['rain'] is Map && h0['rain']['1h'] != null) {
        final r = h0['rain']['1h'];
        final mm = (r is num) ? r.toDouble() : double.tryParse(r.toString()) ?? 0.0;
        if (mm > 0) return true;
      }
    }
    return false;
  }


  Future<SimpleWeather?> snapshot(double lat, double lng) async {
    final uri = Uri.parse(
      '$_baseUrl?lat=$lat&lon=$lng&exclude=minutely,daily,alerts&units=metric&appid=$apiKey',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;

    final data = json.decode(resp.body) as Map<String, dynamic>;

    final current = Map<String, dynamic>.from(data['current'] ?? {});
    final dt = (current['dt'] as num?)?.toInt();
    final sunrise = (current['sunrise'] as num?)?.toInt();
    final sunset = (current['sunset'] as num?)?.toInt();
    final bool isNight = (dt != null && sunrise != null && sunset != null)
        ? (dt < sunrise || dt > sunset)
        : false;

    int code = 800;
    if (current['weather'] is List && (current['weather'] as List).isNotEmpty) {
      code = (current['weather'][0]['id'] as num?)?.toInt() ?? 800;
    } else if (data['hourly'] is List && (data['hourly'] as List).isNotEmpty) {
      final h0 = Map<String, dynamic>.from(data['hourly'][0]);
      if (h0['weather'] is List && (h0['weather'] as List).isNotEmpty) {
        code = (h0['weather'][0]['id'] as num?)?.toInt() ?? 800;
      }
    }

    return SimpleWeather(
      condition: conditionFromOpenWeather(code),
      isNight: isNight,
      code: code,
    );
  }
}
