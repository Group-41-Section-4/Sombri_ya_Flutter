import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'notifications.dart';

class WeatherNotifier extends ChangeNotifier {
  AppNotification? _latestWeatherNotification;

  AppNotification? get latestWeatherNotification => _latestWeatherNotification;

  Future<void> checkRainAndNotify() async {
    try {
      print("Obteniendo ubicación del usuario...");
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Ubicación: ${pos.latitude}, ${pos.longitude}");

      const apiKey = "64a018d01eba547f998be6d43c606c80";
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast"
        "?lat=${pos.latitude}&lon=${pos.longitude}"
        "&appid=$apiKey&lang=es&units=metric",
      );

      print("Llamando a la API: $url");

      final response = await http.get(url);
      print("Código de respuesta: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Respuesta JSON recibida");

        // El pronóstico viene en la lista, cada 3 horas
        final firstForecast = data["list"][0];
        final rainProb = ((firstForecast["pop"] ?? 0) as num) * 100; // 0–100 %

        print("Probabilidad de lluvia: $rainProb%");

        if (rainProb > 70) {
          final now = DateTime.now();
          final formattedTime = DateFormat('hh:mm a').format(now);

          _latestWeatherNotification = AppNotification(
            type: NotificationType.weather,
            title: 'Alerta de Lluvia',
            message:
                'Hay $rainProb% de probabilidad de lluvia en las próximas horas.',
            time: formattedTime,
          );

          print("Notificación creada y enviada a la UI.");
          notifyListeners();
        } else {
          print("ℹNo hay suficiente probabilidad de lluvia.");
        }
      } else {
        print("Error al llamar a la API: ${response.body}");
      }
    } catch (e) {
      print("Excepción en checkRainAndNotify: $e");
    }
  }
}
