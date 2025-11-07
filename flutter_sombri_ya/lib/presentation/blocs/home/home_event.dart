import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/connectivity/connectivity_service.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class InitializeHome extends HomeEvent {
  final BitmapDescriptor? stationIcon;
  const InitializeHome({this.stationIcon});
  @override
  List<Object?> get props => [stationIcon];
}

class AppResumed extends HomeEvent {
  const AppResumed();
}

class RefreshHome extends HomeEvent {
  final BitmapDescriptor? stationIcon;
  const RefreshHome({this.stationIcon});
  @override
  List<Object?> get props => [stationIcon];
}

class RecenterMap extends HomeEvent {
  const RecenterMap();
}

class ToggleMapType extends HomeEvent {
  const ToggleMapType();
}

class UpdateConnectivity extends HomeEvent {
  final ConnectivityStatus status;
  const UpdateConnectivity(this.status);
  @override
  List<Object?> get props => [status];
}
