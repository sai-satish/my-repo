import 'package:flutter/material.dart';

class AppTheme {
  // Primary color palette
  static const Color primaryColor = Color(0xFF22DD85); // Green
  static const Color headingColor = Colors.white; // White for headings
  static const Color secondaryColor = Color(0xFFBCA5ED); // Lavender for accents
  static const gradientStart = Color(0xFF07353E);
  static const gradientEnd = Color(0xFF131617);
  static const textColor = Colors.white;
  static const backgroundGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  // App theme definition
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xff131617),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xff07353E),
      ),

      textTheme: TextTheme(

        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: headingColor,
          fontFamily: 'Roboto', // Set your global font family
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: headingColor,
          fontFamily: 'Roboto',
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
          fontFamily: 'Roboto',
        ),
        bodySmall: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white10,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: headingColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

    );
  }
}
