import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/rental_repository.dart';
import 'return_event.dart';
import 'return_state.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  final RentalRepository repo;
  ReturnBloc({required this.repo}) : super(const ReturnState()) {
    on<ReturnInit>(_onInit);
    on<ReturnWithQr>(_onQr);
    on<ReturnWithNfc>(_onNfc);
    on<ReturnClearMessage>((e, emit) => emit(state.copyWith(message: null, error: null)));
  }

  Future<void> _onInit(ReturnInit event, Emitter<ReturnState> emit) async {
    emit(state.copyWith(loading: true, ended: false, message: null, error: null));
    try {
      final userId = await repo.readUserId();
      if (userId == null) {
        emit(state.copyWith(loading: false, error: "Usuario no encontrado."));
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
      emit(state.copyWith(loading: false, error: "Error al verificar renta activa: $e"));
    }
  }

  Future<void> _endFlow({
    required Emitter<ReturnState> emit,
    required String stationEndId,
  }) async {
    final userId = await repo.readUserId();
    if (userId == null) {
      emit(state.copyWith(loading: false, error: "Usuario no encontrado."));
      return;
    }
    await repo.endRental(userId: userId, stationEndId: stationEndId);
    await repo.clearLocalRentalId();
    emit(state.copyWith(
      loading: false,
      activeRentalId: null,
      ended: true,
      message: "Sombrilla devuelta exitosamente.",
    ));
  }

  Future<void> _onQr(ReturnWithQr event, Emitter<ReturnState> emit) async {
    emit(state.copyWith(loading: true, ended: false, message: null, error: null));
    try {
      late final String stationId;
      try {
        final data = jsonDecode(event.rawQr);
        stationId = (data["station_id"] ?? "").toString();
      } catch (_) {
        emit(state.copyWith(loading: false, error: "QR inválido."));
        return;
      }
      if (stationId.isEmpty) {
        emit(state.copyWith(loading: false, error: "QR inválido: falta station_id."));
        return;
      }

      final userId = await repo.readUserId();
      if (userId == null) {
        emit(state.copyWith(loading: false, error: "Usuario no encontrado."));
        return;
      }
      final backId = await repo.getActiveRentalIdFromBackend(userId);
      if (backId == null) {
        await repo.clearLocalRentalId();
        emit(state.copyWith(
          loading: false,
          activeRentalId: null,
          ended: true,
          message: "No tenías ninguna sombrilla activa.",
        ));
        return;
      }

      await _endFlow(emit: emit, stationEndId: stationId);
    } catch (e) {
      emit(state.copyWith(loading: false, error: "Error al procesar devolución: $e"));
    }
  }

  Future<void> _onNfc(ReturnWithNfc event, Emitter<ReturnState> emit) async {
    emit(state.copyWith(loading: true, nfcBusy: true, ended: false, message: null, error: null));
    try {
      final userId = await repo.readUserId();
      if (userId == null) {
        emit(state.copyWith(loading: false, nfcBusy: false, error: "Usuario no encontrado."));
        return;
      }
      final backId = await repo.getActiveRentalIdFromBackend(userId);
      if (backId == null) {
        await repo.clearLocalRentalId();
        emit(state.copyWith(
          loading: false,
          nfcBusy: false,
          activeRentalId: null,
          ended: true,
          message: "No tenías ninguna sombrilla activa.",
        ));
        return;
      }

      final stationId = await repo.stationIdByTagUid(event.uid);
      await _endFlow(emit: emit, stationEndId: stationId);
      emit(state.copyWith(nfcBusy: false));
    } catch (e) {
      emit(state.copyWith(loading: false, nfcBusy: false, error: "Error en devolución NFC: $e"));
    }
  }
}
