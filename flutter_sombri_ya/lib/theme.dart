import 'package:flutter/material.dart';

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
    );
  }

}