// notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

// BloC Notifications
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';
import '../../presentation/blocs/notifications/notifications_state.dart';

import '../../data/models/notification_model.dart' as model;

// **CAMBIOS MÍNIMOS: Importaciones de conectividad**
import '../../../core/connectivity/connectivity_service.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, connectivityStatus) {
        final isOffline = connectivityStatus != ConnectivityStatus.online;

        if (isOffline) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6FBFF),
            appBar: AppBar(
              title: Text(
                'Notificaciones',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              backgroundColor: const Color(0xFF90E0EF),
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: Image.asset(
                        'assets/images/gato.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '¡Miau! Conexión perdida.',
                      style: GoogleFonts.robotoSlab(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Necesitas internet para ver y recibir notificaciones.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const _NotificationsView();
      },
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
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final allNotifications = [
          if (state.latestWeatherNotification != null)
            state.latestWeatherNotification!,
          ...state.rentalNotifications.reversed,
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF6FBFF),
          appBar: AppBar(
            title: const Text("Notificaciones"),
            backgroundColor: const Color(0xFF90E0EF),
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (allNotifications.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: _clearNotifications,
                  tooltip: 'Borrar todas',
                ),
            ],
          ),
          body: allNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Todo despejado!',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'No tienes notificaciones pendientes.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: allNotifications.length,
                  itemBuilder: (context, index) {
                    return _NotificationCard(
                      notification: allNotifications[index],
                    );
                  },
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
