import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFF93C5FD);
  static const Color skyBlue = Color(0xFFDBEAFE);

  // Status Colors
  static const Color availableGreen = Color(0xFF22C55E);
  static const Color occupiedRed = Color(0xFFEF4444);
  static const Color reservedYellow = Color(0xFFF59E0B);
  static const Color disabledGray = Color(0xFF9CA3AF);

  // Neutral Colors
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF3F4F6);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyBlue, backgroundWhite],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBlue, lightBlue],
  );
}
