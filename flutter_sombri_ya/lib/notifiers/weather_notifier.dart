import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../notifications.dart';

class WeatherNotifier extends ChangeNotifier {
  AppNotification? _latestWeatherNotification;
  AppNotification? get latestWeatherNotification => _latestWeatherNotification;

  void clearWeatherNotification() {
    if (_latestWeatherNotification != null) {
      _latestWeatherNotification = null;
      notifyListeners();
    }
  }

  Future<void> checkRainAndNotify() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      const apiKey = "64a018d01eba547f998be6d43c606c80";
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast"
        "?lat=${pos.latitude}&lon=${pos.longitude}"
        "&appid=$apiKey&lang=es&units=metric",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final firstForecast = data["list"][0];
        final rainProb = ((firstForecast["pop"] ?? 0) as num) * 100;

        if (rainProb > 30) {
          final now = DateTime.now();
          final formattedTime = DateFormat('hh:mm a').format(now);

          _latestWeatherNotification = AppNotification(
            type: NotificationType.weather,
            title: 'Alerta de Lluvia',
            message:
                'Hay $rainProb% de probabilidad de lluvia en las próximas horas.',
            time: formattedTime,
          );

          notifyListeners();
        } else {}
      } else {}
    } catch (e) {
      throw Exception('Error al obtener datos del clima: $e');
    }
  }
}
