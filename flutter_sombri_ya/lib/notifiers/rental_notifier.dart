import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service_adapters/rentals_service.dart';
import '../notifications.dart';

class RentalNotifier extends ChangeNotifier {
  final RentalsService _rentalsService = RentalsService();
  Timer? _pollingTimer;

  List<AppNotification> _rentalNotifications = [];
  List<AppNotification> get rentalNotifications => _rentalNotifications;

  void startPolling(String userId) {
    _pollingTimer?.cancel();
    checkForOngoingRentals(userId);

    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkForOngoingRentals(userId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> checkForOngoingRentals(String userId) async {
    try {
      final activeRentals = await _rentalsService.getOngoingRentals(userId);
      bool newNotificationAdded = false;
      final displayedRentalIds = _rentalNotifications.map((n) => n.id).toSet();

      for (final rental in activeRentals) {
        if (!displayedRentalIds.contains(rental.id)) {
          final now = DateTime.now();
          final formattedTime = DateFormat('hh:mm a').format(now);

          _rentalNotifications.add(
            AppNotification(
              id: rental.id,
              type: NotificationType.reminder,
              title: 'Recordatorio',
              message:
                  'Tienes una sombrilla en alquiler. ¡No olvides devolverla!',
              time: formattedTime,
            ),
          );
          newNotificationAdded = true;
        }
      }

      if (newNotificationAdded) {
        notifyListeners();
      }
    } catch (e) {
      print("Could not check for ongoing rentals: $e");
    }
  }

  void clearNotifications() {
    _rentalNotifications = [];
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
