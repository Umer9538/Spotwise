import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/parking_zone_model.dart';
import '../models/parking_spot_model.dart';

class ZoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all parking zones
  Future<List<ParkingZoneModel>> getAllZones() async {
    try {
      final snapshot = await _firestore
          .collection('parking_zones')
          .get();

      return snapshot.docs
          .map((doc) => ParkingZoneModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get parking zones: $e');
    }
  }

  // Get zones stream (real-time updates)
  Stream<List<ParkingZoneModel>> getZonesStream() {
    return _firestore
        .collection('parking_zones')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingZoneModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get zone by ID
  Future<ParkingZoneModel?> getZoneById(String zoneId) async {
    try {
      final doc =
          await _firestore.collection('parking_zones').doc(zoneId).get();

      if (doc.exists) {
        return ParkingZoneModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get zone: $e');
    }
  }

  // Get zone stream by ID
  Stream<ParkingZoneModel?> getZoneStreamById(String zoneId) {
    return _firestore
        .collection('parking_zones')
        .doc(zoneId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return ParkingZoneModel.fromJson(
            snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Get zones by campus
  Future<List<ParkingZoneModel>> getZonesByCampus(CampusType campus) async {
    try {
      final snapshot = await _firestore
          .collection('parking_zones')
          .where('campus', isEqualTo: campus.toString().split('.').last)
          .get();

      return snapshot.docs
          .map((doc) => ParkingZoneModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get zones by campus: $e');
    }
  }

  // Get zones by campus stream
  Stream<List<ParkingZoneModel>> getZonesByCampusStream(CampusType campus) {
    return _firestore
        .collection('parking_zones')
        .where('campus', isEqualTo: campus.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingZoneModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get zones with available spots
  Future<List<ParkingZoneModel>> getZonesWithAvailableSpots() async {
    try {
      final snapshot = await _firestore
          .collection('parking_zones')
          .where('available_spots', isGreaterThan: 0)
          .orderBy('available_spots', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ParkingZoneModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get zones with available spots: $e');
    }
  }

  // Get zones with available spots stream
  Stream<List<ParkingZoneModel>> getZonesWithAvailableSpotsStream() {
    return _firestore
        .collection('parking_zones')
        .where('available_spots', isGreaterThan: 0)
        .orderBy('available_spots', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingZoneModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get parking spots for a zone
  Future<List<ParkingSpotModel>> getSpotsByZone(String zoneId) async {
    try {
      final snapshot = await _firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('spots')
          .orderBy('spot_number')
          .get();

      return snapshot.docs
          .map((doc) => ParkingSpotModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get parking spots: $e');
    }
  }

  // Get spots stream for a zone
  Stream<List<ParkingSpotModel>> getSpotsByZoneStream(String zoneId) {
    return _firestore
        .collection('parking_zones')
        .doc(zoneId)
        .collection('spots')
        .orderBy('spot_number')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingSpotModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get available spots for a zone
  Future<List<ParkingSpotModel>> getAvailableSpotsByZone(String zoneId) async {
    try {
      final snapshot = await _firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('spots')
          .where('status', isEqualTo: 'available')
          .orderBy('spot_number')
          .get();

      return snapshot.docs
          .map((doc) => ParkingSpotModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get available spots: $e');
    }
  }

  // Get spot by ID
  Future<ParkingSpotModel?> getSpotById(String zoneId, String spotId) async {
    try {
      final doc = await _firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('spots')
          .doc(spotId)
          .get();

      if (doc.exists) {
        return ParkingSpotModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get spot: $e');
    }
  }

  // Update spot status
  Future<void> updateSpotStatus({
    required String zoneId,
    required String spotId,
    required SpotStatus status,
  }) async {
    try {
      await _firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('spots')
          .doc(spotId)
          .update({
        'status': status.toString().split('.').last,
        'last_updated': FieldValue.serverTimestamp(),
      });

      // Update zone statistics
      await _updateZoneStatistics(zoneId);
    } catch (e) {
      throw Exception('Failed to update spot status: $e');
    }
  }

  // Update zone statistics
  Future<void> _updateZoneStatistics(String zoneId) async {
    try {
      final spotsSnapshot = await _firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('spots')
          .get();

      int availableSpots = 0;
      int occupiedSpots = 0;
      int reservedSpots = 0;

      for (var doc in spotsSnapshot.docs) {
        final spotData = doc.data();
        final status = spotData['status'] as String;

        switch (status) {
          case 'available':
            availableSpots++;
            break;
          case 'occupied':
            occupiedSpots++;
            break;
          case 'reserved':
            reservedSpots++;
            break;
        }
      }

      await _firestore.collection('parking_zones').doc(zoneId).update({
        'available_spots': availableSpots,
        'occupied_spots': occupiedSpots,
        'reserved_spots': reservedSpots,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update zone statistics: $e');
    }
  }

  // Create new zone (admin only)
  Future<void> createZone(ParkingZoneModel zone) async {
    try {
      await _firestore
          .collection('parking_zones')
          .doc(zone.zoneId)
          .set(zone.toJson());
    } catch (e) {
      throw Exception('Failed to create zone: $e');
    }
  }

  // Update zone (admin only)
  Future<void> updateZone({
    required String zoneId,
    String? zoneName,
    String? building,
    List<String>? features,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (zoneName != null) updates['zone_name'] = zoneName;
      if (building != null) updates['building'] = building;
      if (features != null) updates['features'] = features;

      if (updates.isNotEmpty) {
        await _firestore.collection('parking_zones').doc(zoneId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update zone: $e');
    }
  }

  // Create new spot (admin only)
  Future<void> createSpot({
    required String zoneId,
    required ParkingSpotModel spot,
  }) async {
    try {
      await _firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('spots')
          .doc(spot.spotId)
          .set(spot.toJson());

      // Update zone statistics
      await _updateZoneStatistics(zoneId);
    } catch (e) {
      throw Exception('Failed to create spot: $e');
    }
  }

  // Delete spot (admin only)
  Future<void> deleteSpot({
    required String zoneId,
    required String spotId,
  }) async {
    try {
      await _firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('spots')
          .doc(spotId)
          .delete();

      // Update zone statistics
      await _updateZoneStatistics(zoneId);
    } catch (e) {
      throw Exception('Failed to delete spot: $e');
    }
  }

  // Search zones by name
  Future<List<ParkingZoneModel>> searchZones(String query) async {
    try {
      // Get all zones and filter client-side due to inconsistent field names
      final allZones = await getAllZones();
      final queryLower = query.toLowerCase();

      return allZones.where((zone) =>
        zone.zoneName.toLowerCase().contains(queryLower)
      ).toList();
    } catch (e) {
      throw Exception('Failed to search zones: $e');
    }
  }

  // Get zones sorted by distance (requires user location)
  Future<List<ParkingZoneModel>> getZonesSortedByDistance({
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      final zones = await getAllZones();

      // Calculate distances and sort
      zones.sort((a, b) {
        double distanceA = _calculateDistance(
          userLatitude,
          userLongitude,
          a.coordinates.latitude,
          a.coordinates.longitude,
        );

        double distanceB = _calculateDistance(
          userLatitude,
          userLongitude,
          b.coordinates.latitude,
          b.coordinates.longitude,
        );

        return distanceA.compareTo(distanceB);
      });

      return zones;
    } catch (e) {
      throw Exception('Failed to get zones sorted by distance: $e');
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Get campus availability summary
  Future<Map<String, dynamic>> getCampusAvailabilitySummary() async {
    try {
      final zones = await getAllZones();

      Map<String, Map<String, int>> campusStats = {
        'female': {'total': 0, 'available': 0, 'zones': 0},
        'male': {'total': 0, 'available': 0, 'zones': 0},
        'visitor': {'total': 0, 'available': 0, 'zones': 0},
      };

      for (var zone in zones) {
        String campus = zone.campus.toString().split('.').last;
        campusStats[campus]!['total'] =
            campusStats[campus]!['total']! + zone.totalSpots;
        campusStats[campus]!['available'] =
            campusStats[campus]!['available']! + zone.availableSpots;
        campusStats[campus]!['zones'] = campusStats[campus]!['zones']! + 1;
      }

      return campusStats;
    } catch (e) {
      throw Exception('Failed to get campus availability summary: $e');
    }
  }

  // Batch update spots from camera detection (admin/system only)
  Future<void> batchUpdateSpotsFromDetection({
    required String zoneId,
    required List<Map<String, dynamic>> detectionData,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var detection in detectionData) {
        final spotId = detection['spotId'] as String;
        final status = detection['status'] as String;

        final spotRef = _firestore
            .collection('parking_zones')
            .doc(zoneId)
            .collection('spots')
            .doc(spotId);

        batch.update(spotRef, {
          'status': status,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Update zone statistics
      await _updateZoneStatistics(zoneId);
    } catch (e) {
      throw Exception('Failed to batch update spots: $e');
    }
  }
}
