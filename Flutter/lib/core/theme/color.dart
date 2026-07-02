import 'package:flutter/material.dart';

abstract class AppColors {
  // Medical Blue Palette - Trustworthy, Calm, Professional
  // Primary: Deep Blue (Trust, Stability)
  static const primaryLight = Color(0xFF0F4C75); 
  static const primaryDark = Color(0xFFBBE1FA);

  // Secondary: Soft Blue-Grey (Balance)
  static const secondary = Color(0xFF3282B8);

  // Backgrounds: Clean White / Deep Dark Blue
  static const appLightBgColor = Color(0xFFF8FAFC); // Very light grey-blue
  static const appDarkBgColor = Color(0xFF1B262C); // Dark Blue-Grey

  static const appBarColor = Color(0xFF0F4C75);
  
  // Shadows & Elevation
  static const shadowColor = Color(0x1A000000); // 10% Black
  static const shadowDarkColor = Color(0x3D000000); // 24% Black

  // Text Colors
  static const textColor = Color(0xFF1E293B); // Slate 800
  static const labelColor = Color(0xFF64748B); // Slate 500
  static const textDarkColor = Color(0xFFE2E8F0); // Slate 200

  // Inputs
  static const textBoxColor = Colors.white;
  static const textBoxDarkColor = Color(0xFF2B3A46);

  // Status Colors (Medical indicators)
  static const success = Color(0xFF10B981); // Emerald Green
  static const warning = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444); // Red
  static const info = Color(0xFF3B82F6); // Blue

  // Legacy mappings (keeping for compatibility, but updating values where appropriate)
  static const mainColor = primaryLight;
  static const appbarLightColor = Colors.white;
  static const appbarDarkColor = Color(0xFF1B262C);
  
  static const bottomBarColor = Colors.white; 
  static const bottomBarDarkColor = Color(0xFF1B262C);
  
  static const buttonColor = primaryLight;
  static const inActiveColor = Color(0xFF94A3B8);

  static const cardLightColor = Colors.white;
  static const cardDarkColor = Color(0xFF2B3A46);
  static const cardDarkStrokeColor = Color(0xFF374151);
  static const cardLightStrokeColor = Color(0xFFE2E8F0);

  static const drawerLightBgColor = appLightBgColor;
  static const drawerDarkBgColor = appDarkBgColor;
  
  static const actionColor = error;
  static const sendMessageLightColor = secondary;
  static const receiveMessageLightColor = primaryDark;
  static const onlineColor = success;

  // Chart/List Colors (Slightly muted for professional look)
  static const green = Color(0xFFA7F3D0);
  static const purple = Color(0xFFDDD6FE);
  static const yellow = Color(0xFFFDE68A);
  static const orange = Color(0xFFFED7AA);
  static const sky = Color(0xFFBAE6FD);
  static const pink = Color(0xFFFBCFE8);
  static const red = Color(0xFFFECACA);
  static const blue = Color(0xFFBFDBFE);

  static const listColors = [
    green,
    purple,
    yellow,
    orange,
    sky,
    secondary,
    red,
    blue,
    pink,
    yellow,
  ];
}
