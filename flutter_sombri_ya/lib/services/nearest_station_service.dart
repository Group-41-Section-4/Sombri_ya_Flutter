import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/models/station_model.dart';              
import '../data/repositories/station_repository.dart';   

class NearestStationService {
  final StationRepository stationRepo;
  NearestStationService(this.stationRepo);

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; 
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(lat1*math.pi/180.0) * math.cos(lat2*math.pi/180.0) *
        math.sin(dLon/2) * math.sin(dLon/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  Future<Station?> nearest(double userLat, double userLng) async {
    final stations =
        await stationRepo.findNearbyStationsCached(
          LatLng(userLat, userLng),
          radiusM: 1000000,
          ttl: const Duration(minutes: 30),
    );
    
    if (stations.isEmpty) return null;

    stations.sort((a, b) =>
      _haversine(userLat, userLng, a.latitude, a.longitude)
        .compareTo(_haversine(userLat, userLng, b.latitude, b.longitude)));

    return stations.first;
  }
}
