import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'weather_rain_channel',
    'Lluvia y Estaciones',
    description: 'Avisos de lluvia y estaciones cercanas',
    importance: Importance.high,
  );

  static Future<void> init({
    Function(String? payload)? onTap,
  }) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) => onTap?.call(resp.payload),
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_androidChannel);

    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> showRainAlert({
    required String title,
    required String body,
    String? payload, 
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(1001, title, body, details, payload: payload);
  }
}
