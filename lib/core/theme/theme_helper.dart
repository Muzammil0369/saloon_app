// lib/core/theme/theme_helper.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class ThemeHelper {
  final BuildContext context;

  ThemeHelper(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Container/Card colors
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.card;
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get backgroundColor => isDark ? AppColors.darkBackground : AppColors.background;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.border;
  Color get lightPinkColor => isDark ? AppColors.darkLightPink : AppColors.lightPink;

  // Text colors
  Color get textColor => isDark ? AppColors.darkText_dark : AppColors.darkText;
  Color get mutedTextColor => isDark ? AppColors.darkMutedText : AppColors.mutedText;

  // Grey scale replacements (softer dark greys)
  Color grey50() => isDark ? const Color(0xFF1A1518) : Colors.grey[50]!;
  Color grey100() => isDark ? const Color(0xFF221C20) : Colors.grey[100]!;
  Color grey200() => isDark ? const Color(0xFF2D2428) : Colors.grey[200]!;
  Color grey300() => isDark ? const Color(0xFF3D3438) : Colors.grey[300]!;
  Color grey400() => isDark ? const Color(0xFF5D5458) : Colors.grey[400]!;
  Color grey500() => isDark ? const Color(0xFF8D8488) : Colors.grey[500]!;
  Color grey600() => isDark ? const Color(0xFFADA4A8) : Colors.grey[600]!;
  Color grey800() => isDark ? const Color(0xFFDDD4D8) : Colors.grey[800]!;

  // Shadow
  BoxShadow get cardShadow => BoxShadow(
    color: isDark
        ? Colors.black.withOpacity(0.3)
        : AppColors.primaryPink.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  BoxShadow get softShadow => BoxShadow(
    color: isDark
        ? Colors.black.withOpacity(0.2)
        : AppColors.primaryPink.withOpacity(0.08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
}