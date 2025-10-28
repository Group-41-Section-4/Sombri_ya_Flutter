// lib/widgets/weather_icon.dart
import 'package:flutter/material.dart';
import '../data/models/weather_models.dart';

IconData _iconFor(WeatherCondition c, bool isNight) {
  switch (c) {
    case WeatherCondition.thunderstorm: return Icons.bolt;
    case WeatherCondition.drizzle:      return Icons.grain;
    case WeatherCondition.rain:         return Icons.umbrella;
    case WeatherCondition.snow:         return Icons.ac_unit;
    case WeatherCondition.fog:          return Icons.blur_on;
    case WeatherCondition.clear:
      return isNight ? Icons.nightlight_round : Icons.wb_sunny;
    case WeatherCondition.clouds:       return Icons.cloud;
    case WeatherCondition.unknown:      return Icons.wb_cloudy;
  }
}

String labelFor(WeatherCondition c) {
  switch (c) {
    case WeatherCondition.thunderstorm: return 'Tormenta';
    case WeatherCondition.drizzle:      return 'Llovizna';
    case WeatherCondition.rain:         return 'Lluvia';
    case WeatherCondition.snow:         return 'Nieve';
    case WeatherCondition.fog:          return 'Niebla';
    case WeatherCondition.clear:        return 'Despejado';
    case WeatherCondition.clouds:       return 'Nublado';
    case WeatherCondition.unknown:      return 'Clima';
  }
}

class WeatherIcon extends StatelessWidget {
  final WeatherCondition condition;
  final bool isNight;
  final double size;

  const WeatherIcon({
    super.key,
    required this.condition,
    required this.isNight,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Icon(
      _iconFor(condition, isNight),
      color: scheme.onPrimary,
      size: size,
    );
  }
}

class WeatherBadge extends StatelessWidget {
  final WeatherCondition condition;
  final bool isNight;
  final bool compact;

  const WeatherBadge({
    super.key,
    required this.condition,
    required this.isNight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.primaryContainer.withOpacity(0.25);
    final textColor = scheme.onPrimary;

    return Container(
      padding: compact ? const EdgeInsets.all(6) : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onPrimary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WeatherIcon(condition: condition, isNight: isNight, size: 18),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              labelFor(condition),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
