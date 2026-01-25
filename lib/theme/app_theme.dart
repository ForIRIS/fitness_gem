import 'package:flutter/material.dart';

class AppTheme {
  // 2026 Trend Palette: Neo-Minimalism / Cyber-Sport
  static const Color primary = Color(0xFF6200EA); // Electric Indigo
  static const Color primaryVariant = Color(0xFF7C4DFF);

  static const Color secondary = Color(0xFF00E5FF); // Neon Cyan (Accent)
  static const Color accent = Color(0xFFCCFF00); // Lime Punch (High Energy)

  static const Color background = Color(0xFF050505); // Deep Void
  static const Color surface = Color(0xFF121212); // Obsidian
  static const Color surfaceGlass = Color(0x1AFFFFFF); // Glassmorphism base

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF00E676);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    fontFamily: 'Pretendard', // Assuming used, or default
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded Squircle-ish
        ),
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    iconTheme: const IconThemeData(color: textSecondary, size: 24),
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
