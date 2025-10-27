import 'package:equatable/equatable.dart';

class RentState extends Equatable {
  final bool loading;
  final bool hasActiveRental;
  final String? rentalId;
  final String? message;      
  final String? error;       
  final bool nfcBusy;

  const RentState({
    this.loading = false,
    this.hasActiveRental = false,
    this.rentalId,
    this.message,
    this.error,
    this.nfcBusy = false,
  });

  RentState copyWith({
    bool? loading,
    bool? hasActiveRental,
    String? rentalId,
    String? message,
    String? error,
    bool? nfcBusy,
  }) {
    return RentState(
      loading: loading ?? this.loading,
      hasActiveRental: hasActiveRental ?? this.hasActiveRental,
      rentalId: rentalId,
      message: message,
      error: error,
      nfcBusy: nfcBusy ?? this.nfcBusy,
    );
  }

  @override
  List<Object?> get props => [loading, hasActiveRental, rentalId, message, error, nfcBusy];
}
