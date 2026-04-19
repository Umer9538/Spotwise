import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get user stream (real-time updates)
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? studentId,
    String? avatarUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (studentId != null) updates['studentId'] = studentId;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Create reference to storage location
      final ref =
          _storage.ref().child('profile_pictures').child('$userId.jpg');

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      // Update user document with new avatar URL
      await updateUserProfile(userId: userId, avatarUrl: downloadUrl);

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    try {
      // Delete from storage
      final ref =
          _storage.ref().child('profile_pictures').child('$userId.jpg');
      await ref.delete();

      // Update user document
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'avatarUrl': FieldValue.delete()});
    } catch (e) {
      throw Exception('Failed to delete profile picture: $e');
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences({
    required String userId,
    required NotificationPreferences preferences,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationPreferences': preferences.toJson(),
      });
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Get total parking count
      final historySnapshot = await _firestore
          .collection('parking_history')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      int totalParkings = historySnapshot.docs.length;

      // Calculate total hours
      int totalMinutes = 0;
      Map<String, int> zoneUsage = {};

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        totalMinutes += (data['durationMinutes'] as int?) ?? 0;

        final zoneName = data['zoneName'] as String;
        zoneUsage[zoneName] = (zoneUsage[zoneName] ?? 0) + 1;
      }

      double totalHours = totalMinutes / 60;
      double averageDuration = totalParkings > 0 ? totalMinutes / totalParkings : 0;

      // Find favorite zone
      String? favoriteZone;
      if (zoneUsage.isNotEmpty) {
        favoriteZone = zoneUsage.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // Get active reservations count
      final activeReservations = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      // Get user data for member since
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final memberSince = (userData?['createdAt'] as Timestamp?)?.toDate();

      return {
        'totalParkings': totalParkings,
        'totalHours': totalHours.toStringAsFixed(1),
        'averageDuration': averageDuration.toStringAsFixed(0),
        'favoriteZone': favoriteZone ?? 'N/A',
        'activeReservations': activeReservations.docs.length,
        'memberSince': memberSince,
        'zoneUsage': zoneUsage,
      };
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // Get most used zones for statistics
  Future<List<Map<String, dynamic>>> getMostUsedZones(
      String userId, int limit) async {
    try {
      final historySnapshot = await _firestore
          .collection('parking_history')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      Map<String, int> zoneUsage = {};

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        final zoneName = data['zoneName'] as String;
        zoneUsage[zoneName] = (zoneUsage[zoneName] ?? 0) + 1;
      }

      final totalVisits = zoneUsage.values.fold(0, (sum, count) => sum + count);

      final sortedZones = zoneUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedZones.take(limit).map((entry) {
        return {
          'zoneName': entry.key,
          'visits': entry.value,
          'percentage': totalVisits > 0
              ? ((entry.value / totalVisits) * 100).toStringAsFixed(1)
              : '0.0',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get most used zones: $e');
    }
  }

  // Get parking history by period
  Future<List<Map<String, dynamic>>> getParkingHistoryByPeriod({
    required String userId,
    required String period, // 'week', 'month', 'year'
  }) async {
    try {
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(2020); // All time
      }

      final historySnapshot = await _firestore
          .collection('parking_history')
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('startTime', descending: true)
          .get();

      // Group by date for chart data
      Map<String, int> dailyUsage = {};

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        final startTime = (data['startTime'] as Timestamp).toDate();
        final dateKey =
            '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';

        dailyUsage[dateKey] = (dailyUsage[dateKey] ?? 0) + 1;
      }

      return dailyUsage.entries.map((entry) {
        return {
          'date': entry.key,
          'count': entry.value,
        };
      }).toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    } catch (e) {
      throw Exception('Failed to get parking history by period: $e');
    }
  }

  // Search users (admin only)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Update user role (admin only)
  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }
}
