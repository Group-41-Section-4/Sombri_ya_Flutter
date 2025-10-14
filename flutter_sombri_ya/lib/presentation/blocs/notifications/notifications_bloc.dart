import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'notifications_event.dart';
import 'notifications_state.dart';
import '/../../data/repositories/rental_repository.dart';
import '/../../data/models/notification_model.dart' as model;

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final RentalRepository _rentalRepository;
  Timer? _pollingTimer;

  NotificationsBloc({RentalRepository? rentalRepository})
    : _rentalRepository = rentalRepository ?? RentalRepository(),
      super(const NotificationsState()) {
    on<StartRentalPolling>(_onStartRentalPolling);
    on<StopRentalPolling>(_onStopRentalPolling);
    on<RentalPollingTick>(_onRentalPollingTick);
    on<ClearRentalNotifications>(_onClearRentalNotifications);
    on<CheckWeather>(_onCheckWeather);
    on<ClearWeatherNotification>(_onClearWeather);
  }

  Future<void> _onStartRentalPolling(
    StartRentalPolling event,
    Emitter<NotificationsState> emit,
  ) async {
    _pollingTimer?.cancel();
    add(RentalPollingTick(event.userId));
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      add(RentalPollingTick(event.userId));
    });
    emit(state.copyWith(isPollingRentals: true, error: null));
  }

  Future<void> _onStopRentalPolling(
    StopRentalPolling event,
    Emitter<NotificationsState> emit,
  ) async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    emit(state.copyWith(isPollingRentals: false));
  }

  DateTime? _asDateTime(dynamic dt) {
    if (dt is DateTime) return dt;
    if (dt is String) return DateTime.tryParse(dt);
    return null;
  }

  Future<void> _onRentalPollingTick(
    RentalPollingTick event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final rentals = await _rentalRepository.getOngoingRentals(event.userId);
      if (rentals.isEmpty) return;

      final ongoing = rentals.first;
      final startedAt = _asDateTime(ongoing.startTime);
      final minutes = startedAt == null
          ? 0
          : DateTime.now().difference(startedAt).inMinutes.clamp(0, 9999);

      final formattedTime = DateFormat('hh:mm a').format(DateTime.now());
      final n = model.AppNotification(
        id: ongoing.id.toString(),
        type: model.NotificationType.reminder,
        title: 'Renta en curso',
        message:
            'Llevas $minutes minutos con la sombrilla. Recuerda devolverla para evitar recargos.',
        time: formattedTime,
      );

      final list = List<model.AppNotification>.from(state.rentalNotifications);
      final idx = list.indexWhere((x) => x.id == n.id);
      if (idx >= 0) {
        list[idx] = n;
      } else {
        list.insert(0, n);
      }
      emit(state.copyWith(rentalNotifications: list, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'No se pudo consultar la renta: $e'));
    }
  }

  Future<void> _onClearRentalNotifications(
    ClearRentalNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(rentalNotifications: const [], error: null));
  }

  Future<void> _onCheckWeather(
    CheckWeather event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition();
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${pos.latitude}&longitude=${pos.longitude}&hourly=precipitation_probability',
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return;

      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final hourly = map['hourly'] as Map<String, dynamic>?;
      final probs = (hourly?['precipitation_probability'] as List?)
          ?.cast<num>();
      if (probs == null || probs.isEmpty) return;

      final rainProb = probs.first.round();
      if (rainProb >= 50) {
        final formattedTime = DateFormat('hh:mm a').format(DateTime.now());
        final n = model.AppNotification(
          type: model.NotificationType.weather,
          title: 'Alerta de Lluvia',
          message:
              'Hay $rainProb% de probabilidad de lluvia en las próximas horas.',
          time: formattedTime,
        );
        emit(state.copyWith(latestWeatherNotification: n, error: null));
      }
    } catch (e) {
      emit(state.copyWith(error: 'Error clima: $e'));
    }
  }

  Future<void> _onClearWeather(
    ClearWeatherNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(latestWeatherNotification: null, error: null));
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
