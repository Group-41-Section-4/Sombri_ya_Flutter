class RentalExportRow {
  final String id;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final int? durationMinutes;
  final double? distanceMeters;
  final String? startStationName;
  final String? endStationName;

  RentalExportRow({
    required this.id,
    this.startTime,
    this.endTime,
    required this.status,
    this.durationMinutes,
    this.distanceMeters,
    this.startStationName,
    this.endStationName,
  });

  factory RentalExportRow.fromJson(Map<String, dynamic> json) {
    return RentalExportRow(
      id: json['id'] as String,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      status: json['status'] as String,
      durationMinutes: json['durationMinutes'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      startStationName: json['startStationName'] as String?,
      endStationName: json['endStationName'] as String?,
    );
  }
}
