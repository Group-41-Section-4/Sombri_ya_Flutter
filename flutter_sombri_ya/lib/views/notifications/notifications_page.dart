// notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

// BloC Notifications
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';
import '../../presentation/blocs/notifications/notifications_state.dart';

import '../../data/models/notification_model.dart' as model;

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NotificationsView();
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  @override
  void dispose() {
    context.read<NotificationsBloc>().add(const StopRentalPolling());
    super.dispose();
  }

  void _clearNotifications() {
    final bloc = context.read<NotificationsBloc>();
    bloc.add(const ClearWeatherNotification());
    bloc.add(const ClearRentalNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final List<model.AppNotification> allNotifications = [];
        if (state.latestWeatherNotification != null) {
          allNotifications.add(state.latestWeatherNotification!);
        }
        allNotifications.addAll(state.rentalNotifications);

        return Scaffold(
          backgroundColor: const Color(0xFFFFFDFD),
          appBar: AppBar(
            backgroundColor: const Color(0xFF90E0EF),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
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
          body: Column(
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
                        backgroundColor: const Color(0xFFFF4645),
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
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final model.AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData _getIconForType(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.weather:
        return Icons.wb_sunny_outlined;
      case model.NotificationType.subscription:
        return Icons.info_outline;
      case model.NotificationType.reminder:
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
      shadowColor: Colors.black.withOpacity(0.5),
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
