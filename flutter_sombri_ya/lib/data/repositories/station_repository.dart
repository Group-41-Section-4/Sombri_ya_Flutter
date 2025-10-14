import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/api_provider.dart';
import '../models/station_model.dart';

class StationRepository {
  final ApiProvider _apiProvider = ApiProvider();

  Future<List<Station>> findNearbyStations(LatLng location) async {
    final body = {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'radius_m': 5000,
    };

    final List<dynamic> data = await _apiProvider.getWithBody(
      '/stations',
      body,
    );

    return data.map((json) => Station.fromJson(json)).toList();
  }
}
