import 'package:equatable/equatable.dart';
import 'package:flutter_sombri_ya/data/models/rental_model.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<Rental> rentals;
  const HistoryLoaded(this.rentals);

  @override
  List<Object?> get props => [rentals];
}

class HistoryEmpty extends HistoryState {}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
