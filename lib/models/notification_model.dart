class NotificationModel {
  final String notificationId;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'],
      userId: json['user_id'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'data': data,
    };
  }
}

enum NotificationType {
  spotAvailable,
  reservationConfirmed,
  reservationExpiring,
  reservationExpired,
  reservationCancelled,
  systemUpdate,
  weeklySummary,
}
