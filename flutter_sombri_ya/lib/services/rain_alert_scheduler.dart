import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';
import 'weather_service.dart';
import 'nearest_station_service.dart';
import 'notification_service.dart';
import '../data/repositories/station_repository.dart';
import '../data/models/station_model.dart';
import '../config/openweather_config.dart';

const _taskName = 'rain_alert_periodic';          // tarea periódica (>= 15 min)
const _testTaskName = 'rain_alert_test_loop';     // one-off que se reprograma cada 5 min

class RainAlertScheduler {
  /// Producción: corre cada ~15 minutos (mínimo permitido por Android).
  static Future<void> registerPeriodic() async {
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'rain_alert_task_id',            // uniqueName
      _taskName,                       // taskName
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.linear,
    );
  }

  /// Pruebas: corre cada ~5 minutos re-agendándose como OneOff.
  static Future<void> registerTestEveryFiveMinutes() async {
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: true);
    await Workmanager().registerOneOffTask(
      'rain_alert_test_loop',          // uniqueName fijo
      _testTaskName,                   // taskName
      initialDelay: const Duration(minutes: 2),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
    );
  }

  /// (Opcional) Cancelar todo lo registrado.
  static Future<void> cancelAll() => Workmanager().cancelAll();
}

/// Debe ser top-level y único.
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final bool isPeriodic = task == _taskName;
    final bool isTestLoop = task == _testTaskName;

    if (!isPeriodic && !isTestLoop) return Future.value(true);

    try {
      // 1) Servicios
      final weather = WeatherService(apiKey: OpenWeatherConfig.apiKey);
      final nearest = NearestStationService(StationRepository());

      // 2) Ubicación (si falla en background, considera cachear última ubicación)
      final pos = await LocationService.getPosition();
      if (pos == null) return Future.value(true);

      // 3) ¿Lloverá en la próxima hora?
      final willRain = await weather.willRainNextHour(pos.latitude, pos.longitude);
      if (!willRain) return Future.value(true);

      // 4) Anti-spam (90 min). Para pruebas, puedes comentar este bloque.
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt('last_rain_alert_epoch') ?? 0;
      final now  = DateTime.now().millisecondsSinceEpoch;
      if (now - last < 90 * 60 * 1000) return Future.value(true);

      // 5) Estación más cercana
      final Station? station = await nearest.nearest(pos.latitude, pos.longitude);
      if (station == null) return Future.value(true);

      // 6) Notificación
      await NotificationService.showRainAlert(
        title: 'Lloverá pronto',
        body: 'La estación más cercana es ${station.placeName}. ¡Renta un paraguas!',
        payload: station.id, // se usa en main.dart para abrir RentPage
      );

      // 7) Marca anti-spam
      await prefs.setInt('last_rain_alert_epoch', now);
    } catch (_) {
      // Silenciar errores en background
    }

    // 🔁 Si es el modo prueba, reprograma otro one-off dentro de 5 minutos
    if (isTestLoop) {
      await Workmanager().registerOneOffTask(
        'rain_alert_test_loop',         // mismo uniqueName para reemplazar
        _testTaskName,
        initialDelay: const Duration(minutes: 5),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
      );
    }

    return Future.value(true);
  });
}
