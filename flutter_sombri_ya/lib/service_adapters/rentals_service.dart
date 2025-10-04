import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rental_model.dart';

class RentalsService {
  final String _baseUrl = 'https://sombri-ya-back-4def07fa1804.herokuapp.com';

  Future<List<Rental>> getOngoingRentals(String userId) async {
    return _fetchRentals(userId, 'ongoing');
  }

  Future<List<Rental>> getCompletedRentals(String userId) async {
    return _fetchRentals(userId, 'completed');
  }

  Future<List<Rental>> _fetchRentals(String userId, String status) async {
    final uri = Uri.parse(
      '$_baseUrl/rentals',
    ).replace(queryParameters: {'user_id': userId, 'status': status});

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Rental.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load rentals from API');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }
}
