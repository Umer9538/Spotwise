import 'package:flutter/foundation.dart';
import '../models/parking_zone_model.dart';
import '../models/parking_spot_model.dart';
import '../models/reservation_model.dart';
import '../models/parking_history_model.dart';
import '../services/zone_service.dart';
import '../services/reservation_service.dart';
import '../services/history_service.dart';

class ParkingProvider with ChangeNotifier {
  final ZoneService _zoneService = ZoneService();
  final ReservationService _reservationService = ReservationService();
  final HistoryService _historyService = HistoryService();

  // Zones
  List<ParkingZoneModel> _zones = [];
  ParkingZoneModel? _selectedZone;
  List<ParkingSpotModel> _spots = [];
  ParkingSpotModel? _selectedSpot;

  // Reservations
  ReservationModel? _activeReservation;
  List<ReservationModel> _userReservations = [];

  // History
  List<ParkingHistoryModel> _parkingHistory = [];

  // State
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ParkingZoneModel> get zones => _zones;
  ParkingZoneModel? get selectedZone => _selectedZone;
  List<ParkingSpotModel> get spots => _spots;
  ParkingSpotModel? get selectedSpot => _selectedSpot;
  ReservationModel? get activeReservation => _activeReservation;
  List<ReservationModel> get userReservations => _userReservations;
  List<ParkingHistoryModel> get parkingHistory => _parkingHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // === ZONES ===

  // Load all zones
  Future<void> loadZones() async {
    try {
      _setLoading(true);
      _error = null;

      _zones = await _zoneService.getAllZones();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Listen to zones in real-time
  void listenToZones() {
    _zoneService.getZonesStream().listen(
      (zones) {
        _zones = zones;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Load zones by campus
  Future<void> loadZonesByCampus(CampusType campus) async {
    try {
      _setLoading(true);
      _error = null;

      _zones = await _zoneService.getZonesByCampus(campus);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Load zones with available spots
  Future<void> loadZonesWithAvailableSpots() async {
    try {
      _setLoading(true);
      _error = null;

      _zones = await _zoneService.getZonesWithAvailableSpots();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Select a zone
  Future<void> selectZone(String zoneId) async {
    try {
      _setLoading(true);
      _error = null;

      _selectedZone = await _zoneService.getZoneById(zoneId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Listen to selected zone in real-time
  void listenToSelectedZone(String zoneId) {
    _zoneService.getZoneStreamById(zoneId).listen(
      (zone) {
        _selectedZone = zone;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Clear selected zone
  void clearSelectedZone() {
    _selectedZone = null;
    _spots = [];
    _selectedSpot = null;
    notifyListeners();
  }

  // === SPOTS ===

  // Load spots for a zone
  Future<void> loadSpotsByZone(String zoneId) async {
    try {
      _setLoading(true);
      _error = null;

      _spots = await _zoneService.getSpotsByZone(zoneId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Listen to spots in real-time
  void listenToSpots(String zoneId) {
    _zoneService.getSpotsByZoneStream(zoneId).listen(
      (spots) {
        _spots = spots;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Load available spots
  Future<void> loadAvailableSpots(String zoneId) async {
    try {
      _setLoading(true);
      _error = null;

      _spots = await _zoneService.getAvailableSpotsByZone(zoneId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Select a spot
  void selectSpot(ParkingSpotModel spot) {
    _selectedSpot = spot;
    notifyListeners();
  }

  // Clear selected spot
  void clearSelectedSpot() {
    _selectedSpot = null;
    notifyListeners();
  }

  // === RESERVATIONS ===

  // Load active reservation
  Future<void> loadActiveReservation(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      _activeReservation = await _reservationService.getActiveReservation(userId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Listen to active reservation in real-time
  void listenToActiveReservation(String userId) {
    _reservationService.getActiveReservationStream(userId).listen(
      (reservation) {
        _activeReservation = reservation;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Create reservation
  Future<bool> createReservation({
    required String userId,
    required String spotId,
    required String zoneId,
    required String spotNumber,
    required Duration duration,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      _activeReservation = await _reservationService.createReservation(
        userId: userId,
        spotId: spotId,
        zoneId: zoneId,
        spotNumber: spotNumber,
        duration: duration,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Extend reservation
  Future<bool> extendReservation({
    required String reservationId,
    required Duration additionalDuration,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _reservationService.extendReservation(
        reservationId: reservationId,
        additionalDuration: additionalDuration,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Cancel reservation
  Future<bool> cancelReservation(String reservationId) async {
    try {
      _setLoading(true);
      _error = null;

      await _reservationService.cancelReservation(reservationId);
      _activeReservation = null;

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Complete reservation
  Future<bool> completeReservation(String reservationId) async {
    try {
      _setLoading(true);
      _error = null;

      await _reservationService.completeReservation(reservationId);
      _activeReservation = null;

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Load user reservations
  Future<void> loadUserReservations(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      _userReservations = await _reservationService.getUserReservations(userId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // === HISTORY ===

  // Load parking history
  Future<void> loadParkingHistory(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      _parkingHistory = await _historyService.getUserHistory(userId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Listen to parking history in real-time
  void listenToParkingHistory(String userId) {
    _historyService.getUserHistoryStream(userId).listen(
      (history) {
        _parkingHistory = history;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Load history by period
  Future<void> loadHistoryByPeriod({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      _parkingHistory = await _historyService.getHistoryByPeriod(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Load recent history
  Future<void> loadRecentHistory(String userId, {int limit = 5}) async {
    try {
      _setLoading(true);
      _error = null;

      _parkingHistory = await _historyService.getRecentHistory(
        userId: userId,
        limit: limit,
      );

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // === UTILITY ===

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data (on logout)
  void clearAll() {
    _zones = [];
    _selectedZone = null;
    _spots = [];
    _selectedSpot = null;
    _activeReservation = null;
    _userReservations = [];
    _parkingHistory = [];
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
