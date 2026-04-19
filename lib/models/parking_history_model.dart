import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingHistoryModel {
  final String historyId;
  final String userId;
  final String zoneId;
  final String zoneName;
  final String spotNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final HistoryStatus status;

  ParkingHistoryModel({
    required this.historyId,
    required this.userId,
    required this.zoneId,
    required this.zoneName,
    required this.spotNumber,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.status,
  });

  factory ParkingHistoryModel.fromJson(Map<String, dynamic> json) {
    return ParkingHistoryModel(
      historyId: json['history_id'],
      userId: json['user_id'],
      zoneId: json['zone_id'],
      zoneName: json['zone_name'],
      spotNumber: json['spot_number'],
      startTime: _parseDateTime(json['start_time'])!,
      endTime: json['end_time'] != null ? _parseDateTime(json['end_time']) : null,
      duration: Duration(minutes: json['duration_minutes']),
      status: HistoryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'history_id': historyId,
      'user_id': userId,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'spot_number': spotNumber,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': duration.inMinutes,
      'status': status.toString().split('.').last,
    };
  }
}

enum HistoryStatus {
  completed,
  cancelled,
  expired,
}
