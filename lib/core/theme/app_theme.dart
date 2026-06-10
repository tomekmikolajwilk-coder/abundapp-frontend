import 'package:flutter/material.dart';

// Jeden plik który grafik edytuje.
// Kolory, fonty, zaokrąglenia — wszystko tutaj.

class AppColors {
  // Tło
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF242424);

  // Tekst
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8A8A);

  // Akcenty
  static const positive = Color(0xFF00C896);
  static const negative = Color(0xFFFF4D4D);
  static const accent = Color(0xFF6C5CE7);

  // Wykres kołowy — kategorie
  static const categoryColors = [
    Color(0xFF6C5CE7), // krypto
    Color(0xFF00CEC9), // akcje
    Color(0xFFFDAA5E), // ETF
    Color(0xFF74B9FF), // gotówka
    Color(0xFFA29BFE), // inne
  ];
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
