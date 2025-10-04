import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/station_model.dart';

class StationsService {
  final String _baseUrl = 'https://sombri-ya-back-4def07fa1804.herokuapp.com';

  Future<List<Station>> findNearbyStations(LatLng location) async {
    final uri = Uri.parse('$_baseUrl/stations');

    try {
      final body = json.encode({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'radius_m': 1000000000,
      });

      final request = http.Request('GET', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Station.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stations from API');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to connect to the server');
    }
  }
}
