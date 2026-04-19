import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSpotModel {
  final String spotId;
  final String zoneId;
  final String spotNumber;
  final SpotStatus status;
  final Coordinates coordinates;
  final DateTime lastUpdated;
  final List<String> features;
  final double? distanceFromUser;

  ParkingSpotModel({
    required this.spotId,
    required this.zoneId,
    required this.spotNumber,
    required this.status,
    required this.coordinates,
    required this.lastUpdated,
    this.features = const [],
    this.distanceFromUser,
  });

  factory ParkingSpotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSpotModel(
      spotId: json['spot_id'],
      zoneId: json['zone_id'],
      spotNumber: json['spot_number'],
      status: SpotStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      coordinates: Coordinates.fromJson(json['coordinates']),
      lastUpdated: _parseDateTime(json['last_updated'] ?? json['lastUpdated']),
      features: List<String>.from(json['features'] ?? []),
      distanceFromUser: json['distance_from_user']?.toDouble(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'spot_id': spotId,
      'zone_id': zoneId,
      'spot_number': spotNumber,
      'status': status.toString().split('.').last,
      'coordinates': coordinates.toJson(),
      'last_updated': lastUpdated.toIso8601String(),
      'features': features,
      'distance_from_user': distanceFromUser,
    };
  }
}

enum SpotStatus {
  available,
  occupied,
  reserved,
  disabled,
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
