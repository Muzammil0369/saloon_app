import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary:   AppColors.primaryPink,
      secondary: AppColors.darkPink,
      surface:   AppColors.surface,
      error:     Color(0xFFE53935),
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.dmSans().fontFamily,
    fontFamilyFallback: [GoogleFonts.notoSansArabic().fontFamily!],

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor:  AppColors.surface,
      elevation:        0,
      scrolledUnderElevation: 0,
      centerTitle:      true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.syne(
        fontSize:   16,
        fontWeight: FontWeight.w800,
        color:      AppColors.darkText,
      ),
      iconTheme: IconThemeData(color: AppColors.darkText),
    ),

    // ElevatedButton → primary gradient button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:  AppColors.primaryPink,
        foregroundColor:  Colors.white,
        minimumSize:      Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
        textStyle: GoogleFonts.syne(
          fontSize:   13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // OutlinedButton → secondary button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.mutedText,
        minimumSize:     Size(double.infinity, 44),
        side:            BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // TextButton → link style
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryPink,
        textStyle: GoogleFonts.dmSans(
          fontSize:   10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // InputDecoration → all text fields
    inputDecorationTheme: InputDecorationTheme(
      filled:      true,
      fillColor:   AppColors.surface,
      hintStyle:   GoogleFonts.dmSans(
        fontSize: 11,
        color:    AppColors.mutedText,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: AppColors.primaryPink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
    ),

    // BottomNavigationBar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:      AppColors.surface,
      selectedItemColor:    AppColors.primaryPink,
      unselectedItemColor:  AppColors.mutedText,
      selectedLabelStyle:   GoogleFonts.dmSans(fontSize: 9,  fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 9,  fontWeight: FontWeight.w500),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Card
    cardTheme: CardThemeData(
      color:     AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color:     AppColors.border,
      thickness: 1,
      space:     1,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor:   AppColors.surface,
      selectedColor:     AppColors.primaryPink,
      labelStyle: GoogleFonts.dmSans(
        fontSize:   10,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: AppColors.border, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary:   AppColors.primaryPink,
      secondary: AppColors.darkPink,
      surface:   AppColors.darkSurface,
      error:     Color(0xFFE53935),
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: GoogleFonts.dmSans().fontFamily,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 16, fontWeight: FontWeight.w800,
        color: AppColors.darkText_dark,
      ),
      iconTheme: IconThemeData(color: AppColors.darkText_dark),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkMutedText,
        minimumSize: Size(double.infinity, 44),
        side: BorderSide(color: AppColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      hintStyle: GoogleFonts.dmSans(fontSize: 11, color: AppColors.darkMutedText),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryPink, width: 1.5),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:      AppColors.darkSurface,
      selectedItemColor:    AppColors.primaryPink,
      unselectedItemColor:  AppColors.darkMutedText,
      selectedLabelStyle:   GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w500),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.darkBorder, thickness: 1, space: 1,
    ),
  );
}