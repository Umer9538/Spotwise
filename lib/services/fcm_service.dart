import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }

      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // Update token in Firestore if user is logged in
      });

      // Configure foreground notification presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Setup message handlers
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('Failed to initialize FCM: $e');
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app was terminated
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        _handleTerminatedMessage(message);
      }
    });
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Notification: ${message.notification?.title}');
    debugPrint('Data: ${message.data}');

    // Display notification in app or show a banner
    // You can use a package like flutter_local_notifications for this
  }

  // Handle background message
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Message clicked! Message ID: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Navigate to specific screen based on message data
    _handleNotificationNavigation(message.data);
  }

  // Handle terminated message
  void _handleTerminatedMessage(RemoteMessage message) {
    debugPrint('App opened from terminated state via notification');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Navigate to specific screen based on message data
    _handleNotificationNavigation(message.data);
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Extract navigation data
    String? type = data['type'];
    String? reservationId = data['reservationId'];
    String? zoneId = data['zoneId'];

    // Navigate based on type
    switch (type) {
      case 'reservationConfirmed':
      case 'reservationExpiring':
        // Navigate to active reservation screen
        debugPrint('Navigate to reservation: $reservationId');
        break;
      case 'spotAvailable':
        // Navigate to zone details or map screen
        debugPrint('Navigate to zone: $zoneId');
        break;
      case 'weeklySummary':
        // Navigate to statistics screen
        debugPrint('Navigate to statistics screen');
        break;
      default:
        // Navigate to notifications screen
        debugPrint('Navigate to notifications screen');
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  // Save FCM token to user document
  Future<void> saveTokenToDatabase(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved to database');
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  // Remove FCM token from user document (on logout)
  Future<void> removeTokenFromDatabase(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      debugPrint('FCM token removed from database');
    } catch (e) {
      debugPrint('Failed to remove FCM token: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic: $e');
    }
  }

  // Subscribe to role-based topics
  Future<void> subscribeToRoleTopics(String role) async {
    await subscribeToTopic('all_users');
    await subscribeToTopic(role.toLowerCase());
  }

  // Unsubscribe from all topics
  Future<void> unsubscribeFromAllTopics(String role) async {
    await unsubscribeFromTopic('all_users');
    await unsubscribeFromTopic(role.toLowerCase());
  }

  // Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
  }

  // Check notification permission status
  Future<bool> isNotificationEnabled() async {
    try {
      NotificationSettings settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Failed to check notification status: $e');
      return false;
    }
  }

  // Request notification permission again
  Future<bool> requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
      return false;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Notification: ${message.notification?.title}');
  debugPrint('Data: ${message.data}');

  // Handle the message
  // Note: You cannot access UI context here
}
