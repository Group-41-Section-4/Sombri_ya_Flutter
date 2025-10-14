import 'package:equatable/equatable.dart';
import '/../../data/models/notification_model.dart' as model;

class NotificationsState extends Equatable {
  final List<model.AppNotification> rentalNotifications;
  final model.AppNotification? latestWeatherNotification;
  final bool isPollingRentals;
  final String? error;

  const NotificationsState({
    this.rentalNotifications = const [],
    this.latestWeatherNotification,
    this.isPollingRentals = false,
    this.error,
  });

  NotificationsState copyWith({
    List<model.AppNotification>? rentalNotifications,
    model.AppNotification? latestWeatherNotification,
    bool? isPollingRentals,
    String? error,
  }) {
    return NotificationsState(
      rentalNotifications: rentalNotifications ?? this.rentalNotifications,
      latestWeatherNotification:
          latestWeatherNotification ?? this.latestWeatherNotification,
      isPollingRentals: isPollingRentals ?? this.isPollingRentals,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    rentalNotifications,
    latestWeatherNotification,
    isPollingRentals,
    error,
  ];
}
