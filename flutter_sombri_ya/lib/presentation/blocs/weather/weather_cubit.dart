import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/weather_models.dart';
import '../../../services/weather_service.dart';
import '../../../services/location_service.dart' as myloc;

class WeatherCubit extends Cubit<SimpleWeather?> {
  final WeatherService weather;
  Timer? _timer;

  static const _kCode  = 'weather_code';
  static const _kNight = 'weather_is_night';

  static const _kWxPrefix = 'cache:weather:fb:';

  Duration _ttl = const Duration(minutes: 10);

  WeatherCubit({required this.weather}) : super(null) {
    _restoreFromLocalPrefs();
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[WeatherCubit] $msg');
  }

  Future<void> start({
    Duration every = const Duration(minutes: 15),
    Duration ttl = const Duration(minutes: 10),
  }) async {
    _ttl = ttl;
    _log('start(every=${every.inMinutes}m, ttl=${ttl.inMinutes}m)');
    await _tickCacheFirst();

    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => _tickCacheFirst());
  }

  Future<void> refreshAt({required double lat, required double lon}) async {
    try {
      _log('refreshAt(lat=${lat.toStringAsFixed(3)}, lon=${lon.toStringAsFixed(3)}) → FORCE network');
      final brief = await weather.refreshForecast(lat, lon);
      if (brief == null) {
        _log('refreshAt → brief=null');
        return;
      }

      final cond = brief.willRain
          ? WeatherCondition.rain
          : conditionFromOpenWeather(brief.code);
      final prevIsNight = state?.isNight ?? await _readNightFromLocalPrefs() ?? false;

      final effective = SimpleWeather(
        condition: cond,
        isNight: prevIsNight,
        code: brief.willRain ? 500 : brief.code,
      );

      await _saveToLocalPrefs(effective);
      _log('emit (refresh) cond=${effective.condition} code=${effective.code} night=${effective.isNight}');
      emit(effective);
    } catch (e, st) {
      _log('refreshAt error: $e\n$st');
    }
  }

  /// Try to emit from current state; else from local prefs.
  Future<void> emitFromCachedForecastOrState() async {
    if (state != null) {
      _log('emitFromCachedForecastOrState → using in-memory state');
      emit(state);
      return;
    }
    final sp = await SharedPreferences.getInstance();
    final code = sp.getInt(_kCode);
    final isNight = sp.getBool(_kNight);
    if (code != null && isNight != null) {
      _log('emitFromCachedForecastOrState → using local prefs (code=$code night=$isNight)');
      emit(SimpleWeather(
        condition: conditionFromOpenWeather(code),
        isNight: isNight,
        code: code,
      ));
    } else {
      _log('emitFromCachedForecastOrState → no local prefs available');
    }
  }

  Future<void> _tickCacheFirst() async {
    try {
      final pos = await myloc.LocationService.getPosition();
      if (pos == null) {
        _log('no position available');
        return;
      }

      final lat = pos.latitude;
      final lon = pos.longitude;
      _log('tick at lat=${lat.toStringAsFixed(3)}, lon=${lon.toStringAsFixed(3)}, ttl=${_ttl.inMinutes}m');

      final brief = await weather.getForecastBrief(lat, lon, ttl: _ttl);
      if (brief == null) {
        _log(' brief=null (no forecast)');
        return;
      }

      final cond = brief.willRain
          ? WeatherCondition.rain
          : conditionFromOpenWeather(brief.code);

      final prevIsNight = state?.isNight ?? await _readNightFromLocalPrefs() ?? false;

      final effective = SimpleWeather(
        condition: cond,
        isNight: prevIsNight,
        code: brief.willRain ? 500 : brief.code,
      );

      await _saveToLocalPrefs(effective);
      _log('emit (tick) cond=${effective.condition} code=${effective.code} night=${effective.isNight}');
      emit(effective);
    } catch (e, st) {
      _log('_tickCacheFirst error: $e\n$st');
    }
  }

  Future<void> _saveToLocalPrefs(SimpleWeather w) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kCode, w.code);
    await sp.setBool(_kNight, w.isNight);
    _log('saved local prefs: code=${w.code}, night=${w.isNight}');
  }

  Future<bool?> _readNightFromLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kNight);
  }

  Future<void> _restoreFromLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getInt(_kCode);
    final isNight = sp.getBool(_kNight);
    if (code != null && isNight != null) {
      _log('restored from local prefs: code=$code night=$isNight');
      emit(SimpleWeather(
        condition: conditionFromOpenWeather(code),
        isNight: isNight,
        code: code,
      ));
    } else {
      _log('no local prefs to restore');
    }
  }

  Future<void> debugDumpLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getInt(_kCode);
    final night = sp.getBool(_kNight);
    _log('🗃️ LOCAL PREFS → code=$code night=$night');
  }

  Future<void> debugDumpWeatherCache({double? lat, double? lon}) async {
    final sp = await SharedPreferences.getInstance();
    final keys = sp.getKeys().where((k) => k.startsWith(_kWxPrefix)).toList()
      ..sort();
    for (final k in keys) {
      final raw = sp.getString(k);
      final ts = sp.getInt('$k#ts');
      String mini = 'invalid';
      if (raw != null) {
        try {
          final m = json.decode(raw) as Map<String, dynamic>;
          mini = 'pop=${m['pop']} code=${m['code']} will=${m['willRain']}';
        } catch (_) {/* ignore */}
      }
      final age = ts == null
          ? 'no-ts'
          : '${DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000)).inSeconds}s';
    }

    if (lat != null && lon != null) {
      final latKey = lat.toStringAsFixed(3);
      final lonKey = lon.toStringAsFixed(3);
      final k = '$_kWxPrefix$latKey,$lonKey';
      final hit = sp.getString(k) != null;
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    return super.close();
  }
}
