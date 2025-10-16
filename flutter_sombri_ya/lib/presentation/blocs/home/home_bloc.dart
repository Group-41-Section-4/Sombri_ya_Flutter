import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'home_event.dart';
import 'home_state.dart';

import '../../../core/services/location_service.dart';
import '../../../data/models/station_model.dart';
import '../../../data/repositories/station_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final StationRepository _stationRepository;
  final LocationService _locationService;

  HomeBloc({
    StationRepository? stationRepository,
    LocationService? locationService,
  }) : _stationRepository = stationRepository ?? StationRepository(),
       _locationService = locationService ?? LocationService(),
       super(const HomeState()) {
    on<InitializeHome>(_onInitializeHome);
    on<RefreshHome>(_onInitializeHome);
    on<RecenterMap>(_onRecenter);
    on<ToggleMapType>(_onToggleMapType);
  }

  Future<void> _onInitializeHome(
    HomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, locationError: null));

    BitmapDescriptor? stationIcon;
    if (event is InitializeHome) stationIcon = event.stationIcon;
    if (event is RefreshHome) stationIcon = event.stationIcon;

    try {
      final userPosition = await _locationService.getCurrentLocation();
      emit(
        state.copyWith(userPosition: userPosition, cameraTarget: userPosition),
      );

      final stations = await _stationRepository.findNearbyStations(
        userPosition,
      );
      emit(state.copyWith(nearbyStations: stations));

      _updateMarkers(emit, userPosition, stations, stationIcon);

      emit(state.copyWith(isLoading: false));
    } on LocationServiceDisabledException {
      emit(state.copyWith(isLoading: false, locationError: 'disabled'));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Error al cargar el mapa: $e'),
      );
    }
  }

  void _updateMarkers(
    Emitter<HomeState> emit,
    LatLng userPosition,
    List<Station> stations,
    BitmapDescriptor? stationIcon,
  ) {
    final Set<Marker> markers = {};
    markers.add(
      Marker(
        markerId: const MarkerId('userLocation'),
        position: userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu Ubicación'),
      ),
    );

    for (final station in stations) {
      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: stationIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: station.placeName,
            snippet: '${station.availableUmbrellas} sombrillas disponibles',
          ),
        ),
      );
    }
    emit(state.copyWith(markers: markers));
  }

  Future<void> _onRecenter(RecenterMap e, Emitter<HomeState> emit) async {
    try {
      final me = await _locationService.getCurrentLocation();
      emit(state.copyWith(cameraTarget: me, cameraZoom: 16));
    } catch (err) {
      emit(state.copyWith(error: 'No se pudo recentrar: $err'));
    }
  }

  void _onToggleMapType(ToggleMapType e, Emitter<HomeState> emit) {
    final next = state.mapType == MapType.normal
        ? MapType.satellite
        : MapType.normal;
    emit(state.copyWith(mapType: next));
  }
}
