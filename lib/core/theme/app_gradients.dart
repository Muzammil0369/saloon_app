import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primaryPink, AppColors.darkPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const banner = LinearGradient(
    colors: [AppColors.primaryPink, AppColors.darkPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroBg = LinearGradient(
    colors: [Color(0xFFFFD8E8), Color(0xFFFFB0CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}