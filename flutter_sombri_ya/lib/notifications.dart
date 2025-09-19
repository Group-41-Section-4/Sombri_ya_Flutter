import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final List<AppNotification> _notifications = [
    AppNotification(
      type: NotificationType.weather,
      title: 'Clima',
      message: 'El reporte del clima de hoy es soleado con 25°C.',
      time: '9:41 AM',
    ),

    AppNotification(
      type: NotificationType.subscription,
      title: 'Subscripción',
      message: 'Tu subscripción se renueva en 5 días.',
      time: '9:41 AM',
    ),

    AppNotification(
      type: NotificationType.reminder,
      title: 'Recordatorio',
      message: 'Recordatorio de regreso de sombrilla.',
      time: '9:41 AM',
    ),
  ];

  void _clearNotifications() {
    // setState(() {
    //   _notifications.clear();
    // });
    //print("Borrando notificaciones...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF90E0EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
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
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _NotificationCard(notification: _notifications[index]);
                },
              ),
            ),

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
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});
  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.weather:
        return Icons.wb_sunny_outlined;
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
      color: const Color.fromARGB(255, 220, 240, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 8,
      shadowColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 15,
          top: 15,
          left: 15,
          right: 15,
        ),
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
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
