import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/station_model.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final String? error;
  final String? locationError;

  // Map
  final LatLng? userPosition;
  final LatLng? cameraTarget;
  final double cameraZoom;
  final MapType mapType;
  final Set<Marker> markers;

  // Stations
  final List<Station> nearbyStations;
  final String? selectedStationId;

  const HomeState({
    this.isLoading = true,
    this.error,
    this.locationError,
    this.userPosition,
    this.cameraTarget,
    this.cameraZoom = 16.0,
    this.mapType = MapType.normal,
    this.markers = const {},
    this.nearbyStations = const [],
    this.selectedStationId,
  });

  HomeState copyWith({
    bool? isLoading,
    String? error,
    String? locationError,
    LatLng? userPosition,
    LatLng? cameraTarget,
    double? cameraZoom,
    MapType? mapType,
    Set<Marker>? markers,
    List<Station>? nearbyStations,
    String? selectedStationId,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      locationError: locationError,
      userPosition: userPosition ?? this.userPosition,
      cameraTarget: cameraTarget ?? this.cameraTarget,
      cameraZoom: cameraZoom ?? this.cameraZoom,
      mapType: mapType ?? this.mapType,
      markers: markers ?? this.markers,
      nearbyStations: nearbyStations ?? this.nearbyStations,
      selectedStationId: selectedStationId ?? this.selectedStationId,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    locationError,
    userPosition,
    cameraTarget,
    cameraZoom,
    mapType,
    markers,
    nearbyStations,
    selectedStationId,
  ];
}
