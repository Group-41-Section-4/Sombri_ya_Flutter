import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'rental_detail_event.dart';
import 'rental_detail_state.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/rental_export_row.dart';

class RentalDetailBloc extends Bloc<RentalDetailEvent, RentalDetailState> {
  final HistoryRepository historyRepository;
  final ReportRepository reportRepository;

  RentalDetailBloc({
    required this.historyRepository,
    required this.reportRepository,
  }) : super(RentalDetailInitial()) {
    on<LoadRentalDetail>(_onLoad);
    on<RefreshRentalDetail>(_onRefresh);
  }

  Future<void> _onLoad(
      LoadRentalDetail event,
      Emitter<RentalDetailState> emit,
      ) async {
    emit(RentalDetailLoading());
    await _fetchAndEmit(event.rentalId, emit, showLoading: false);
  }

  Future<void> _onRefresh(
      RefreshRentalDetail event,
      Emitter<RentalDetailState> emit,
      ) async {
    await _fetchAndEmit(event.rentalId, emit, showLoading: false);
  }

  Future<void> _fetchAndEmit(
      String rentalId,
      Emitter<RentalDetailState> emit, {
        bool showLoading = true,
      }) async {
    try {

      final RentalExportRow rental =
      await historyRepository.getRentalById(rentalId);

      debugPrint('[RentalDetailBloc] Rental cargado: '
          'id=${rental.id}, start=${rental.startTime}, '
          'startStation=${rental.startStationName}, '
          'endStation=${rental.endStationName}');

      final formats = await reportRepository.getFormatsByRentalId(rentalId);

      emit(RentalDetailLoaded(
        rental: rental,
        formats: formats,
      ));
    } catch (e) {
      emit(RentalDetailError('No se pudieron cargar los detalles: $e'));
    }
  }
}
