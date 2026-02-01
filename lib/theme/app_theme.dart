import 'package:flutter/material.dart';

class AppTheme {
  // 2026 Trend Palette: Pantone Data
  static const Color cloudDancer = Color(0xFFF0EEE9); // 11-4201 TCX
  static const Color irisOrchid = Color(0xFFB57EDC); // 17-3323 TCX
  static const Color capri = Color(0xFF00B0E0); // 15-4722 TCX
  static const Color kiwiColada = Color(0xFFD8DE73); // 14-0443 TCX
  static const Color sunnyLime = Color(0xFFE9F299); // 12-0741 TCX
  static const Color brightMarigold = Color(0xFFFFA800); // 15-1164 TCX (Approx)
  static const Color paradisePink = Color(0xFFE63E62); // 17-1755 TCX
  static const Color blazingYellow = Color(0xFFFEE715); // 12-0643 TCX (Approx)

  // Semantic Aliases
  static const Color primary = irisOrchid;
  static const Color background = cloudDancer;
  static const Color surface = Colors.white;
  static const Color accent = capri;
  static const Color error = paradisePink;
  static const Color success = kiwiColada;
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Keep readable dark slate
  static const Color textSecondary = Color(0xFF64748B);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    fontFamily: 'Pretendard',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.transparent),
      ),
    ),
    iconTheme: const IconThemeData(color: textPrimary, size: 24),
  );

  // Gradient Styles
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF7F00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
