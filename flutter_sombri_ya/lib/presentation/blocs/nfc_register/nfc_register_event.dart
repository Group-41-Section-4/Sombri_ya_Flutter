import 'package:equatable/equatable.dart';

abstract class NfcRegisterEvent extends Equatable {
  const NfcRegisterEvent();

  @override
  List<Object?> get props => [];
}

class LoadStationsRequested extends NfcRegisterEvent {
  final double lat;
  final double lng;

  const LoadStationsRequested({required this.lat, required this.lng});

  @override
  List<Object?> get props => [lat, lng];
}

class ScanRequested extends NfcRegisterEvent {
  const ScanRequested();
}


class UidReadInternal extends NfcRegisterEvent {
  final String uid;

  const UidReadInternal(this.uid);

  @override
  List<Object?> get props => [uid];
}

class AssignRequested extends NfcRegisterEvent {
  final String uid;
  final String stationId;

  const AssignRequested({required this.uid, required this.stationId});

  @override
  List<Object?> get props => [uid, stationId];
}

class RefreshStationsRequested extends NfcRegisterEvent {
  const RefreshStationsRequested();
}
