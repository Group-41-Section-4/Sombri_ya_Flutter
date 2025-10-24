import 'package:bloc/bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/repositories/station_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/models/station_model.dart';
import '../../../services/nfc_service.dart';
import 'nfc_register_event.dart';
import 'nfc_register_state.dart';

class NfcRegisterBloc extends Bloc<NfcRegisterEvent, NfcRegisterState> {
  final StationRepository stationRepo;
  final TagRepository tagRepo;
  final NfcService nfc;

  NfcRegisterBloc({
    required this.stationRepo,
    required this.tagRepo,
    required this.nfc,
  }) : super(const NfcRegisterState()) {
    on<LoadStationsRequested>(_onLoadStations);
    on<RefreshStationsRequested>(_onRefreshStations);
    on<ScanRequested>(_onScan);
    on<UidReadInternal>(_onUidRead);
    on<AssignRequested>(_onAssign);
  }

  Future<void> _onLoadStations(
      LoadStationsRequested e, Emitter<NfcRegisterState> emit) async {
    emit(state.copyWith(
      status: NfcRegisterStatus.loadingStations,
      message: "Cargando lista de estaciones...",
    ));
    try {
      final stations = await stationRepo.findNearbyStations(LatLng(e.lat, e.lng));
      emit(state.copyWith(
        status: NfcRegisterStatus.stationsLoaded,
        stations: stations,
        message: "Estaciones cargadas correctamente.",
      ));
    } catch (err) {
      emit(state.copyWith(
        status: NfcRegisterStatus.error,
        message: "Error cargando estaciones: $err",
      ));
    }
  }

  Future<void> _onRefreshStations(
      RefreshStationsRequested e, Emitter<NfcRegisterState> emit) async {
    add(LoadStationsRequested(lat: 4.6030837, lng: -74.0651307));
  }

  Future<void> _onScan(ScanRequested e, Emitter<NfcRegisterState> emit) async {
    final available = await nfc.isAvailable();
    if (!available) {
      emit(state.copyWith(
        status: NfcRegisterStatus.error,
        message: "NFC no disponible en este dispositivo.",
        isScanning: false,
      ));
      return;
    }
    emit(state.copyWith(
      status: NfcRegisterStatus.scanning,
      message: "Acerca la tarjeta NFC...",
      isScanning: true,
    ));

    await nfc.startUidSession((uid) async {
      add(UidReadInternal(uid));
    });
  }

  Future<void> _onUidRead(
      UidReadInternal e, Emitter<NfcRegisterState> emit) async {
    emit(state.copyWith(
      status: NfcRegisterStatus.tagDetected,
      message: "Tag detectado: ${e.uid}",
      lastUid: e.uid,
    ));

    try {
      final info = await tagRepo.getTagStation(e.uid);
      if (info != null) {
        final placeName = (info['place_name'] ?? '').toString();
        emit(state.copyWith(
          status: NfcRegisterStatus.associatedKnown,
          associatedName: placeName,
          isScanning: false,
          message: "Este tag pertenece a la estación: $placeName",
        ));
      } else {
        emit(state.copyWith(
          status: NfcRegisterStatus.needsAssignment,
          isScanning: false,
          message: "Este tag no está asociado. Selecciona una estación.",
        ));
      }
    } catch (err) {
      emit(state.copyWith(
        status: NfcRegisterStatus.error,
        isScanning: false,
        message: "Error al consultar: $err",
      ));
    } finally {
      await nfc.stopSession();
    }
  }

  Future<void> _onAssign(
      AssignRequested e, Emitter<NfcRegisterState> emit) async {
    emit(state.copyWith(
      status: NfcRegisterStatus.assigning,
      message: "Asociando tag a la estación...",
    ));
    try {
      await tagRepo.assignTagToStation(uid: e.uid, stationId: e.stationId);
      emit(state.copyWith(
        status: NfcRegisterStatus.assignedOk,
        message: "Tag asociado correctamente a la estación seleccionada.",
      ));
    } catch (err) {
      emit(state.copyWith(
        status: NfcRegisterStatus.error,
        message: "Error al asociar: $err",
      ));
    }
  }
}
