enum CoordinateSystem {
  wgs84,
  gcj02,
}

class LocationSelectionResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final CoordinateSystem crs;

  const LocationSelectionResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.crs = CoordinateSystem.wgs84,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'crs': crs.name.toUpperCase(),
    };
  }

  factory LocationSelectionResult.fromMap(Map<String, dynamic> map) {
    final crsRaw = (map['crs'] as String?)?.toLowerCase() ?? 'wgs84';
    final crs = CoordinateSystem.values.firstWhere(
      (e) => e.name == crsRaw,
      orElse: () => CoordinateSystem.wgs84,
    );
    return LocationSelectionResult(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 10.0,
      crs: crs,
    );
  }
}
