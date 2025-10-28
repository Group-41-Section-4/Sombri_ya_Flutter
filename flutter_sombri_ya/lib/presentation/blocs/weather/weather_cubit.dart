// lib/presentation/blocs/weather/weather_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/weather_models.dart';

import '../../../services/weather_service.dart';

import '../../../services/location_service.dart' as myloc;

class WeatherCubit extends Cubit<SimpleWeather?> {
  final WeatherService weather;
  Timer? _timer;

  static const _kCode = 'weather_code';
  static const _kNight = 'weather_is_night';

  WeatherCubit({required this.weather}) : super(null) {
    _restoreFromCache();
  }

  Future<void> start({Duration every = const Duration(minutes: 15)}) async {
    await _tick();
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => _tick());
  }

  Future<void> _tick() async {
    try {
      final pos = await myloc.LocationService.getPosition();
      if (pos == null) return;


      final snap = await weather.snapshot(pos.latitude, pos.longitude);
      if (snap == null) return;

      final willRain = await weather.willRainNextHour(pos.latitude, pos.longitude);
      final effective = willRain
          ? SimpleWeather(
        condition: WeatherCondition.rain,
        isNight: snap.isNight,
        code: 500,
      )
          : snap;

      await _saveToCache(effective);
      emit(effective);
    } catch (_) {

    }
  }

  Future<void> _saveToCache(SimpleWeather w) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kCode, w.code);
    await sp.setBool(_kNight, w.isNight);
  }

  Future<void> _restoreFromCache() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getInt(_kCode);
    final isNight = sp.getBool(_kNight);
    if (code != null && isNight != null) {
      emit(SimpleWeather(
        condition: conditionFromOpenWeather(code),
        isNight: isNight,
        code: code,
      ));
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    return super.close();
  }
}
