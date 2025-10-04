class Rental {
  final String id;
  final String status;
  final String authType;
  final String? userId;
  final String? umbrellaId;
  final String? startStationId;
  final String? endStationId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;

  Rental({
    required this.id,
    required this.status,
    required this.authType,
    this.userId,
    this.umbrellaId,
    this.startStationId,
    this.endStationId,
    this.startTime,
    this.endTime,
    this.durationMinutes,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    String asString(dynamic v) => v?.toString() ?? '';
    DateTime? asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return Rental(
      id: asString(json['id']),
      status: asString(json['status']),
      authType: asString(json['auth_type']),
      userId: json['user']?['id']?.toString(),
      umbrellaId: json['umbrella']?['id']?.toString(),
      startStationId: json['start_station']?['id']?.toString(),
      endStationId: json['end_station']?['id']?.toString(),
      startTime: asDate(json['start_time']),
      endTime: asDate(json['end_time']),
      durationMinutes: (json['duration_minutes'] is int)
          ? json['duration_minutes']
          : (json['duration_minutes'] is String
              ? int.tryParse(json['duration_minutes'])
              : null),
    );
  }
}
