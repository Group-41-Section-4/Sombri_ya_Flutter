import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';
import '../../presentation/blocs/notifications/notifications_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          final items = state.rentalNotifications;
          final weather = state.latestWeatherNotification;

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (weather != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_queue),
                    title: Text(weather.title),
                    subtitle: Text(weather.message),
                    trailing: Text(weather.time),
                  ),
                ),
              for (final n in items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(n.title),
                    subtitle: Text(n.message),
                    trailing: Text(n.time),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.read<NotificationsBloc>().add(const CheckWeather()),
                child: const Text('Chequear clima ahora'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.read<NotificationsBloc>().add(
                  const ClearRentalNotifications(),
                ),
                child: const Text('Limpiar notificaciones de renta'),
              ),
            ],
          );
        },
      ),
    );
  }
}
