import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sombri_ya/data/repositories/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository repository;

  HistoryBloc({required this.repository}) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoad);
    on<RefreshHistory>(_onRefresh);
  }

  Future<void> _onLoad(LoadHistory event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final rentals = await repository.getCompletedRentals(event.userId);
      if (rentals.isEmpty) {
        emit(HistoryEmpty());
      } else {
        emit(HistoryLoaded(rentals));
      }
    } catch (_) {
      emit(const HistoryError('Error al cargar el historial. Inténtalo más tarde.'));
    }
  }

  Future<void> _onRefresh(RefreshHistory event, Emitter<HistoryState> emit) async {
    try {
      final rentals = await repository.getCompletedRentals(event.userId);
      if (rentals.isEmpty) {
        emit(HistoryEmpty());
      } else {
        emit(HistoryLoaded(rentals));
      }
    } catch (_) {
      emit(const HistoryError('No se pudo actualizar el historial.'));
    }
  }
}
