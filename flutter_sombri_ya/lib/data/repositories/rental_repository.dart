import '../providers/api_provider.dart';
import '../models/rental_model.dart';

class RentalRepository {
  final ApiProvider _apiProvider = ApiProvider();

  Future<List<Rental>> getOngoingRentals(String userId) async {
    return _fetchRentals(userId, 'ongoing');
  }

  Future<List<Rental>> getCompletedRentals(String userId) async {
    return _fetchRentals(userId, 'completed');
  }

  Future<List<Rental>> _fetchRentals(String userId, String status) async {
    final List<dynamic> data = await _apiProvider.getWithParams('/rentals', {
      'user_id': userId,
      'status': status,
    });

    return data.map((json) => Rental.fromJson(json)).toList();
  }
}
