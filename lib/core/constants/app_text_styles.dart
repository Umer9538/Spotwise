import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.5,
  );

  // Body Text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle bodyLight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.5,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.5,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.5,
  );

  // Small
  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.5,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.backgroundWhite,
    height: 1.5,
  );

  // Monospace (for codes)
  static const TextStyle monospace = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Courier',
    letterSpacing: 2,
  );
}
