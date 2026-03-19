import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFFA5D6A7); // verde suave
  static const Color primaryBlue = Color(0xFFBBDEFB); // azul suave
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF263238);
  static const Color textLight = Color(0xFF546E7A);

  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.green,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      color: cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: textDark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: primaryBlue,
      surface: cardLight,
      background: backgroundLight,
      error: Colors.redAccent,
    ),
  );
}
