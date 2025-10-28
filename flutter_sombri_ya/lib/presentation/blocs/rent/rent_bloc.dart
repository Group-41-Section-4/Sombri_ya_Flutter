import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sombri_ya/data/repositories/rental_repository.dart';
import 'package:flutter_sombri_ya/core/services/pedometer_service.dart';
import 'rent_event.dart';
import 'rent_state.dart';

class RentBloc extends Bloc<RentEvent, RentState> {
  final RentalRepository repo;
  final PedometerService _pedometer = PedometerService();

  RentBloc({required this.repo}) : super(const RentState()) {
    on<RentInit>(_onInit);
    on<RentRefreshActive>(_onRefresh);
    on<RentStartWithQr>(_onStartWithQr);
    on<RentStartWithNfc>(_onStartWithNfc);
    on<RentClearMessage>(
      (e, emit) => emit(state.copyWith(message: null, error: null)),
    );
  }

  bool _isAlreadyActiveError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('already has an active rental') ||
        msg.contains('"statuscode":404') ||
        msg.contains('http 404') ||
        msg.contains('not found');
  }

  Future<void> _onInit(RentInit event, Emitter<RentState> emit) async {
    emit(state.copyWith(loading: true, message: null, error: null));
    try {
      final syncedId = await repo.syncLocalWithBackend();
      if (syncedId != null) {
        _pedometer.startListening();
      }
      emit(
        state.copyWith(
          loading: false,
          hasActiveRental: syncedId != null,
          rentalId: syncedId,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _onRefresh(
    RentRefreshActive event,
    Emitter<RentState> emit,
  ) async {
    try {
      final syncedId = await repo.syncLocalWithBackend();
      emit(
        state.copyWith(hasActiveRental: syncedId != null, rentalId: syncedId),
      );
    } catch (e) {
      emit(state.copyWith(error: "No se pudo refrescar la renta: $e"));
    }
  }

  Future<void> _onStartWithQr(
    RentStartWithQr event,
    Emitter<RentState> emit,
  ) async {
    emit(state.copyWith(loading: true, message: null, error: null));
    try {
      final userId = await repo.readUserId();
      if (userId == null) {
        emit(state.copyWith(loading: false, error: "Usuario no encontrado."));
        return;
      }

      final backId = await repo.getActiveRentalIdFromBackend(userId);
      if (backId != null && backId.isNotEmpty) {
        await repo.writeLocalRentalId(backId);
        emit(
          state.copyWith(
            loading: false,
            hasActiveRental: true,
            rentalId: backId,
            message: "Ya tenías una sombrilla activa. Te llevo a devolución.",
          ),
        );
        return;
      }

      String stationId;
      try {
        final data = jsonDecode(event.rawQr);
        stationId = (data["station_id"] ?? "").toString();
      } catch (_) {
        emit(state.copyWith(loading: false, error: "QR inválido."));
        return;
      }
      if (stationId.isEmpty) {
        emit(
          state.copyWith(
            loading: false,
            error: "QR inválido: falta station_id.",
          ),
        );
        return;
      }

      final newId = await repo.startRentalWithStation(
        userId: userId,
        stationId: stationId,
        authType: "qr",
      );
      await repo.writeLocalRentalId(newId);
      _pedometer.startListening();

      emit(
        state.copyWith(
          loading: false,
          hasActiveRental: true,
          rentalId: newId,
          message: "Sombrilla rentada con éxito (QR).",
        ),
      );
    } catch (e) {
      if (_isAlreadyActiveError(e)) {
        final userId = await repo.readUserId();
        if (userId != null) {
          final existing = await repo.getActiveRentalIdFromBackend(userId);
          if (existing != null && existing.isNotEmpty) {
            await repo.writeLocalRentalId(existing);
            emit(
              state.copyWith(
                loading: false,
                hasActiveRental: true,
                rentalId: existing,
                message:
                    "Ya tenías una sombrilla activa. Te llevo a devolución.",
                error: null,
              ),
            );
            return;
          }
        }
      }
      emit(
        state.copyWith(loading: false, error: "Error al iniciar la renta: $e"),
      );
    }
  }

  Future<void> _onStartWithNfc(
    RentStartWithNfc event,
    Emitter<RentState> emit,
  ) async {
    emit(
      state.copyWith(loading: true, nfcBusy: true, message: null, error: null),
    );
    try {
      final userId = await repo.readUserId();
      if (userId == null) {
        emit(
          state.copyWith(
            loading: false,
            nfcBusy: false,
            error: "Usuario no encontrado.",
          ),
        );
        return;
      }

      final backId = await repo.getActiveRentalIdFromBackend(userId);
      if (backId != null && backId.isNotEmpty) {
        await repo.writeLocalRentalId(backId);
        emit(
          state.copyWith(
            loading: false,
            nfcBusy: false,
            hasActiveRental: true,
            rentalId: backId,
            message: "Ya tenías una sombrilla activa. Te llevo a devolución.",
          ),
        );
        return;
      }

      final stationId = await repo.stationIdByTagUid(event.uid);
      final newId = await repo.startRentalWithStation(
        userId: userId,
        stationId: stationId,
        authType: "nfc",
      );
      await repo.writeLocalRentalId(newId);
      _pedometer.startListening();
      emit(
        state.copyWith(
          loading: false,
          nfcBusy: false,
          hasActiveRental: true,
          rentalId: newId,
          message: "Sombrilla rentada en $stationId (NFC).",
        ),
      );
    } catch (e) {
      if (_isAlreadyActiveError(e)) {
        final userId = await repo.readUserId();
        if (userId != null) {
          final existing = await repo.getActiveRentalIdFromBackend(userId);
          if (existing != null && existing.isNotEmpty) {
            await repo.writeLocalRentalId(existing);
            emit(
              state.copyWith(
                loading: false,
                nfcBusy: false,
                hasActiveRental: true,
                rentalId: existing,
                message:
                    "Ya tenías una sombrilla activa. Te llevo a devolución.",
                error: null,
              ),
            );
            return;
          }
        }
      }
      emit(
        state.copyWith(
          loading: false,
          nfcBusy: false,
          error: "Error en renta NFC: $e",
        ),
      );
    }
  }
}
