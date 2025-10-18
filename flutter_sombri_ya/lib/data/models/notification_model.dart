enum NotificationType { weather, subscription, reminder }

class AppNotification {
  final String? id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;

  const AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
  });
}
