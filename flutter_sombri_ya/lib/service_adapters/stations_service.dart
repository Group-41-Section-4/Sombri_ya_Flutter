import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/station_model.dart'; // Importa el modelo

class StationsService {
  final String _baseUrl = 'https://sombri-ya-back-4def07fa1804.herokuapp.com/';
  Future<List<Station>> findNearbyStations(LatLng location) async {
    final uri = Uri.parse('$_baseUrl/stations').replace(
      queryParameters: {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'radius_m': '2000',
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Station.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stations from API');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }
}
