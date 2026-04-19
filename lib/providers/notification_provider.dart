import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load notifications
  Future<void> loadNotifications(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      _notifications = await _notificationService.getUserNotifications(userId);
      _unreadCount = await _notificationService.getUnreadCount(userId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Listen to notifications in real-time
  void listenToNotifications(String userId) {
    _notificationService.getUserNotificationsStream(userId).listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    _notificationService.getUnreadCountStream(userId).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
    );
  }

  // Load unread notifications
  Future<void> loadUnreadNotifications(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      _notifications = await _notificationService.getUnreadNotifications(userId);
      _unreadCount = _notifications.length;

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Load notifications by type
  Future<void> loadNotificationsByType({
    required String userId,
    required NotificationType type,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      _notifications = await _notificationService.getNotificationsByType(
        userId: userId,
        type: type,
      );

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark all as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      await _notificationService.markAllAsRead(userId);
      _unreadCount = 0;

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete all notifications
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      await _notificationService.deleteAllNotifications(userId);
      _notifications = [];
      _unreadCount = 0;

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data (on logout)
  void clearAll() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
