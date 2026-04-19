import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _currentUser;
  Map<String, dynamic>? _userStatistics;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  Map<String, dynamic>? get userStatistics => _userStatistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user data
  Future<void> loadUser(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      _currentUser = await _userService.getUserById(userId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Listen to user changes in real-time
  void listenToUser(String userId) {
    _userService.getUserStream(userId).listen(
      (user) {
        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Update user profile
  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? studentId,
    String? avatarUrl,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _userService.updateUserProfile(
        userId: userId,
        name: name,
        studentId: studentId,
        avatarUrl: avatarUrl,
      );

      // Reload user data
      await loadUser(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final downloadUrl = await _userService.uploadProfilePicture(
        userId: userId,
        imageFile: imageFile,
      );

      // Reload user data
      await loadUser(userId);

      _setLoading(false);
      return downloadUrl;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // Delete profile picture
  Future<bool> deleteProfilePicture(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      await _userService.deleteProfilePicture(userId);

      // Reload user data
      await loadUser(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences({
    required String userId,
    required NotificationPreferences preferences,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _userService.updateNotificationPreferences(
        userId: userId,
        preferences: preferences,
      );

      // Reload user data
      await loadUser(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Load user statistics
  Future<void> loadUserStatistics(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      _userStatistics = await _userService.getUserStatistics(userId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear user data (on logout)
  void clearUser() {
    _currentUser = null;
    _userStatistics = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
