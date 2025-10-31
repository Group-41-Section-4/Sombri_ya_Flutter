import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/rental_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../core/services/pedometer_service.dart';

import 'return_event.dart';
import 'return_state.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  final RentalRepository repo;
  final ProfileRepository profileRepo;
  final PedometerService _pedometer = PedometerService();

  ReturnBloc({required this.repo, required this.profileRepo})
    : super(const ReturnState()) {
    on<ReturnInit>(_onInit);
    on<ReturnWithQr>(_onQr);
    on<ReturnWithNfc>(_onNfc);
    on<ReturnClearMessage>(
      (e, emit) => emit(state.copyWith(message: null, error: null)),
    );
  }

  void _d(String m) => debugPrint('[ReturnBloc] $m');

  String? _extractStationId(String raw) {
    try {
      final m = jsonDecode(raw);
      final id = (m['station_id'] ?? m['stationId'])?.toString();
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    try {
      final uri = Uri.parse(raw);
      final id = uri.queryParameters['station_id'] ?? uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    if (raw.isNotEmpty && raw.length <= 64) return raw;
    return null;
  }

  Future<void> _onInit(ReturnInit event, Emitter<ReturnState> emit) async {
    emit(
      state.copyWith(loading: true, ended: false, message: null, error: null),
    );
    try {
      final userId = await repo.readUserId();
      if (userId == null) {
        emit(state.copyWith(loading: false, error: 'Usuario no encontrado.'));
        return;
      }
      final backId = await repo.getActiveRentalIdFromBackend(userId);
      if (backId == null) {
        await repo.clearLocalRentalId();
      } else {
        await repo.writeLocalRentalId(backId);
      }
      emit(state.copyWith(loading: false, activeRentalId: backId));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Error al verificar renta activa: $e',
        ),
      );
    }
  }

  Future<void> _endFlow({
    required Emitter<ReturnState> emit,
    required String stationEndId,
  }) async {
    final userId = await repo.readUserId();
    if (userId == null) {
      emit(state.copyWith(loading: false, error: 'Usuario no encontrado.'));
      return;
    }

    // Future Handler + async/await
    _d('POST /rentals/end userId=$userId stationEndId=$stationEndId');
    await repo.endRental(userId: userId, stationEndId: stationEndId);
    await repo.clearLocalRentalId();

    // Handler
    final double distanceKm = _pedometer.stopAndGetDistanceKm();

    // Future + Handler
    if (distanceKm > 0.01) {
      try {
        await profileRepo.addPedometerDistance(distanceKm);
      } catch (e) {
        _d('Error guardando distancia podómetro: $e');
      }
    }

    emit(
      state.copyWith(
        loading: false,
        activeRentalId: null,
        ended: true,
        message: 'Sombrilla devuelta exitosamente.',
      ),
    );
  }

  Future<void> _onQr(ReturnWithQr event, Emitter<ReturnState> emit) async {
    emit(
      state.copyWith(loading: true, ended: false, message: null, error: null),
    );
    try {
      final stationId = _extractStationId(event.rawQr);
      _d('QR -> stationId=$stationId');
      if (stationId == null) {
        emit(
          state.copyWith(
            loading: false,
            error: 'QR inválido (sin station_id).',
          ),
        );
        return;
      }

      final userId = await repo.readUserId();
      if (userId == null) {
        emit(state.copyWith(loading: false, error: 'Usuario no encontrado.'));
        return;
      }

      final backId = await repo.getActiveRentalIdFromBackend(userId);
      _d('activeRentalId=$backId');
      if (backId == null) {
        await repo.clearLocalRentalId();
        emit(
          state.copyWith(
            loading: false,
            activeRentalId: null,
            ended: true,
            message: 'No tenías ninguna sombrilla activa.',
          ),
        );
        return;
      }

      await _endFlow(emit: emit, stationEndId: stationId);
    } catch (e, st) {
      _d('QR ERROR: $e\n$st');
      emit(
        state.copyWith(
          loading: false,
          error: 'Error al procesar devolución: $e',
        ),
      );
    }
  }

  Future<void> _onNfc(ReturnWithNfc event, Emitter<ReturnState> emit) async {
    emit(
      state.copyWith(
        loading: true,
        nfcBusy: true,
        ended: false,
        message: null,
        error: null,
      ),
    );

    try {
      _d('NFC uid="${event.uid}"');

      final userId = await repo.readUserId();
      if (userId == null) {
        emit(
          state.copyWith(
            loading: false,
            nfcBusy: false,
            error: 'Usuario no encontrado.',
          ),
        );
        return;
      }

      final backId = await repo.getActiveRentalIdFromBackend(userId);
      _d('activeRentalId=$backId');
      if (backId == null) {
        await repo.clearLocalRentalId();
        emit(
          state.copyWith(
            loading: false,
            nfcBusy: false,
            activeRentalId: null,
            ended: true,
            message: 'No tenías ninguna sombrilla activa.',
          ),
        );
        return;
      }

      final sid = await repo.stationIdByTagUid(event.uid);
      if (sid == null || sid.isEmpty) {
        emit(
          state.copyWith(
            loading: false,
            nfcBusy: false,
            error: 'No se encontró estación para el tag NFC (${event.uid}).',
          ),
        );
        return;
      }
      final String stationId = sid;
      _d('stationId(from UID)=$stationId');

      await _endFlow(emit: emit, stationEndId: stationId);
      emit(state.copyWith(nfcBusy: false));
    } catch (e, st) {
      _d('NFC ERROR: $e\n$st');
      emit(
        state.copyWith(
          loading: false,
          nfcBusy: false,
          error: 'Error en devolución NFC: $e',
        ),
      );
    }
  }
}
