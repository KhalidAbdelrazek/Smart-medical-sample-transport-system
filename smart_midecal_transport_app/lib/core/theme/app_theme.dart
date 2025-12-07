import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color.dart';

class AppTheme {
  static TextTheme appTextLightTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryLight,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryLight,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryLight,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryLight,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryLight,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryLight,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryLight,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryLight,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      color: AppColors.primaryLight,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14.sp,
      color: AppColors.primaryLight,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12.sp,
      color: AppColors.primaryLight,
    ),
    labelLarge: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.labelColor),
  );

  static TextTheme appTextDarkTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryDark,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryDark,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDark,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDark,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDark,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDark,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryDark,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryDark,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      color: AppColors.primaryDark,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14.sp,
      color: AppColors.primaryDark,
    ),
    bodySmall: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.primaryDark),
    labelLarge: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.labelColor),
  );

  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryLight,
    cardColor: AppColors.cardLightColor,
    shadowColor: Colors.black,
    scaffoldBackgroundColor: AppColors.appLightBgColor,
    fontFamily: GoogleFonts.inter().fontFamily,
    drawerTheme: DrawerThemeData(backgroundColor: AppColors.drawerLightBgColor),
    appBarTheme: AppBarTheme(
      surfaceTintColor: AppColors.cardLightColor,
      backgroundColor: AppColors.cardLightColor,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      iconTheme: IconThemeData(color: AppColors.mainColor),
      titleTextStyle: TextStyle(
        color: AppColors.mainColor,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
      ),
    ),

    textTheme: appTextLightTheme,
    iconTheme: IconThemeData(color: AppColors.mainColor),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.bottomBarColor,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.inActiveColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.textBoxColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: AppColors.labelColor),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
    ),
  );

  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.appDarkBgColor,
    drawerTheme: DrawerThemeData(backgroundColor: AppColors.drawerDarkBgColor),
    fontFamily: GoogleFonts.inter().fontFamily,
    appBarTheme: AppBarTheme(
      surfaceTintColor: AppColors.cardDarkColor,
      backgroundColor: AppColors.cardDarkColor,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardColor: AppColors.cardDarkColor,
    shadowColor: AppColors.shadowColor,
    textTheme: appTextDarkTheme,
    iconTheme: IconThemeData(color: Colors.white),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.bottomBarColor,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.inActiveColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.mainColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: AppColors.labelColor),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.black,
    ),
  );
}
