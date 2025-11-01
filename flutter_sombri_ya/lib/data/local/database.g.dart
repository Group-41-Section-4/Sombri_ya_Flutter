// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
mixin _$HistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $RentalHistoryTable get rentalHistory => attachedDatabase.rentalHistory;
}

class $RentalHistoryTable extends RentalHistory
    with TableInfo<$RentalHistoryTable, RentalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RentalHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startStationIdMeta = const VerificationMeta(
    'startStationId',
  );
  @override
  late final GeneratedColumn<String> startStationId = GeneratedColumn<String>(
    'start_station_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endStationIdMeta = const VerificationMeta(
    'endStationId',
  );
  @override
  late final GeneratedColumn<String> endStationId = GeneratedColumn<String>(
    'end_station_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    startStationId,
    endStationId,
    status,
    startTime,
    endTime,
    durationMinutes,
    distanceKm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rental_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<RentalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('start_station_id')) {
      context.handle(
        _startStationIdMeta,
        startStationId.isAcceptableOrUnknown(
          data['start_station_id']!,
          _startStationIdMeta,
        ),
      );
    }
    if (data.containsKey('end_station_id')) {
      context.handle(
        _endStationIdMeta,
        endStationId.isAcceptableOrUnknown(
          data['end_station_id']!,
          _endStationIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RentalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      startStationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_station_id'],
      ),
      endStationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_station_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      ),
    );
  }

  @override
  $RentalHistoryTable createAlias(String alias) {
    return $RentalHistoryTable(attachedDatabase, alias);
  }
}

class RentalEntry extends DataClass implements Insertable<RentalEntry> {
  final String id;
  final String? userId;
  final String? startStationId;
  final String? endStationId;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? distanceKm;
  const RentalEntry({
    required this.id,
    this.userId,
    this.startStationId,
    this.endStationId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.distanceKm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || startStationId != null) {
      map['start_station_id'] = Variable<String>(startStationId);
    }
    if (!nullToAbsent || endStationId != null) {
      map['end_station_id'] = Variable<String>(endStationId);
    }
    map['status'] = Variable<String>(status);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || distanceKm != null) {
      map['distance_km'] = Variable<double>(distanceKm);
    }
    return map;
  }

  RentalHistoryCompanion toCompanion(bool nullToAbsent) {
    return RentalHistoryCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      startStationId: startStationId == null && nullToAbsent
          ? const Value.absent()
          : Value(startStationId),
      endStationId: endStationId == null && nullToAbsent
          ? const Value.absent()
          : Value(endStationId),
      status: Value(status),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      distanceKm: distanceKm == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceKm),
    );
  }

  factory RentalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentalEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      startStationId: serializer.fromJson<String?>(json['startStationId']),
      endStationId: serializer.fromJson<String?>(json['endStationId']),
      status: serializer.fromJson<String>(json['status']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      distanceKm: serializer.fromJson<double?>(json['distanceKm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'startStationId': serializer.toJson<String?>(startStationId),
      'endStationId': serializer.toJson<String?>(endStationId),
      'status': serializer.toJson<String>(status),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'distanceKm': serializer.toJson<double?>(distanceKm),
    };
  }

  RentalEntry copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> startStationId = const Value.absent(),
    Value<String?> endStationId = const Value.absent(),
    String? status,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    Value<double?> distanceKm = const Value.absent(),
  }) => RentalEntry(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    startStationId: startStationId.present
        ? startStationId.value
        : this.startStationId,
    endStationId: endStationId.present ? endStationId.value : this.endStationId,
    status: status ?? this.status,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    distanceKm: distanceKm.present ? distanceKm.value : this.distanceKm,
  );
  RentalEntry copyWithCompanion(RentalHistoryCompanion data) {
    return RentalEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      startStationId: data.startStationId.present
          ? data.startStationId.value
          : this.startStationId,
      endStationId: data.endStationId.present
          ? data.endStationId.value
          : this.endStationId,
      status: data.status.present ? data.status.value : this.status,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentalEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startStationId: $startStationId, ')
          ..write('endStationId: $endStationId, ')
          ..write('status: $status, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('distanceKm: $distanceKm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    startStationId,
    endStationId,
    status,
    startTime,
    endTime,
    durationMinutes,
    distanceKm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentalEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.startStationId == this.startStationId &&
          other.endStationId == this.endStationId &&
          other.status == this.status &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationMinutes == this.durationMinutes &&
          other.distanceKm == this.distanceKm);
}

class RentalHistoryCompanion extends UpdateCompanion<RentalEntry> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> startStationId;
  final Value<String?> endStationId;
  final Value<String> status;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int?> durationMinutes;
  final Value<double?> distanceKm;
  final Value<int> rowid;
  const RentalHistoryCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.startStationId = const Value.absent(),
    this.endStationId = const Value.absent(),
    this.status = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentalHistoryCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.startStationId = const Value.absent(),
    this.endStationId = const Value.absent(),
    required String status,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       startTime = Value(startTime);
  static Insertable<RentalEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? startStationId,
    Expression<String>? endStationId,
    Expression<String>? status,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationMinutes,
    Expression<double>? distanceKm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (startStationId != null) 'start_station_id': startStationId,
      if (endStationId != null) 'end_station_id': endStationId,
      if (status != null) 'status': status,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentalHistoryCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? startStationId,
    Value<String?>? endStationId,
    Value<String>? status,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<int?>? durationMinutes,
    Value<double?>? distanceKm,
    Value<int>? rowid,
  }) {
    return RentalHistoryCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startStationId: startStationId ?? this.startStationId,
      endStationId: endStationId ?? this.endStationId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (startStationId.present) {
      map['start_station_id'] = Variable<String>(startStationId.value);
    }
    if (endStationId.present) {
      map['end_station_id'] = Variable<String>(endStationId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentalHistoryCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startStationId: $startStationId, ')
          ..write('endStationId: $endStationId, ')
          ..write('status: $status, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RentalHistoryTable rentalHistory = $RentalHistoryTable(this);
  late final HistoryDao historyDao = HistoryDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [rentalHistory];
}

typedef $$RentalHistoryTableCreateCompanionBuilder =
    RentalHistoryCompanion Function({
      required String id,
      Value<String?> userId,
      Value<String?> startStationId,
      Value<String?> endStationId,
      required String status,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<int?> durationMinutes,
      Value<double?> distanceKm,
      Value<int> rowid,
    });
typedef $$RentalHistoryTableUpdateCompanionBuilder =
    RentalHistoryCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> startStationId,
      Value<String?> endStationId,
      Value<String> status,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<int?> durationMinutes,
      Value<double?> distanceKm,
      Value<int> rowid,
    });

class $$RentalHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $RentalHistoryTable> {
  $$RentalHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startStationId => $composableBuilder(
    column: $table.startStationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endStationId => $composableBuilder(
    column: $table.endStationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RentalHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $RentalHistoryTable> {
  $$RentalHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startStationId => $composableBuilder(
    column: $table.startStationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endStationId => $composableBuilder(
    column: $table.endStationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RentalHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $RentalHistoryTable> {
  $$RentalHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get startStationId => $composableBuilder(
    column: $table.startStationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endStationId => $composableBuilder(
    column: $table.endStationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );
}

class $$RentalHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RentalHistoryTable,
          RentalEntry,
          $$RentalHistoryTableFilterComposer,
          $$RentalHistoryTableOrderingComposer,
          $$RentalHistoryTableAnnotationComposer,
          $$RentalHistoryTableCreateCompanionBuilder,
          $$RentalHistoryTableUpdateCompanionBuilder,
          (
            RentalEntry,
            BaseReferences<_$AppDatabase, $RentalHistoryTable, RentalEntry>,
          ),
          RentalEntry,
          PrefetchHooks Function()
        > {
  $$RentalHistoryTableTableManager(_$AppDatabase db, $RentalHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RentalHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RentalHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RentalHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> startStationId = const Value.absent(),
                Value<String?> endStationId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<double?> distanceKm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalHistoryCompanion(
                id: id,
                userId: userId,
                startStationId: startStationId,
                endStationId: endStationId,
                status: status,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                distanceKm: distanceKm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> startStationId = const Value.absent(),
                Value<String?> endStationId = const Value.absent(),
                required String status,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<double?> distanceKm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalHistoryCompanion.insert(
                id: id,
                userId: userId,
                startStationId: startStationId,
                endStationId: endStationId,
                status: status,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                distanceKm: distanceKm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RentalHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RentalHistoryTable,
      RentalEntry,
      $$RentalHistoryTableFilterComposer,
      $$RentalHistoryTableOrderingComposer,
      $$RentalHistoryTableAnnotationComposer,
      $$RentalHistoryTableCreateCompanionBuilder,
      $$RentalHistoryTableUpdateCompanionBuilder,
      (
        RentalEntry,
        BaseReferences<_$AppDatabase, $RentalHistoryTable, RentalEntry>,
      ),
      RentalEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RentalHistoryTableTableManager get rentalHistory =>
      $$RentalHistoryTableTableManager(_db, _db.rentalHistory);
}
