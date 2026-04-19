import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();

      // Save FCM token when user logs in
      if (user != null) {
        _fcmService.saveTokenToDatabase(user.uid);
      }
    });
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        studentId: studentId,
        role: role,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;

      final userCredential = await _authService.signInWithGoogle();

      _setLoading(false);
      return userCredential != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.sendEmailVerification();

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      _user = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reload user: $e');
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.sendPasswordResetEmail(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.updatePassword(newPassword);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update email
  Future<bool> updateEmail(String newEmail) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.updateEmail(newEmail);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);

      // Remove FCM token
      if (_user != null) {
        await _fcmService.removeTokenFromDatabase(_user!.uid);
      }

      await _authService.signOut();

      _user = null;
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _error = null;

      // Remove FCM token
      if (_user != null) {
        await _fcmService.removeTokenFromDatabase(_user!.uid);
      }

      await _authService.deleteAccount();

      _user = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
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

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
