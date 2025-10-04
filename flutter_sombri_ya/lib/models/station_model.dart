class Station {
  final String id;
  final String placeName;
  final String description;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final int availableUmbrellas;
  final int totalUmbrellas;

  Station({
    required this.id,
    required this.placeName,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.availableUmbrellas,
    required this.totalUmbrellas,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      placeName: json['placeName'],
      description: json['description'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: json['distanceMeters'],
      availableUmbrellas: json['availableUmbrellas'],
      totalUmbrellas: json['totalUmbrellas'],
    );
  }
}
