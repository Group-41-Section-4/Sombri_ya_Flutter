import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    'pop': pop, 'code': code, 'rainMm': rainMm, 'willRain': willRain,
  };

  static ForecastBrief fromJson(Map<String, dynamic> j) => ForecastBrief(
    pop: (j['pop'] as num?)?.toDouble() ?? 0.0,
    code: (j['code'] as num?)?.toInt() ?? 800,
    rainMm: (j['rainMm'] as num?)?.toDouble() ?? 0.0,
    willRain: j['willRain'] == true,
  );
}

class WeatherService {
  WeatherService({String? apiKey, this.debug = true})
      : apiKey = (apiKey ?? kOpenWeatherApiKey).trim();

  final String apiKey;
  final bool debug;

  void _log(String msg) {
    if (debug && kDebugMode) debugPrint('[WeatherCache] $msg');
  }

  static const _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  static String _cacheKey(double lat, double lon) {
    final latKey = lat.toStringAsFixed(3);
    final lonKey = lon.toStringAsFixed(3);
    return 'cache:weather:fb:$latKey,$lonKey';
  }

  static String _tsKey(String base) => '$base#ts';

  Future<ForecastBrief?> getForecastBrief(double lat,
      double lon, {
        Duration ttl = const Duration(minutes: 10),
        bool forceRefresh = false,
        String lang = 'es',
        String units = 'metric',
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(lat, lon);
    final tkey = _tsKey(key);

    if (!forceRefresh) {
      final cached = _readBrief(prefs, key);
      final ts = prefs.getInt(tkey);
      if (cached != null && ts != null) {
        final age = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
        if (age <= ttl) {
          _log('HIT (fresh) key=$key  age=${age.inSeconds}s  ️pop=${cached
              .pop}  code=${cached.code}');
          return cached;
        } else {
          _log('🕰HIT (stale) key=$key  age=${age.inMinutes}m → fetching…');
        }
      } else {
        _log('MISS key=$key (no cache entry)');
      }
    } else {
      _log('FORCE REFRESH key=$key');
    }

    final net = await _fetch(lat, lon, lang: lang, units: units);
    if (net != null) {
      await _saveBrief(prefs, key, net);
      return net;
    }

    final fallback = _readBrief(prefs, key);
    if (fallback != null) {
      _log('↩FALLBACK STALE key=$key (serving cached data while offline)');
    } else {
      _log('NO CACHE AVAILABLE key=$key (network failed & no local)');
    }
    return fallback;
  }

  Future<ForecastBrief?> refreshForecast(double lat,
      double lon, {
        String lang = 'es',
        String units = 'metric',
      }) =>
      getForecastBrief(lat, lon, forceRefresh: true, lang: lang, units: units);

  Future<bool> willRainNextHour(double lat,
      double lon, {
        Duration ttl = const Duration(minutes: 10),
      }) async {
    final b = await getForecastBrief(lat, lon, ttl: ttl);
    return b?.willRain ?? false;
  }

  Future<void> invalidate(double lat, double lon) async {
    final sp = await SharedPreferences.getInstance();
    final k = _cacheKey(lat, lon);
    await sp.remove(k);
    await sp.remove(_tsKey(k));
    _log('INVALIDATE key=$k');
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    final keys = sp.getKeys().where((k) => k.startsWith('cache:weather:fb:'));
    int n = 0;
    for (final k in keys) {
      await sp.remove(k);
      await sp.remove(_tsKey(k));
      n++;
    }
  }

  Future<void> dumpCacheSummary() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final keys = sp.getKeys().where((k) => k.startsWith('cache:weather:fb:')).toList()
      ..sort();
    for (final k in keys) {
      final ts = sp.getInt(_tsKey(k));
      final age = ts == null
          ? 'no-ts'
          : '${now.difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000)).inSeconds}s';
      final raw = sp.getString(k);
      String mini = 'invalid-json';
      if (raw != null) {
        try {
          final m = json.decode(raw) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
  }

  Future<void> peekLocation(double lat, double lon) async {
    final sp = await SharedPreferences.getInstance();
    final key = _cacheKey(lat, lon);
    final ts = sp.getInt(_tsKey(key));
    final present = sp.getString(key) != null;
  }


  Future<ForecastBrief?> _fetch(
      double lat,
      double lon, {
        String lang = 'es',
        String units = 'metric',
      }) async {
    final url = Uri.parse(_forecastUrl).replace(queryParameters: {
      'lat': lat.toStringAsFixed(3),
      'lon': lon.toStringAsFixed(3),
      'appid': apiKey,
      'lang': lang,
      'units': units,
    });

    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        _log('HTTP ${resp.statusCode} for $url');
        return null;
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final list = (data['list'] as List?) ?? const [];
      if (list.isEmpty) {
        return null;
      }

      final first = Map<String, dynamic>.from(list.first);
      final pop = (first['pop'] is num) ? (first['pop'] as num).toDouble() : 0.0;

      int code = 800;
      if (first['weather'] is List && (first['weather'] as List).isNotEmpty) {
        code = (first['weather'][0]['id'] as num?)?.toInt() ?? 800;
      }

      double rainMm = 0.0;
      if (first['rain'] is Map && first['rain']['3h'] != null) {
        final r = first['rain']['3h'];
        rainMm = (r is num) ? r.toDouble() : double.tryParse(r.toString()) ?? 0.0;
      }

      final will = pop >= 0.20 || rainMm > 0 || (code >= 200 && code < 600);
      return ForecastBrief(pop: pop, code: code, rainMm: rainMm, willRain: will);
    } catch (e) {
      _log('Network error: $e');
      return null;
    }
  }

  ForecastBrief? _readBrief(SharedPreferences sp, String key) {
    final raw = sp.getString(key);
    if (raw == null) return null;
    try {
      return ForecastBrief.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveBrief(
      SharedPreferences sp,
      String key,
      ForecastBrief brief,
      ) async {
    await sp.setString(key, json.encode(brief.toJson()));
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await sp.setInt(_tsKey(key), nowSec);
  }
}
