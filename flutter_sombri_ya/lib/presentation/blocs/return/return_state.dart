import 'package:equatable/equatable.dart';

class ReturnState extends Equatable {
  final bool loading;
  final String? activeRentalId;
  final bool ended;       
  final String? message;   
  final String? error;     
  final bool nfcBusy;
  final bool isOffline;

  const ReturnState({
    this.loading = false,
    this.activeRentalId,
    this.ended = false,
    this.message,
    this.error,
    this.nfcBusy = false,
    this.isOffline = false,
  });

  ReturnState copyWith({
    bool? loading,
    String? activeRentalId,
    bool? ended,
    String? message,
    String? error,
    bool? nfcBusy,
    bool? isOffline,
  }) {
    return ReturnState(
      loading: loading ?? this.loading,
      activeRentalId: activeRentalId ?? this.activeRentalId,
      ended: ended ?? this.ended,
      message: message,
      error: error,
      nfcBusy: nfcBusy ?? this.nfcBusy,
      isOffline: isOffline ?? this.isOffline
    );
  }



  @override
  List<Object?> get props => [loading, activeRentalId, ended, message, error, nfcBusy, isOffline,];
}
