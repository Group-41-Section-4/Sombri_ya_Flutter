import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/connectivity/connectivity_service.dart';
import 'rental_format_event.dart';
import 'rental_format_state.dart';
import '../../../data/repositories/report_repository.dart';
import '../connectivity/connectivity_cubit.dart';

class RentalFormatBloc extends Bloc<RentalFormatEvent, RentalFormatState> {
  final ReportRepository repository;
  final String rentalId;
  final ConnectivityCubit connectivityCubit;

  RentalFormatBloc({
    required this.repository,
    required this.rentalId,
    required this.connectivityCubit,
  }) : super(const RentalFormatState()) {
    on<RatingChanged>((event, emit) {
      emit(state.copyWith(rating: event.someInt, errorMessage: null));
    });

    on<DescriptionChanged>((event, emit) {
      emit(state.copyWith(description: event.description, errorMessage: null));
    });

    on<ImageChanged>((event, emit) {
      emit(state.copyWith(imageFile: event.imageFile, errorMessage: null));
    });

    on<SubmitReportPressed>(_onSubmit);
  }

  Future<void> _onSubmit(
      SubmitReportPressed event,
      Emitter<RentalFormatState> emit,
      ) async {

    if (!state.isValid || state.isSubmitting) {
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final isOnline = connectivityCubit.state == ConnectivityStatus.online;

    try {
      await repository.sendOrQueueReport(
        rentalId: rentalId,
        rating: state.someInt,
        description: state.description,
        imageFile: state.imageFile,
        isOnline: isOnline,
      );

      emit(state.copyWith(
        isSubmitting: false,
        submitSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'No se pudo guardar/enviar el reporte. Intenta de nuevo.',
      ));
    }
  }
}
