enum WeatherCondition {
  thunderstorm,
  drizzle,
  rain,
  snow,
  fog,
  clear,
  clouds,
  unknown,
}

class SimpleWeather {
  final WeatherCondition condition;
  final bool isNight;
  final int code;

  const SimpleWeather({
    required this.condition,
    required this.isNight,
    required this.code,
  });
}

WeatherCondition conditionFromOpenWeather(int code) {
  if (code >= 200 && code <= 232) return WeatherCondition.thunderstorm;
  if (code >= 300 && code <= 321) return WeatherCondition.drizzle;
  if (code >= 500 && code <= 531) return WeatherCondition.rain;
  if (code >= 600 && code <= 622) return WeatherCondition.snow;
  if (code >= 701 && code <= 781) return WeatherCondition.fog;
  if (code == 800) return WeatherCondition.clear;
  if (code >= 801 && code <= 804) return WeatherCondition.clouds;
  return WeatherCondition.unknown;
}
