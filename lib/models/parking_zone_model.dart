import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingZoneModel {
  final String zoneId;
  final String zoneName;
  final String cameraId;
  final int totalSpots;
  final int availableSpots;
  final int occupiedSpots;
  final int reservedSpots;
  final CampusType campus;
  final String building;
  final Coordinates coordinates;
  final List<String> features;
  final DateTime lastUpdated;

  ParkingZoneModel({
    required this.zoneId,
    required this.zoneName,
    required this.cameraId,
    required this.totalSpots,
    required this.availableSpots,
    required this.occupiedSpots,
    required this.reservedSpots,
    required this.campus,
    required this.building,
    required this.coordinates,
    required this.features,
    required this.lastUpdated,
  });

  factory ParkingZoneModel.fromJson(Map<String, dynamic> json) {
    return ParkingZoneModel(
      zoneId: json['zone_id'] as String? ?? '',
      zoneName: (json['zone_name'] as String?) ?? (json['name'] as String?) ?? 'Unknown Zone',
      cameraId: json['camera_id'] as String? ?? '',
      totalSpots: json['total_spots'] as int? ?? 0,
      availableSpots: json['available_spots'] as int? ?? 0,
      occupiedSpots: json['occupied_spots'] as int? ?? 0,
      reservedSpots: json['reserved_spots'] as int? ?? 0,
      campus: json['campus'] != null
          ? CampusType.values.firstWhere(
              (e) => e.toString().split('.').last == json['campus'],
              orElse: () => CampusType.visitor,
            )
          : CampusType.visitor,
      building: json['building'] as String? ?? '',
      coordinates: json['coordinates'] != null
          ? Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>)
          : Coordinates(
              latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
            ),
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      lastUpdated: _parseDateTime(json['last_updated'] ?? json['lastUpdated']),
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
      'zone_id': zoneId,
      'zone_name': zoneName,
      'camera_id': cameraId,
      'total_spots': totalSpots,
      'available_spots': availableSpots,
      'occupied_spots': occupiedSpots,
      'reserved_spots': reservedSpots,
      'campus': campus.toString().split('.').last,
      'building': building,
      'coordinates': coordinates.toJson(),
      'features': features,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

enum CampusType {
  female,
  male,
  visitor,
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
