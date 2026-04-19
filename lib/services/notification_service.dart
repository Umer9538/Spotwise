import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: _uuid.v4(),
        userId: userId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get all notifications for user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  // Get notifications stream
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get unread notifications: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Get unread count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType({
    required String userId,
    required NotificationType type,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications by type: $e');
    }
  }

  // Get notifications by type stream
  Stream<List<NotificationModel>> getNotificationsByTypeStream({
    required String userId,
    required NotificationType type,
  }) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications for user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Delete old notifications (older than X days)
  Future<void> deleteOldNotifications({
    required String userId,
    int daysOld = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }

  // Create spot available notification
  Future<void> notifySpotAvailable({
    required String userId,
    required String zoneName,
    required int availableSpots,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.spotAvailable,
      title: 'Parking Spots Available',
      message: '$availableSpots spots are now available in $zoneName',
      data: {
        'zoneName': zoneName,
        'availableSpots': availableSpots,
      },
    );
  }

  // Create weekly summary notification
  Future<void> createWeeklySummary({
    required String userId,
    required Map<String, dynamic> summary,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.weeklySummary,
      title: 'Your Weekly Parking Summary',
      message:
          'You parked ${summary['totalParkings']} times this week for a total of ${summary['totalHours']} hours',
      data: summary,
    );
  }

  // Create system update notification
  Future<void> createSystemUpdate({
    required String title,
    required String message,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      // Create notification for each user
      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notification = NotificationModel(
          notificationId: _uuid.v4(),
          userId: userDoc.id,
          type: NotificationType.systemUpdate,
          title: title,
          message: message,
          createdAt: DateTime.now(),
          isRead: false,
        );

        batch.set(
          _firestore.collection('notifications').doc(notification.notificationId),
          notification.toJson(),
        );
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create system update: $e');
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStatistics(String userId) async {
    try {
      final allNotifications = await getUserNotifications(userId);
      final unreadNotifications = await getUnreadNotifications(userId);

      Map<String, int> typeCount = {};
      for (var notification in allNotifications) {
        String type = notification.type.toString().split('.').last;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      return {
        'total': allNotifications.length,
        'unread': unreadNotifications.length,
        'read': allNotifications.length - unreadNotifications.length,
        'typeCount': typeCount,
      };
    } catch (e) {
      throw Exception('Failed to get notification statistics: $e');
    }
  }

  // Filter notifications by date range
  Future<List<NotificationModel>> getNotificationsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications by date range: $e');
    }
  }
}
