import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../models/reservation_model.dart';
import '../models/parking_history_model.dart';
import '../models/parking_spot_model.dart';
import '../models/notification_model.dart';
import 'zone_service.dart';
import 'notification_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ZoneService _zoneService = ZoneService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Create a new reservation
  Future<ReservationModel> createReservation({
    required String userId,
    required String spotId,
    required String zoneId,
    required String spotNumber,
    required Duration duration,
  }) async {
    try {
      // Check if spot is available
      final spot = await _zoneService.getSpotById(zoneId, spotId);
      if (spot == null) {
        throw Exception('Parking spot not found');
      }

      if (spot.status != SpotStatus.available) {
        throw Exception('Parking spot is not available');
      }

      // Check if user already has an active reservation
      final activeReservations = await _firestore
          .collection('reservations')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (activeReservations.docs.isNotEmpty) {
        // Check if the reservation is actually expired
        final existingReservation = ReservationModel.fromJson(activeReservations.docs.first.data());
        if (existingReservation.isExpired) {
          // Auto-expire the old reservation
          debugPrint('🔄 Auto-expiring old reservation: ${existingReservation.reservationId}');
          await expireReservation(existingReservation.reservationId);
        } else {
          throw Exception('You already have an active reservation');
        }
      }

      // Generate confirmation code
      final confirmationCode = _generateConfirmationCode();

      // Create reservation
      final reservation = ReservationModel(
        reservationId: _uuid.v4(),
        userId: userId,
        spotId: spotId,
        zoneId: zoneId,
        spotNumber: spotNumber,
        reservedAt: DateTime.now(),
        expiresAt: DateTime.now().add(duration),
        status: ReservationStatus.active,
        confirmationCode: confirmationCode,
        duration: duration,
      );

      // Save to Firestore
      await _firestore
          .collection('reservations')
          .doc(reservation.reservationId)
          .set(reservation.toJson());

      // Update spot status to reserved
      await _zoneService.updateSpotStatus(
        zoneId: zoneId,
        spotId: spotId,
        status: SpotStatus.reserved,
      );

      // Send notification
      await _notificationService.createNotification(
        userId: userId,
        type: NotificationType.reservationConfirmed,
        title: 'Reservation Confirmed',
        message:
            'Your parking spot $spotNumber has been reserved. Confirmation code: $confirmationCode',
        data: {
          'reservationId': reservation.reservationId,
          'spotNumber': spotNumber,
          'expiresAt': reservation.expiresAt.toIso8601String(),
        },
      );

      return reservation;
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  // Get active reservation for user
  Future<ReservationModel?> getActiveReservation(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('reserved_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReservationModel.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get active reservation: $e');
    }
  }

  // Get active reservation stream
  Stream<ReservationModel?> getActiveReservationStream(String userId) {
    debugPrint('📡 Setting up active reservation stream for user: $userId');
    return _firestore
        .collection('reservations')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('reserved_at', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
      debugPrint('📡 Stream update - found ${snapshot.docs.length} active reservations');
      if (snapshot.docs.isNotEmpty) {
        final reservation = ReservationModel.fromJson(snapshot.docs.first.data());

        // Check if reservation is expired
        if (reservation.isExpired) {
          debugPrint('⏰ Reservation expired, auto-expiring: ${reservation.reservationId}');
          await expireReservation(reservation.reservationId);
          debugPrint('❌ No active reservation found (expired)');
          return null;
        }

        debugPrint('✅ Active reservation found: ${reservation.reservationId}');
        return reservation;
      }
      debugPrint('❌ No active reservation found');
      return null;
    });
  }

  // Get reservation by ID
  Future<ReservationModel?> getReservationById(String reservationId) async {
    try {
      final doc =
          await _firestore.collection('reservations').doc(reservationId).get();

      if (doc.exists) {
        return ReservationModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get reservation: $e');
    }
  }

  // Extend reservation time
  Future<void> extendReservation({
    required String reservationId,
    required Duration additionalDuration,
  }) async {
    try {
      final reservation = await getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found');
      }

      if (reservation.status != ReservationStatus.active) {
        throw Exception('Reservation is not active');
      }

      if (reservation.isExpired) {
        throw Exception('Reservation has already expired');
      }

      // Update expiration time
      final newExpiresAt = reservation.expiresAt.add(additionalDuration);
      final newDuration = newExpiresAt.difference(reservation.reservedAt);

      await _firestore.collection('reservations').doc(reservationId).update({
        'expires_at': Timestamp.fromDate(newExpiresAt),
        'duration_minutes': newDuration.inMinutes,
      });

      // Send notification
      await _notificationService.createNotification(
        userId: reservation.userId,
        type: NotificationType.reservationConfirmed,
        title: 'Reservation Extended',
        message:
            'Your reservation has been extended by ${additionalDuration.inMinutes} minutes',
        data: {
          'reservationId': reservationId,
          'newExpiresAt': newExpiresAt.toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to extend reservation: $e');
    }
  }

  // Cancel reservation
  Future<void> cancelReservation(String reservationId) async {
    try {
      final reservation = await getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found');
      }

      if (reservation.status != ReservationStatus.active) {
        throw Exception('Reservation is not active');
      }

      // Update reservation status
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': 'cancelled',
      });

      // Update spot status back to available
      await _zoneService.updateSpotStatus(
        zoneId: reservation.zoneId,
        spotId: reservation.spotId,
        status: SpotStatus.available,
      );

      // Create history entry
      await _createHistoryEntry(
        reservation: reservation,
        status: HistoryStatus.cancelled,
      );

      // Send notification
      await _notificationService.createNotification(
        userId: reservation.userId,
        type: NotificationType.reservationCancelled,
        title: 'Reservation Cancelled',
        message: 'Your reservation for spot ${reservation.spotNumber} has been cancelled',
        data: {
          'reservationId': reservationId,
        },
      );
    } catch (e) {
      throw Exception('Failed to cancel reservation: $e');
    }
  }

  // Complete reservation (user has parked)
  Future<void> completeReservation(String reservationId) async {
    try {
      final reservation = await getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found');
      }

      if (reservation.status != ReservationStatus.active) {
        throw Exception('Reservation is not active');
      }

      // Update reservation status
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': 'completed',
      });

      // Update spot status to occupied
      await _zoneService.updateSpotStatus(
        zoneId: reservation.zoneId,
        spotId: reservation.spotId,
        status: SpotStatus.occupied,
      );

      // Create history entry
      await _createHistoryEntry(
        reservation: reservation,
        status: HistoryStatus.completed,
      );
    } catch (e) {
      throw Exception('Failed to complete reservation: $e');
    }
  }

  // Expire reservation (called automatically or manually)
  Future<void> expireReservation(String reservationId) async {
    try {
      final reservation = await getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found');
      }

      if (reservation.status != ReservationStatus.active) {
        return; // Already handled
      }

      // Update reservation status
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': 'expired',
      });

      // Update spot status back to available
      await _zoneService.updateSpotStatus(
        zoneId: reservation.zoneId,
        spotId: reservation.spotId,
        status: SpotStatus.available,
      );

      // Create history entry
      await _createHistoryEntry(
        reservation: reservation,
        status: HistoryStatus.expired,
      );

      // Send notification
      await _notificationService.createNotification(
        userId: reservation.userId,
        type: NotificationType.reservationExpired,
        title: 'Reservation Expired',
        message: 'Your reservation for spot ${reservation.spotNumber} has expired',
        data: {
          'reservationId': reservationId,
        },
      );
    } catch (e) {
      throw Exception('Failed to expire reservation: $e');
    }
  }

  // Check and expire old reservations
  Future<void> checkAndExpireReservations() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'active')
          .where('expires_at', isLessThan: Timestamp.fromDate(now))
          .get();

      for (var doc in snapshot.docs) {
        await expireReservation(doc.id);
      }
    } catch (e) {
      throw Exception('Failed to check and expire reservations: $e');
    }
  }

  // Send expiring soon notifications
  Future<void> sendExpiringNotifications() async {
    try {
      final now = DateTime.now();
      final fiveMinutesLater = now.add(const Duration(minutes: 5));

      final snapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'active')
          .where('expires_at',
              isGreaterThan: Timestamp.fromDate(now),
              isLessThanOrEqualTo: Timestamp.fromDate(fiveMinutesLater))
          .get();

      for (var doc in snapshot.docs) {
        final reservation = ReservationModel.fromJson(doc.data());

        // Check if notification was already sent
        final existingNotifications = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: reservation.userId)
            .where('type', isEqualTo: 'reservationExpiring')
            .where('data.reservationId', isEqualTo: reservation.reservationId)
            .get();

        if (existingNotifications.docs.isEmpty) {
          await _notificationService.createNotification(
            userId: reservation.userId,
            type: NotificationType.reservationExpiring,
            title: 'Reservation Expiring Soon',
            message:
                'Your reservation for spot ${reservation.spotNumber} expires in ${reservation.timeRemaining.inMinutes} minutes',
            data: {
              'reservationId': reservation.reservationId,
              'expiresAt': reservation.expiresAt.toIso8601String(),
            },
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to send expiring notifications: $e');
    }
  }

  // Get all reservations for user
  Future<List<ReservationModel>> getUserReservations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('user_id', isEqualTo: userId)
          .orderBy('reserved_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReservationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reservations: $e');
    }
  }

  // Get reservations by status
  Future<List<ReservationModel>> getReservationsByStatus({
    required String userId,
    required ReservationStatus status,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('reserved_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReservationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reservations by status: $e');
    }
  }

  // Create parking history entry
  Future<void> _createHistoryEntry({
    required ReservationModel reservation,
    required HistoryStatus status,
  }) async {
    try {
      // Get zone details
      final zone = await _zoneService.getZoneById(reservation.zoneId);
      if (zone == null) return;

      final history = ParkingHistoryModel(
        historyId: _uuid.v4(),
        userId: reservation.userId,
        zoneId: reservation.zoneId,
        zoneName: zone.zoneName,
        spotNumber: reservation.spotNumber,
        startTime: reservation.reservedAt,
        endTime: DateTime.now(),
        duration: DateTime.now().difference(reservation.reservedAt),
        status: status,
      );

      await _firestore
          .collection('parking_history')
          .doc(history.historyId)
          .set(history.toJson());
    } catch (e) {
      // Log error but don't throw - history is not critical
      print('Failed to create history entry: $e');
    }
  }

  // Generate random confirmation code
  String _generateConfirmationCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000; // 6 digit code
    return code.toString();
  }

  // Get all active reservations (admin only)
  Future<List<ReservationModel>> getAllActiveReservations() async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'active')
          .orderBy('reserved_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReservationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all active reservations: $e');
    }
  }

  // Get reservation statistics
  Future<Map<String, dynamic>> getReservationStatistics() async {
    try {
      final activeSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'active')
          .get();

      final completedSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'completed')
          .get();

      final cancelledSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'cancelled')
          .get();

      final expiredSnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'expired')
          .get();

      return {
        'active': activeSnapshot.docs.length,
        'completed': completedSnapshot.docs.length,
        'cancelled': cancelledSnapshot.docs.length,
        'expired': expiredSnapshot.docs.length,
        'total': activeSnapshot.docs.length +
            completedSnapshot.docs.length +
            cancelledSnapshot.docs.length +
            expiredSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get reservation statistics: $e');
    }
  }
}
