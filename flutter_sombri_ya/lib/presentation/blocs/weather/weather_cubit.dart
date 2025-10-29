import 'dart:async';
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

  WeatherCubit({required this.weather}) : super(null) {
    _restoreFromCache();
  }

  Future<void> start({Duration every = const Duration(minutes: 15)}) async {

    await _tickForecastOnly();
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => _tickForecastOnly());
  }

  Future<void> _tickForecastOnly() async {

    try {
      final pos = await myloc.LocationService.getPosition();
      if (pos == null) {

        return;
      }

      final brief = await weather.fetchAndCacheForecast(pos.latitude, pos.longitude);
      if (brief == null) {
        debugPrint('⚠️ brief=null (forecast no disponible)');
        return;
      }

      final cond = brief.willRain ? WeatherCondition.rain : conditionFromOpenWeather(brief.code);

      final prevIsNight = state?.isNight ?? await _readNightFlagFromCache() ?? false;

      final effective = SimpleWeather(
        condition: cond,
        isNight: prevIsNight,
        code: brief.willRain ? 500 : brief.code,
      );

      await _saveToCache(effective);

      emit(effective);
    } catch (e) {

    }
  }


  Future<void> refreshAt({required double lat, required double lon}) async {
    try {
      final brief = await weather.fetchAndCacheForecast(lat, lon);
      if (brief == null) {
        return;
      }
      final cond = brief.willRain ? WeatherCondition.rain : conditionFromOpenWeather(brief.code);
      final prevIsNight = state?.isNight ?? await _readNightFlagFromCache() ?? false;

      final effective = SimpleWeather(
        condition: cond,
        isNight: prevIsNight,
        code: brief.willRain ? 500 : brief.code,
      );

      await _saveToCache(effective);
      emit(effective);
    } catch (e) {
    }
  }

  Future<void> emitFromCachedForecastOrState() async {
    if (state != null) {
      emit(state);
      return;
    }
    final sp = await SharedPreferences.getInstance();
    final code = sp.getInt(_kCode);
    final isNight = sp.getBool(_kNight);
    if (code != null && isNight != null) {
      final s = SimpleWeather(
        condition: conditionFromOpenWeather(code),
        isNight: isNight,
        code: code,
      );
      emit(s);
    } else {

    }
  }

  // =========================== CACHE ===============================
  Future<void> _saveToCache(SimpleWeather w) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kCode, w.code);
    await sp.setBool(_kNight, w.isNight);
  }

  Future<bool?> _readNightFlagFromCache() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kNight);
  }

  Future<void> _restoreFromCache() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getInt(_kCode);
    final isNight = sp.getBool(_kNight);
    if (code != null && isNight != null) {
      final restored = SimpleWeather(
        condition: conditionFromOpenWeather(code),
        isNight: isNight,
        code: code,
      );
      emit(restored);
    } else {
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    return super.close();
  }
}
