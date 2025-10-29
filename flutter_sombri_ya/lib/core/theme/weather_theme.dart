import 'package:flutter/material.dart';
import '../../data/models/weather_models.dart';

ThemeData themeFor(WeatherCondition c, bool isNight) {
  final seed = switch (c) {
    WeatherCondition.thunderstorm => const Color(0xFF6B5B95),
    WeatherCondition.drizzle     => const Color(0xFF467397),
    WeatherCondition.rain        => const Color(0xFF92BAD2),
    WeatherCondition.snow        => const Color(0xFFE0F7FA),
    WeatherCondition.fog         => const Color(0xFF9E9E9E),
    WeatherCondition.clear       => const Color(0xFF90E0EF),
    WeatherCondition.clouds      => const Color(0xFF90A4AE),
    WeatherCondition.unknown     => const Color(0xFF90E0EF),
  };

  final brightness = isNight ? Brightness.dark : Brightness.light;

  final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final scheme = base.copyWith(primary: seed);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      centerTitle: true,
      elevation: 0,
      iconTheme: IconThemeData(color: scheme.onPrimary),
      titleTextStyle: TextStyle(
        color: scheme.onPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
