import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class StartRentalPolling extends NotificationsEvent {
  final String userId;
  const StartRentalPolling(this.userId);
  @override
  List<Object?> get props => [userId];
}

class StopRentalPolling extends NotificationsEvent {
  const StopRentalPolling();
}

class ClearRentalNotifications extends NotificationsEvent {
  const ClearRentalNotifications();
}

class CheckWeather extends NotificationsEvent {
  const CheckWeather();
}

class ClearWeatherNotification extends NotificationsEvent {
  const ClearWeatherNotification();
}

class RentalPollingTick extends NotificationsEvent {
  final String userId;
  const RentalPollingTick(this.userId);
  @override
  List<Object?> get props => [userId];
}
