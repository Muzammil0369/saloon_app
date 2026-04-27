import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Syne — headings
  static final displayLarge  = GoogleFonts.syne(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.darkText);
  static final displayMedium = GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.darkText);
  static final headingLarge  = GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkText);
  static final headingMedium = GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkText);
  static final headingSmall  = GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText);
  static final cardTitle     = GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkText);

  // DM Sans — body
  static final bodyLarge     = GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.darkText);
  static final bodyMedium    = GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.darkText);
  static final bodySmall     = GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.mutedText);
  static final label         = GoogleFonts.dmSans(fontSize: 9,  fontWeight: FontWeight.w500, color: AppColors.mutedText);
  static final buttonText    = GoogleFonts.syne(fontSize: 13,  fontWeight: FontWeight.w700, color: Colors.white);
  static final linkText      = GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryPink);
}