import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';
import 'weather_service.dart';
import 'nearest_station_service.dart';
import 'notification_service.dart';
import '../data/repositories/station_repository.dart';
import '../data/models/station_model.dart';
import '../config/openweather_config.dart';

const _taskName = 'rain_alert_periodic';         
const _testTaskName = 'rain_alert_test_loop';     

class RainAlertScheduler {
  static Future<void> registerPeriodic() async {
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'rain_alert_task_id',            
      _taskName,                       
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.linear,
    );
  }

  static Future<void> registerTestEveryFiveMinutes() async {
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: true);
    await Workmanager().registerOneOffTask(
      'rain_alert_test_loop',         
      _testTaskName,                   
      initialDelay: const Duration(minutes: 5),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
    );
  }

  static Future<void> cancelAll() => Workmanager().cancelAll();
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final bool isPeriodic = task == _taskName;
    final bool isTestLoop = task == _testTaskName;

    print('[WM] running tak="$task" test=$isTestLoop periodic=$isPeriodic');

    if (!isPeriodic && !isTestLoop) return Future.value(true);

    try {
      final weather = WeatherService(apiKey: OpenWeatherConfig.apiKey);
      final nearest = NearestStationService(StationRepository());

      final pos = await LocationService.getPosition();
      if (pos == null) return Future.value(true);

      final willRain = await weather.willRainNextHour(pos.latitude, pos.longitude);
      if (!willRain) return Future.value(true);

      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt('last_rain_alert_epoch') ?? 0;
      final now  = DateTime.now().millisecondsSinceEpoch;
      if (now - last < 90 * 60 * 1000) return Future.value(true);

      final Station? station = await nearest.nearest(pos.latitude, pos.longitude);
      if (station == null) return Future.value(true);

      await NotificationService.showRainAlert(
        title: 'Lloverá pronto',
        body: 'La estación más cercana es ${station.placeName}. ¡Renta un paraguas!',
        payload: station.id, 
      );

      await prefs.setInt('last_rain_alert_epoch', now);
    } catch (_) {
    }

    if (isTestLoop) {
      await Workmanager().registerOneOffTask(
        'rain_alert_test_loop',        
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
