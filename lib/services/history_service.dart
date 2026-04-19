import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_history_model.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get parking history for user
  Future<List<ParkingHistoryModel>> getUserHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('parking_history')
          .where('user_id', isEqualTo: userId)
          .orderBy('start_time', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ParkingHistoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get parking history: $e');
    }
  }

  // Get parking history stream
  Stream<List<ParkingHistoryModel>> getUserHistoryStream(String userId) {
    return _firestore
        .collection('parking_history')
        .where('user_id', isEqualTo: userId)
        .orderBy('start_time', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingHistoryModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get parking history by period
  Future<List<ParkingHistoryModel>> getHistoryByPeriod({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('parking_history')
          .where('user_id', isEqualTo: userId)
          .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));

      if (endDate != null) {
        query = query.where('start_time',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.orderBy('start_time', descending: true).get();

      return snapshot.docs
          .map((doc) => ParkingHistoryModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get history by period: $e');
    }
  }

  // Get history by status
  Future<List<ParkingHistoryModel>> getHistoryByStatus({
    required String userId,
    required HistoryStatus status,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('parking_history')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('start_time', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ParkingHistoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get history by status: $e');
    }
  }

  // Get history by zone
  Future<List<ParkingHistoryModel>> getHistoryByZone({
    required String userId,
    required String zoneId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('parking_history')
          .where('user_id', isEqualTo: userId)
          .where('zone_id', isEqualTo: zoneId)
          .orderBy('start_time', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ParkingHistoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get history by zone: $e');
    }
  }

  // Get recent history (last N entries)
  Future<List<ParkingHistoryModel>> getRecentHistory({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('parking_history')
          .where('user_id', isEqualTo: userId)
          .orderBy('start_time', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ParkingHistoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent history: $e');
    }
  }

  // Get history for this week
  Future<List<ParkingHistoryModel>> getThisWeekHistory(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return getHistoryByPeriod(userId: userId, startDate: startDate);
  }

  // Get history for this month
  Future<List<ParkingHistoryModel>> getThisMonthHistory(String userId) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);

    return getHistoryByPeriod(userId: userId, startDate: startDate);
  }

  // Delete history entry
  Future<void> deleteHistoryEntry(String historyId) async {
    try {
      await _firestore.collection('parking_history').doc(historyId).delete();
    } catch (e) {
      throw Exception('Failed to delete history entry: $e');
    }
  }

  // Clear all history for user
  Future<void> clearUserHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('parking_history')
          .where('user_id', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear user history: $e');
    }
  }

  // Get history statistics
  Future<Map<String, dynamic>> getHistoryStatistics(String userId) async {
    try {
      final history = await getUserHistory(userId);

      int completed = 0;
      int cancelled = 0;
      int expired = 0;
      int totalMinutes = 0;
      Map<String, int> zoneVisits = {};
      Map<int, int> hourlyDistribution = {}; // Hour of day distribution

      for (var entry in history) {
        // Count by status
        switch (entry.status) {
          case HistoryStatus.completed:
            completed++;
            break;
          case HistoryStatus.cancelled:
            cancelled++;
            break;
          case HistoryStatus.expired:
            expired++;
            break;
        }

        // Total duration
        totalMinutes += entry.duration.inMinutes;

        // Zone visits
        zoneVisits[entry.zoneName] = (zoneVisits[entry.zoneName] ?? 0) + 1;

        // Hourly distribution
        int hour = entry.startTime.hour;
        hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
      }

      // Find most common parking time
      int? peakHour;
      int maxVisits = 0;
      hourlyDistribution.forEach((hour, visits) {
        if (visits > maxVisits) {
          maxVisits = visits;
          peakHour = hour;
        }
      });

      String peakTimeRange = peakHour != null
          ? '${peakHour! < 10 ? '0$peakHour' : peakHour}:00 - ${(peakHour! + 1) < 10 ? '0${peakHour! + 1}' : peakHour! + 1}:00'
          : 'N/A';

      return {
        'total': history.length,
        'completed': completed,
        'cancelled': cancelled,
        'expired': expired,
        'totalHours': (totalMinutes / 60).toStringAsFixed(1),
        'averageDuration': history.isNotEmpty
            ? (totalMinutes / history.length).toStringAsFixed(0)
            : '0',
        'zoneVisits': zoneVisits,
        'peakTimeRange': peakTimeRange,
        'hourlyDistribution': hourlyDistribution,
      };
    } catch (e) {
      throw Exception('Failed to get history statistics: $e');
    }
  }

  // Get parking frequency by day of week
  Future<Map<String, int>> getParkingFrequencyByDayOfWeek(String userId) async {
    try {
      final history = await getUserHistory(userId);

      Map<String, int> dayFrequency = {
        'Monday': 0,
        'Tuesday': 0,
        'Wednesday': 0,
        'Thursday': 0,
        'Friday': 0,
        'Saturday': 0,
        'Sunday': 0,
      };

      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];

      for (var entry in history) {
        String dayName = dayNames[entry.startTime.weekday - 1];
        dayFrequency[dayName] = dayFrequency[dayName]! + 1;
      }

      return dayFrequency;
    } catch (e) {
      throw Exception('Failed to get parking frequency by day: $e');
    }
  }

  // Export history as JSON
  Future<List<Map<String, dynamic>>> exportHistory(String userId) async {
    try {
      final history = await getUserHistory(userId);
      return history.map((entry) => entry.toJson()).toList();
    } catch (e) {
      throw Exception('Failed to export history: $e');
    }
  }

  // Get all history entries (admin only)
  Future<List<ParkingHistoryModel>> getAllHistory() async {
    try {
      final snapshot = await _firestore
          .collection('parking_history')
          .orderBy('start_time', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => ParkingHistoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all history: $e');
    }
  }

  // Get system-wide statistics (admin only)
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final snapshot =
          await _firestore.collection('parking_history').get();

      int totalSessions = snapshot.docs.length;
      int completed = 0;
      int cancelled = 0;
      int expired = 0;
      int totalMinutes = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final duration = data['duration_minutes'] as int? ?? 0;

        totalMinutes += duration;

        switch (status) {
          case 'completed':
            completed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'expired':
            expired++;
            break;
        }
      }

      return {
        'totalSessions': totalSessions,
        'completed': completed,
        'cancelled': cancelled,
        'expired': expired,
        'totalHours': (totalMinutes / 60).toStringAsFixed(1),
        'averageDuration': totalSessions > 0
            ? (totalMinutes / totalSessions).toStringAsFixed(0)
            : '0',
        'completionRate': totalSessions > 0
            ? ((completed / totalSessions) * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      throw Exception('Failed to get system statistics: $e');
    }
  }
}
