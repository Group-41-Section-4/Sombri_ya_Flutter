import 'package:equatable/equatable.dart';
import '../../../data/models/station_model.dart';

enum NfcRegisterStatus {
  idle,
  loadingStations,
  stationsLoaded,
  scanning,
  tagDetected,
  associatedKnown,
  needsAssignment,
  assigning,
  assignedOk,
  error,
}

class NfcRegisterState extends Equatable {
  final NfcRegisterStatus status;
  final String message;
  final bool isScanning;
  final List<Station> stations;
  final String? lastUid;
  final String? associatedName;

  const NfcRegisterState({
    this.status = NfcRegisterStatus.idle,
    this.message = "Presiona 'Escanear' y acerca la tarjeta NFC.",
    this.isScanning = false,
    this.stations = const [],
    this.lastUid,
    this.associatedName,
  });

  NfcRegisterState copyWith({
    NfcRegisterStatus? status,
    String? message,
    bool? isScanning,
    List<Station>? stations,
    String? lastUid,
    String? associatedName,
  }) {
    return NfcRegisterState(
      status: status ?? this.status,
      message: message ?? this.message,
      isScanning: isScanning ?? this.isScanning,
      stations: stations ?? this.stations,
      lastUid: lastUid ?? this.lastUid,
      associatedName: associatedName,
    );
  }

  @override
  List<Object?> get props =>
      [status, message, isScanning, stations, lastUid, associatedName];
}
