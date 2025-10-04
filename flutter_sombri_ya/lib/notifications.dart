import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'notifiers/weather_notifier.dart';
import 'notifiers/rental_notifier.dart';
import 'theme.dart';

enum NotificationType { weather, subscription, reminder }

class AppNotification {
  final String? id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;

  AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
  });
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherNotifier()),
        ChangeNotifierProvider(create: (_) => RentalNotifier()),
      ],
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherNotifier = Provider.of<WeatherNotifier>(
        context,
        listen: false,
      );
      final rentalNotifier = Provider.of<RentalNotifier>(
        context,
        listen: false,
      );

      weatherNotifier.checkRainAndNotify();
      rentalNotifier.startPolling('5e1a88f1-55c5-44d0-87bb-44919f9f4202');
    });
  }

  @override
  void dispose() {
    Provider.of<RentalNotifier>(context, listen: false).stopPolling();
    super.dispose();
  }

  void _clearNotifications() {
    Provider.of<WeatherNotifier>(
      context,
      listen: false,
    ).clearWeatherNotification();
    Provider.of<RentalNotifier>(context, listen: false).clearNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final weatherNotifier = context.watch<WeatherNotifier>();
    final rentalNotifier = context.watch<RentalNotifier>();
    final List<AppNotification> allNotifications = [];
    if (weatherNotifier.latestWeatherNotification != null) {
      allNotifications.add(weatherNotifier.latestWeatherNotification!);
    }
    allNotifications.addAll(rentalNotifier.rentalNotifications);

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
      ),
      body: Container(
        color: const Color(0xFFFFFDFD),
        child: Column(
          children: [
            Expanded(
              child: allNotifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No tienes notificaciones',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: allNotifications.length,
                      itemBuilder: (context, index) {
                        return _NotificationCard(
                          notification: allNotifications[index],
                        );
                      },
                    ),
            ),
            if (allNotifications.isNotEmpty)
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
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
