import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
part 'database.g.dart';

@DataClassName('RentalEntry')
class RentalHistory extends Table {
  TextColumn get id => text().named('id')();
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get userId => text().named('user_id').nullable()();
  TextColumn get startStationId =>
      text().named('start_station_id').nullable()();
  TextColumn get endStationId => text().named('end_station_id').nullable()();
  TextColumn get status => text().named('status')();

  DateTimeColumn get startTime => dateTime().named('start_time')();
  DateTimeColumn get endTime => dateTime().named('end_time').nullable()();
  IntColumn get durationMinutes =>
      integer().named('duration_minutes').nullable()();
  RealColumn get distanceKm => real().named('distance_km').nullable()();
}

@DriftAccessor(tables: [RentalHistory])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(AppDatabase db) : super(db);
  Stream<List<RentalEntry>> watchAllRentals() => select(rentalHistory).watch();
  Future<List<RentalEntry>> getAllRentals() => select(rentalHistory).get();
  Future<void> syncHistory(List<Insertable<RentalEntry>> rentals) {
    return transaction(() async {
      await deleteAllRentals();
      await batch((batch) => batch.insertAll(rentalHistory, rentals));
    });
  }

  Future<void> insertRental(Insertable<RentalEntry> rental) =>
      into(rentalHistory).insert(rental);

  Future<int> deleteAllRentals() => delete(rentalHistory).go();
}

@DriftDatabase(tables: [RentalHistory], daos: [HistoryDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'sombri_ya_db.sqlite'));
    return NativeDatabase(file);
  });
}
