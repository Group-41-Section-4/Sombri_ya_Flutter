class RentalFormat {
  final String id;
  final int someInt;
  final String? description;
  final String? imageBase64;
  final String rentalId;

  const RentalFormat({
    required this.id,
    required this.someInt,
    required this.rentalId,
    this.description,
    this.imageBase64,
  });

  int get rating => someInt;

  factory RentalFormat.fromJson(Map<String, dynamic> json) {
    return RentalFormat(
      id: json['id'] as String,
      someInt: json['someInt'] as int,
      description: json['description'] as String?,
      imageBase64: json['imageBase64'] as String?,
      rentalId: json['rentalId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'someInt': someInt,
      'description': description,
      'imageBase64': imageBase64,
      'rentalId': rentalId,
    };
  }
}
