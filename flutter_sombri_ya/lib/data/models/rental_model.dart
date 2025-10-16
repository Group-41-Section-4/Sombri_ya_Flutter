class Rental {
  final String id;
  final String userId;
  final String stationStartId;
  final String? stationEndId;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;

  Rental({
    required this.id,
    required this.userId,
    required this.stationStartId,
    this.stationEndId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['rental_id'] ?? '').toString();

    return Rental(
      id: rawId,
      userId: (json['user_id'] ?? '').toString(),
      stationStartId: (json['station_start_id'] ?? '').toString(),
      stationEndId: json['station_end_id']?.toString(),
      status: (json['status'] ?? '').toString(),
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      durationMinutes: json['duration_minutes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'station_start_id': stationStartId,
    'station_end_id': stationEndId,
    'status': status,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'duration_minutes': durationMinutes,
  };
}
