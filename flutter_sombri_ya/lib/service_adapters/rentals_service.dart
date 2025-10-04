import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rental_model.dart';

class RentalsService {
  final String _baseUrl = 'https://sombri-ya-back-4def07fa1804.herokuapp.com';

  Future<List<Rental>> getOngoingRentals(String userId) async {
    final uri = Uri.parse(
      '$_baseUrl/rentals',
    ).replace(queryParameters: {'user_id': userId, 'status': 'ongoing'});

    try {
      print('[RentalsService] Requesting ongoing rentals from: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(
          '[RentalsService] Success: ${data.length} ongoing rentals received.',
        );
        return data.map((json) => Rental.fromJson(json)).toList();
      } else {
        print('[RentalsService] Error: Failed to load rentals.');
        print('[RentalsService] Status Code: ${response.statusCode}');
        print('[RentalsService] Response Body: ${response.body}');
        throw Exception('Failed to load ongoing rentals from API');
      }
    } catch (e) {
      print(
        '[RentalsService] Network Error: Could not connect to rentals service.',
      );
      print('[RentalsService] Exception details: $e');
      throw Exception('Failed to connect to the server');
    }
  }
}
