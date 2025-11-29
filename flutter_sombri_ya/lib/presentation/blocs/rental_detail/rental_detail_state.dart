import 'package:equatable/equatable.dart';
import '../../../data/models/rental_export_row.dart';
import '../../../data/models/rental_format_model.dart';

abstract class RentalDetailState extends Equatable {
  const RentalDetailState();

  @override
  List<Object?> get props => [];
}

class RentalDetailInitial extends RentalDetailState {}

class RentalDetailLoading extends RentalDetailState {}

class RentalDetailLoaded extends RentalDetailState {
  final RentalExportRow rental;
  final List<RentalFormat> formats;

  const RentalDetailLoaded({
    required this.rental,
    required this.formats,
  });

  @override
  List<Object?> get props => [rental, formats];
}

class RentalDetailError extends RentalDetailState {
  final String message;

  const RentalDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
