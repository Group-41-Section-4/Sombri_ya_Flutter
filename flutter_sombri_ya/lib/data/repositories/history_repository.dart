import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../providers/api_provider.dart';
import '../models/rental_model.dart';

class HistoryRepository {
  final ApiProvider _api = ApiProvider();

  Future<List<Rental>> getCompletedRentals(String userId) async {
    dev.log('[HistoryRepository] start user=$userId', name: 'history');

    try {
      dev.log('[HistoryRepository] try /rentals?user_id', name: 'history');
      final List<dynamic> data = await _api.getWithParams('/rentals', {
        'user_id': userId,
      });
      final all = data.map((j) => Rental.fromJson(j as Map<String, dynamic>)).toList(growable: false);
      final completed = all.where((r) => r.status.toLowerCase() == 'completed').toList(growable: false);
      dev.log('[HistoryRepository] ok /rentals?user_id -> completed=${completed.length}', name: 'history');
      return completed;
    } catch (e1, st1) {
      dev.log('[HistoryRepository] fail /rentals?user_id', name: 'history', error: e1, stackTrace: st1);
    }

    try {
      dev.log('[HistoryRepository] try /rentals (no params)', name: 'history');
      final uri = Uri.parse('${_api.baseUrl}/rentals');
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final List<dynamic> data = _api.decodeJson(resp.body);
        final all = data.map((j) => Rental.fromJson(j as Map<String, dynamic>)).toList(growable: false);
        final mine = all.where((r) => (r.userId ?? '') == userId).toList(growable: false);
        final completed = mine.where((r) => r.status.toLowerCase() == 'completed').toList(growable: false);
        dev.log('[HistoryRepository] ok /rentals -> mine=${mine.length} completed=${completed.length}', name: 'history');
        return completed;
      } else {
        dev.log('[HistoryRepository] /rentals status=${resp.statusCode} body=${resp.body}', name: 'history');
      }
    } catch (e2, st2) {
      dev.log('[HistoryRepository] fail /rentals (no params)', name: 'history', error: e2, stackTrace: st2);
    }

    dev.log('[HistoryRepository] all attempts failed -> []', name: 'history');
    return <Rental>[];
  }
}
