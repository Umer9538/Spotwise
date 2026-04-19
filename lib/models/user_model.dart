import 'parking_zone_model.dart';

class UserModel {
  final String userId;
  final String email;
  final String name;
  final String studentId;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;
  final NotificationPreferences notificationPreferences;
  final CampusType? defaultCampus;

  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.studentId,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    required this.notificationPreferences,
    this.defaultCampus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      email: json['email'],
      name: json['name'],
      studentId: json['student_id'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      notificationPreferences: NotificationPreferences.fromJson(
        json['notification_preferences'] ?? {},
      ),
      defaultCampus: json['default_campus'] != null
          ? CampusType.values.firstWhere(
              (e) => e.toString().split('.').last == json['default_campus'],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'name': name,
      'student_id': studentId,
      'role': role.toString().split('.').last,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'notification_preferences': notificationPreferences.toJson(),
      'default_campus': defaultCampus?.toString().split('.').last,
    };
  }
}

enum UserRole {
  student,
  faculty,
  staff,
  admin,
}

class NotificationPreferences {
  final bool pushEnabled;
  final bool reservationConfirmed;
  final bool expiryWarning;
  final bool spotsAvailable;
  final bool emailEnabled;

  NotificationPreferences({
    this.pushEnabled = true,
    this.reservationConfirmed = true,
    this.expiryWarning = true,
    this.spotsAvailable = false,
    this.emailEnabled = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['push_enabled'] ?? true,
      reservationConfirmed: json['reservation_confirmed'] ?? true,
      expiryWarning: json['expiry_warning'] ?? true,
      spotsAvailable: json['spots_available'] ?? false,
      emailEnabled: json['email_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'reservation_confirmed': reservationConfirmed,
      'expiry_warning': expiryWarning,
      'spots_available': spotsAvailable,
      'email_enabled': emailEnabled,
    };
  }
}
