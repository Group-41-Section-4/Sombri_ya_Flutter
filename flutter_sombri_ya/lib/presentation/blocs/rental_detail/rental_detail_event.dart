import 'package:equatable/equatable.dart';

abstract class RentalDetailEvent extends Equatable {
  const RentalDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadRentalDetail extends RentalDetailEvent {
  final String rentalId;

  const LoadRentalDetail(this.rentalId);

  @override
  List<Object?> get props => [rentalId];
}

class RefreshRentalDetail extends RentalDetailEvent {
  final String rentalId;

  const RefreshRentalDetail(this.rentalId);

  @override
  List<Object?> get props => [rentalId];
}
