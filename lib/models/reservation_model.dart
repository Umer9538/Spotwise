import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String reservationId;
  final String userId;
  final String spotId;
  final String zoneId;
  final String spotNumber;
  final DateTime reservedAt;
  final DateTime expiresAt;
  final ReservationStatus status;
  final String confirmationCode;
  final Duration duration;

  ReservationModel({
    required this.reservationId,
    required this.userId,
    required this.spotId,
    required this.zoneId,
    required this.spotNumber,
    required this.reservedAt,
    required this.expiresAt,
    required this.status,
    required this.confirmationCode,
    required this.duration,
  });

  Duration get timeRemaining {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  bool get isExpiringSoon {
    return timeRemaining.inMinutes <= 5 && timeRemaining.inMinutes > 0;
  }

  bool get isExpired {
    return timeRemaining == Duration.zero;
  }

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      reservationId: json['reservation_id'],
      userId: json['user_id'],
      spotId: json['spot_id'],
      zoneId: json['zone_id'],
      spotNumber: json['spot_number'],
      reservedAt: _parseDateTime(json['reserved_at']),
      expiresAt: _parseDateTime(json['expires_at']),
      status: ReservationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      confirmationCode: json['confirmation_code'],
      duration: Duration(minutes: json['duration_minutes']),
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
      'reservation_id': reservationId,
      'user_id': userId,
      'spot_id': spotId,
      'zone_id': zoneId,
      'spot_number': spotNumber,
      'reserved_at': reservedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'confirmation_code': confirmationCode,
      'duration_minutes': duration.inMinutes,
    };
  }
}

enum ReservationStatus {
  active,
  completed,
  cancelled,
  expired,
}
