class Rental {
  final String id;
  final DateTime startTime;
  final String status;

  Rental({required this.id, required this.startTime, required this.status});

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']),
      status: json['status'],
    );
  }
}
