import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
  WeatherService({
    String? apiKey,
    this.debug = true,
    CacheManager? cache,
    Duration? jsonStalePeriod,
  })  : apiKey = (apiKey ?? kOpenWeatherApiKey).trim(),
        _cm = cache ??
            CacheManager(
              Config(
                'weather_json_cache',
                stalePeriod: jsonStalePeriod ?? const Duration(hours: 12),
                maxNrOfCacheObjects: 64,
                repo: JsonCacheInfoRepository(databaseName: 'weather_json_cache.db'),
                fileService: HttpFileService(),
              ),
            );

  final String apiKey;
  final bool debug;
  final CacheManager _cm;

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

  static String _cmKey(double lat, double lon, {String units = 'metric', String lang = 'es'}) {
    final latKey = lat.toStringAsFixed(3);
    final lonKey = lon.toStringAsFixed(3);
    return 'openweather:forecast:$latKey,$lonKey:$units:$lang.json';
  }

  Future<ForecastBrief?> getForecastBrief(
      double lat,
      double lon, {
        Duration ttl = const Duration(minutes: 10),
        bool forceRefresh = false,
        String lang = 'es',
        String units = 'metric',
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final spKey = _cacheKey(lat, lon);
    final tkey = _tsKey(spKey);
    final cmKey = _cmKey(lat, lon, units: units, lang: lang);

    if (!forceRefresh) {
      final cached = _readBrief(prefs, spKey);
      final ts = prefs.getInt(tkey);
      if (cached != null && ts != null) {
        final age =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
        if (age <= ttl) {
          _log('HIT (fresh) SP key=$spKey age=${age.inSeconds}s pop=${cached.pop} code=${cached.code}');
          return cached;
        } else {
          _log('HIT (stale) SP key=$spKey age=${age.inMinutes}m → probar CacheManager');
        }
      } else {
        _log('MISS SP key=$spKey');
      }

      final cmFile = await _cm.getFileFromCache(cmKey);
      if (cmFile != null && !cmFile.validTill.isBefore(DateTime.now())) {
        try {
          final txt = await cmFile.file.readAsString();
          final map = json.decode(txt) as Map<String, dynamic>;
          final b = _briefFromForecastJson(map);
          if (b != null) {
            _log('HIT (fresh) CM key=$cmKey validTill=${cmFile.validTill.toIso8601String()}');
            await _saveBrief(prefs, spKey, b);
            return b;
          }
        } catch (e, st) {
          _log('CM READ ERROR key=$cmKey err=$e');
          if (e is FormatException || e is FileSystemException) {
            try {
              await _cm.removeFile(cmKey);
            } catch (_) {}
          }
        }
      } else {
        _log('MISS/STALE CM key=$cmKey');
      }
    } else {
      _log('FORCE REFRESH key=$spKey / $cmKey');
    }

    _log('NET FETCH start $cmKey');
    final netJson = await _fetchRaw(lat, lon, lang: lang, units: units);
    _log('NET FETCH done $cmKey ok=${netJson != null}');
    if (netJson != null) {
      _log('CM PUT start $cmKey');
      await _cm.putFile(
        cmKey,
        utf8.encode(json.encode(netJson)),
        fileExtension: 'json',
      );
      _log('CM PUT done $cmKey');

      final b = _briefFromForecastJson(netJson);
      if (b != null) {
        await _saveBrief(prefs, spKey, b);
        _log('SAVE SP+CM sp=$spKey cm=$cmKey pop=${b.pop} code=${b.code}');
        return b;
      }
    }

    final spStale = _readBrief(prefs, spKey);
    if (spStale != null) {
      _log('FALLBACK STALE SP key=$spKey');
      return spStale;
    }
    final cmAny = await _cm.getFileFromCache(cmKey);
    if (cmAny != null) {
      try {
        final txt = await cmAny.file.readAsString();
        final map = json.decode(txt) as Map<String, dynamic>;
        final b = _briefFromForecastJson(map);
        if (b != null) {
          _log('FALLBACK STALE CM key=$cmKey');
          return b;
        }
      } catch (e, st) {
        _log('CM READ ERROR (fallback) key=$cmKey err=$e');
        if (e is FormatException || e is FileSystemException) {
          try {
            await _cm.removeFile(cmKey);
          } catch (_) {}
        }
      }
    }

    _log('NO CACHE AVAILABLE key=$spKey / $cmKey');
    return null;
  }

  Future<ForecastBrief?> refreshForecast(
      double lat,
      double lon, {
        String lang = 'es',
        String units = 'metric',
      }) =>
      getForecastBrief(lat, lon, forceRefresh: true, lang: lang, units: units);

  Future<bool> willRainNextHour(
      double lat,
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
    final cmKey = _cmKey(lat, lon);
    await _cm.removeFile(cmKey);
    _log('INVALIDATE sp=$k cm=$cmKey');
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
    await _cm.emptyCache();
    _log('CLEAR ALL (SP $n entries removed, CM cleared)');
  }

  Future<void> dumpCacheSummary() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final keys =
    sp.getKeys().where((k) => k.startsWith('cache:weather:fb:')).toList()
      ..sort();
    _log('DUMP (${keys.length} items)');
    for (final k in keys) {
      final ts = sp.getInt(_tsKey(k));
      final age = ts == null
          ? 'no-ts'
          : '${now.difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000)).inSeconds}s';
      _log(' - $k age=$age');
    }
  }

  Future<void> peekLocation(double lat, double lon) async {
    final sp = await SharedPreferences.getInstance();
    final key = _cacheKey(lat, lon);
    final ts = sp.getInt(_tsKey(key));
    final present = sp.getString(key) != null;
    _log('PEEK SP key=$key  present=$present  ts=$ts');

    final cmKey = _cmKey(lat, lon);
    final cmFile = await _cm.getFileFromCache(cmKey);
    _log('PEEK CM key=$cmKey present=${cmFile != null} validTill=${cmFile?.validTill}');
  }

  Future<Map<String, dynamic>?> _fetchRaw(
      double lat,
      double lon, {
        required String lang,
        required String units,
      }) async {
    final url = Uri.parse(_forecastUrl).replace(queryParameters: {
      'lat': lat.toStringAsFixed(3),
      'lon': lon.toStringAsFixed(3),
      'appid': apiKey,
      'lang': lang,
      'units': units,
    });

    const timeouts = [Duration(seconds: 8), Duration(seconds: 12), Duration(seconds: 20)];
    for (var i = 0; i < timeouts.length; i++) {
      final t = timeouts[i];
      try {
        _log('HTTP try #${i + 1} ${t.inSeconds}s → $url');
        final resp = await http.get(url).timeout(t);
        _log('HTTP resp #${i + 1}: ${resp.statusCode} len=${resp.bodyBytes.length}');
        if (resp.statusCode == 200) {
          return json.decode(resp.body) as Map<String, dynamic>;
        }
      } on TimeoutException {
        _log('HTTP timeout #${i + 1} after ${t.inSeconds}s');
      } catch (e) {
        _log('Network error try #${i + 1}: $e');
      }

      if (i < timeouts.length - 1) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    return null;
  }


  ForecastBrief? _briefFromForecastJson(Map<String, dynamic> data) {
    final list = (data['list'] as List?) ?? const [];
    if (list.isEmpty) {
      _log('Empty forecast list');
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
    _log('TS SET key=${_tsKey(key)} ts=$nowSec');
  }
}
