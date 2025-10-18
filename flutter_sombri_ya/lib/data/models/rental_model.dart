class Rental {
  final String id;
  final String? userId;           // ahora opcionales: el history no los trae
  final String? stationStartId;
  final String? stationEndId;

  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;

  // Campos opcionales que SÍ devuelve /rentals/history/:user_id
  final String? stationStartName; // station_start?.place_name mapeado por el controller a 'station_start'
  final String? stationEndName;   // station_end?.place_name mapeado a 'station_end'

  Rental({
    required this.id,
    this.userId,
    this.stationStartId,
    this.stationEndId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.stationStartName,
    this.stationEndName,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    // id puede venir como 'id' o 'rental_id'
    final String id = (json['id'] ?? json['rental_id'])?.toString()
        ?? (throw FormatException('Missing rental id'));

    // start_time requerido en ambos endpoints
    final dynamic startRaw = json['start_time'];
    final DateTime startTime = startRaw is String
        ? DateTime.parse(startRaw)
        : startRaw is DateTime
            ? startRaw
            : (throw FormatException('Invalid start_time'));

    // end_time opcional
    final dynamic endRaw = json['end_time'];
    final DateTime? endTime = endRaw == null
        ? null
        : (endRaw is String ? DateTime.parse(endRaw) : endRaw as DateTime);

    // status requerido por tu UI/BLoC
    final String status = (json['status'] ?? '').toString();

    // duration_minutes puede venir num o null
    final int? durationMinutes = json['duration_minutes'] == null
        ? null
        : (json['duration_minutes'] as num).toInt();

    // IDs (presentes en /rentals?user_id&status, ausentes en /history)
    final String? userId = json['user_id']?.toString();
    final String? stationStartId = json['station_start_id']?.toString();
    final String? stationEndId = json['station_end_id']?.toString();

    // Nombres (presentes en /rentals/history/:user_id)
    final String? stationStartName = json['station_start']?.toString();
    final String? stationEndName = json['station_end']?.toString();

    return Rental(
      id: id,
      userId: userId,
      stationStartId: stationStartId,
      stationEndId: stationEndId,
      status: status,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      stationStartName: stationStartName,
      stationEndName: stationEndName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        if (stationStartId != null) 'station_start_id': stationStartId,
        if (stationEndId != null) 'station_end_id': stationEndId,
        'status': status,
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (stationStartName != null) 'station_start': stationStartName,
        if (stationEndName != null) 'station_end': stationEndName,
      };
}
