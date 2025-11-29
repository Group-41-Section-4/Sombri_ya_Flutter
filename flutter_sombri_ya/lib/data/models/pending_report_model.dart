import 'dart:convert';

class PendingReport {
  final String rentalId;
  final int rating;
  final String? description;
  final String? imageBase64;
  final DateTime createdAt;

  PendingReport({
    required this.rentalId,
    required this.rating,
    this.description,
    this.imageBase64,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rentalId': rentalId,
      'rating': rating,
      'description': description,
      'imageBase64': imageBase64,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PendingReport.fromMap(Map<String, dynamic> map) {
    return PendingReport(
      rentalId: map['rentalId'] as String,
      rating: map['rating'] as int,
      description: map['description'] as String?,
      imageBase64: map['imageBase64'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PendingReport.fromJson(String source) =>
      PendingReport.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
