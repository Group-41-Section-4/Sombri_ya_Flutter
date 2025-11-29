import 'dart:developer' as dev;

import '../providers/api_provider.dart';
import '../models/rental_model.dart';
import 'package:flutter_sombri_ya/data/local/database.dart';
import 'package:drift/drift.dart' show Value;

class HistoryRepository {
  final ApiProvider _api = ApiProvider();
  final AppDatabase _db = AppDatabase();

  Future<List<Rental>> getLocalHistory() async {
    final localEntries = await _db.historyDao.getAllRentals();
    return localEntries.map((entry) => _mapEntryToRental(entry)).toList();
  }

  Future<List<Rental>> syncHistoryFromApi(String userId) async {
    dev.log(
      '[HistoryRepository] Sincronizando desde API... user=$userId',
      name: 'history',
    );

    final apiRentals = await _getCompletedRentalsFromApi(userId);
    final entriesToInsert = apiRentals.map((rental) {
      return RentalHistoryCompanion.insert(
        id: rental.id,
        status: rental.status,
        startTime: rental.startTime,
        userId: Value(rental.userId),
        startStationId: Value(rental.stationStartName),
        endStationId: Value(rental.stationEndName),
        endTime: Value(rental.endTime),
        durationMinutes: Value(rental.durationMinutes),
        distanceKm: const Value(null),
      );
    }).toList();

    await _db.historyDao.syncHistory(entriesToInsert);
    dev.log(
      '[HistoryRepository] Sincronización completa. ${apiRentals.length} registros guardados.',
      name: 'history',
    );

    return apiRentals;
  }

  Future<List<Rental>> _getCompletedRentalsFromApi(String userId) async {
    try {
      dev.log('[HistoryRepository] try /rentals?user_id', name: 'history');
      final List<dynamic> data = await _api.getWithParams('/rentals', {
        'user_id': userId,
      });

      final all = data
          .map((j) => Rental.fromJson(j as Map<String, dynamic>))
          .toList(growable: false);

      final completed = all
          .where((r) => r.status.toLowerCase() == 'completed')
          .toList(growable: false);

      dev.log(
        '[HistoryRepository] ok /rentals?user_id -> completed=${completed.length}',
        name: 'history',
      );
      return completed;
    } catch (e1, st1) {
      dev.log(
        '[HistoryRepository] fail /rentals?user_id',
        name: 'history',
        error: e1,
        stackTrace: st1,
      );
    }

    return <Rental>[];
  }

  Future<Rental> getRentalById(String rentalId) async {
    try {
      dev.log(
        '[HistoryRepository] GET /rentals/$rentalId',
        name: 'history',
      );

      final dynamic data =
      await _api.getWithParams('/rentals/$rentalId', {});

      if (data is Map<String, dynamic>) {
        return Rental.fromJson(data);
      } else if (data is List && data.isNotEmpty) {
        return Rental.fromJson(data.first as Map<String, dynamic>);
      } else {
        throw Exception('Respuesta inesperada al obtener rentals/$rentalId');
      }
    } catch (e, st) {
      dev.log(
        '[HistoryRepository] fail /rentals/$rentalId',
        name: 'history',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Rental _mapEntryToRental(RentalEntry entry) {
    return Rental(
      id: entry.id,
      status: entry.status,
      startTime: entry.startTime,
      userId: entry.userId,
      stationStartName: entry.startStationId,
      stationEndName: entry.endStationId,
      endTime: entry.endTime,
      durationMinutes: entry.durationMinutes,
    );
  }
}
