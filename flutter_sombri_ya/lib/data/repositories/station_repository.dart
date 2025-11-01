import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/api_provider.dart';
import '../models/station_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StationRepository {
  final ApiProvider _apiProvider = ApiProvider();

  Future<List<Station>> findNearbyStations(LatLng location) async {
    final body = {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'radius_m': 1000000,
    };

    final List<dynamic> data = await _apiProvider.getWithBody(
      '/stations',
      body,
    );

    return data.map((json) => Station.fromJson(json)).toList();
  }

  final Duration _defaultTtl = const Duration(minutes: 30);

  String _cacheKeyFor(LatLng location, int radiusM) {
    double cell(double v) => (v / 0.003).roundToDouble() * 0.003;
    final latC = cell(location.latitude).toStringAsFixed(3);
    final lngC = cell(location.longitude).toStringAsFixed(3);
    return 'stations_cache_${latC}_${lngC}_r$radiusM';
  }

  bool _isFreshTs(int ts, Duration ttl) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - ts) < ttl.inMilliseconds;
  }

  Map<String, dynamic> _stationToMap(Station s) => {
    'id': s.id,
    'placeName': s.placeName,
    'description': s.description,
    'latitude': s.latitude,
    'longitude': s.longitude,
    'distanceMeters': s.distanceMeters,
    'availableUmbrellas': s.availableUmbrellas,
    'totalUmbrellas': s.totalUmbrellas,
  };

  List<Station> _fromItems(dynamic items) {
    if (items is! List) return const [];
    return items
        .map((e) => Station.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> _saveCache(String key, List<Station> list) async {
    final p = await SharedPreferences.getInstance();
    final payload = {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'items': list.map(_stationToMap).toList(),
    };
    await p.setString(key, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> _loadCacheRaw(String key) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(key);
    return (s == null) ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  Future<List<Station>> findNearbyStationsCached(
    LatLng location, {
    int radiusM = 1000000,
    Duration? ttl,
  }) async {
    final ttl0 = ttl ?? _defaultTtl;
    final key = _cacheKeyFor(location, radiusM);

    final cached = await _loadCacheRaw(key);
    if (cached != null) {
      final ts = (cached['ts'] ?? 0) as int;
      final cachedList = _fromItems(cached['items']);

      if (_isFreshTs(ts, ttl0)) {
        print('[STATIONS] CACHE_HIT key=$key ttl=${ttl0.inSeconds}s');
        return cachedList;
      } else {
        try {
          final fresh = await findNearbyStations(location);
          await _saveCache(key, fresh);
          print('[STATIONS] CACHE_REFRESH key=$key (cache stale)');
          return fresh;
        } catch (_) {
          print('[STATIONS] CACHE_STALE_FALLBACK key=$key');
          return cachedList;
        }
      }
    }

    final fromNet = await findNearbyStations(location);
    await _saveCache(key, fromNet);
    print('[STATIONS] NET_FIRTST_SAVE key=$key');
    return fromNet;
  }

  Future<List<Station>> refresh(
    LatLng location, {
    int radiusM = 1000000,
  }) async {
    final key = _cacheKeyFor(location, radiusM);
    final p = await SharedPreferences.getInstance();
    await p.remove(key);

    final fresh = await findNearbyStations(location);
    await _saveCache(key, fresh);
    return fresh;
  }

  Future<void> invalidate(LatLng location, {int radiusM = 1000000}) async {
    final key = _cacheKeyFor(location, radiusM);
    final p = await SharedPreferences.getInstance();
    await p.remove(key);
  }
}
