import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';

class AdminColors {
  // Primary palette
  static const Color primary = AppColors.primaryPink;
  static const Color primaryLight = AppColors.lightPink;
  static const Color primaryDark = AppColors.darkPink;
  
  // Accent colors
  static const Color accent = AppColors.primaryPink;
  static const Color accentLight = AppColors.lightPink;
  
  // Feedback colors
  static const Color success = AppColors.success;
  static const Color warning = Colors.orange; // Fallback
  static const Color danger = AppColors.errorRed;
  static const Color info = AppColors.primaryPink;
  
  // Neutral palette
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color border = AppColors.border;
  static const Color textPrimary = AppColors.darkText;
  static const Color textSecondary = AppColors.mutedText;
  static const Color textMuted = AppColors.mutedText;
}
