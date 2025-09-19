import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThem { 
  static const Color primaryColor = Color(0xFF28BCEF);
  static const Color backgroundColor = Color(0xFFF5FBFF);
  static const Color accent = Color(0xFFFF4645);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: backgroundColor
    ),
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      labelStyle: const TextStyle(color: Colors.black87),
      shape: StadiumBorder(side: BorderSide(color: primaryColor, width: 1)),
    ),

    textTheme: TextTheme(
      // Titles → Hepta Slab
      headlineLarge: GoogleFonts.heptaSlab(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.heptaSlab(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.heptaSlab(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),

      // Body text → Roboto Slab
      bodyLarge: GoogleFonts.robotoSlab(fontSize: 16),
      bodyMedium: GoogleFonts.robotoSlab(fontSize: 14),
      bodySmall: GoogleFonts.robotoSlab(fontSize: 12),
    ),
    );
  }

}