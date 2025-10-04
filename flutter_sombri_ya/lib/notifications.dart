import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'weather_notifier.dart'; // importamos el notifier
import 'theme.dart';

enum NotificationType { weather, subscription, reminder }

class AppNotification {
  final NotificationType type;
  final String title;
  final String message;
  final String time;

  AppNotification({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<StatefulWidget> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<AppNotification> _notifications = [];

  void _clearNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherNotifier(), // ✅ aquí creamos el notifier
      child: Consumer<WeatherNotifier>(
        builder: (context, weatherNotifier, _) {
          // 🔹 Ejecutamos la consulta de clima después de que el widget se monte
          WidgetsBinding.instance.addPostFrameCallback((_) {
            weatherNotifier.checkRainAndNotify();
          });

          final weatherNotif = weatherNotifier.latestWeatherNotification;
          if (weatherNotif != null &&
              !_notifications.contains(weatherNotif)) {
            _notifications.insert(0, weatherNotif);
          }

          return Scaffold(
            backgroundColor: const Color(0xFFFFFDFD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF90E0EF),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Notificaciones',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              centerTitle: true,
            ),
            body: Container(
              color: const Color(0xFFFFFDFD),
              child: Column(
                children: [
                  Expanded(
                    child: _notifications.isEmpty
                        ? const Center(
                            child: Text(
                              'No tienes notificaciones',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              return _NotificationCard(
                                notification: _notifications[index],
                              );
                            },
                          ),
                  ),
                  if (_notifications.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _clearNotifications,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThem.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Borrar Notificaciones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.weather:
        return Icons.wb_sunny_outlined; // ☀️ (puedes cambiar por lluvia si quieres)
      case NotificationType.subscription:
        return Icons.info_outline;
      case NotificationType.reminder:
        return Icons.alarm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: const Color(0xFFADD8E6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 8,
      shadowColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _getIconForType(notification.type),
              color: Colors.black,
              size: 30,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                ],
              ),
            ),
            Text(
              notification.time,
              style: const TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
