class GpsCoord {
  final double latitude;
  final double longitude;

  GpsCoord({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lon': longitude,
    };
  }
}
