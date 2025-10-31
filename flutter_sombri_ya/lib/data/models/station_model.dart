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
    num parseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return Station(
      id: json['id'] ?? '',
      placeName: json['placeName'] ?? 'Nombre no disponible',
      description: json['description'] ?? '',
      latitude: parseNum(json['latitude']).toDouble(),
      longitude: parseNum(json['longitude']).toDouble(),
      distanceMeters: parseNum(json['distanceMeters']).toInt(),
      availableUmbrellas: parseNum(json['availableUmbrellas']).toInt(),
      totalUmbrellas: parseNum(json['totalUmbrellas']).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'placeName': placeName,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'distanceMeters': distanceMeters,
    'availableUmbrellas': availableUmbrellas,
    'totalUmbrellas': totalUmbrellas,
  };
}
