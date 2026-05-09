import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Syne — Headings ──
  static final displayLarge = GoogleFonts.syne(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.darkText, height: 1.2,
  );
  static final displayMedium = GoogleFonts.syne(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: AppColors.darkText, height: 1.2,
  );
  static final headingLarge = GoogleFonts.syne(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: AppColors.darkText, height: 1.3,
  );
  static final headingMedium = GoogleFonts.syne(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.darkText, height: 1.3,
  );
  static final headingSmall = GoogleFonts.syne(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: AppColors.darkText, height: 1.3,
  );
  static final cardTitle = GoogleFonts.syne(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: AppColors.darkText,
  );

  // ── DM Sans — Body ──
  static final bodyLarge = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.darkText, height: 1.6,
  );
  static final bodyMedium = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.darkText, height: 1.6,
  );
  static final bodySmall = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w400,  // ← was 10, too small
    color: AppColors.mutedText, height: 1.6,
  );

  // ── Taglines — visible & readable ──
  static final tagline = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.mutedText, height: 1.5,
    letterSpacing: 0.2,
  );
  static final taglinePink = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.primaryPink, height: 1.5,
  );
  static final taglineSmall = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.mutedText, height: 1.5,
  );

  // ── Labels & Captions ──
  static final label = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w500,  // ← was 9, too small
    color: AppColors.mutedText,
  );
  static final caption = GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w400,
    color: AppColors.mutedText, letterSpacing: 0.2,
  );
  static final overline = GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: AppColors.mutedText,
    letterSpacing: 1.5,
  );

  // ── Buttons & Links ──
  static final buttonText = GoogleFonts.syne(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static final containerText = GoogleFonts.syne(
    fontSize: 45, fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static final buttonTextDark = GoogleFonts.syne(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: AppColors.darkText,
  );
  static final linkText = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w600,  // ← was 10, too small
    color: AppColors.primaryPink,
  );
}