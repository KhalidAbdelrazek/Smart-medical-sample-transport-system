import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color.dart';

class AppTheme {
  
  // -- Typography --
  static TextTheme appTextTheme(Color color, Color secondaryColor) => TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32.sp,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28.sp,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24.sp,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.2,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12.sp,
      fontWeight: FontWeight.normal,
      color: secondaryColor,
      height: 1.5,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      color: secondaryColor,
    ),
  );

  // -- Light Theme --
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.appLightBgColor,
    
    // Card Theme
    cardColor: AppColors.cardLightColor,
    cardTheme: CardThemeData(
      color: AppColors.cardLightColor,
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appLightBgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.primaryLight),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.primaryLight,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardLightStrokeColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardLightStrokeColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.labelColor, fontSize: 14.sp),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0, // Flat modern look, shadow controlled by container if needed
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16.sp),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
      ),
    ),

    // Text Theme
    textTheme: appTextTheme(AppColors.textColor, AppColors.labelColor),
    iconTheme: IconThemeData(color: AppColors.primaryLight),

    // Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.inActiveColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.sp),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12.sp),
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // -- Dark Theme --
  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark, // Lighter blue for dark mode
    scaffoldBackgroundColor: AppColors.appDarkBgColor,
    
    // Card Theme
    cardColor: AppColors.cardDarkColor,
    cardTheme: CardThemeData(
      color: AppColors.cardDarkColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.cardDarkStrokeColor, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appDarkBgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.textBoxDarkColor,
      filled: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardDarkStrokeColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardDarkStrokeColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 1),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.labelColor, fontSize: 14.sp),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight, // Keep primary branding even in dark
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16.sp),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
      ),
    ),

    // Text Theme
    textTheme: appTextTheme(AppColors.textDarkColor, AppColors.labelColor),
    iconTheme: IconThemeData(color: Colors.white),

    // Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.bottomBarDarkColor,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.labelColor,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.sp),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12.sp),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
