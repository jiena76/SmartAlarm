import 'dart:math';

class HomeLocation {
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? label;

  HomeLocation({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 40.0,
    this.label,
  });

  bool isOutside(double lat, double lng) {
    final distance = _calculateDistance(lat, lng);
    return distance > radiusMeters;
  }

  double _calculateDistance(double lat, double lng) {
    const double earthRadius = 6371000;
    final dLat = _toRadians(lat - latitude);
    final dLng = _toRadians(lng - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'label': label,
      };

  factory HomeLocation.fromJson(Map<String, dynamic> json) => HomeLocation(
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 40.0,
        label: json['label'] as String?,
      );
}
