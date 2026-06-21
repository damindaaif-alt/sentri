import 'package:flutter/material.dart';

abstract class SentriColors {
  // Brand
  static const primary = Color(0xFF1A73E8);
  static const primaryDark = Color(0xFF1558B0);
  static const accent = Color(0xFF00C853);

  // Risk
  static const riskSafe = Color(0xFF2E7D32);
  static const riskLow = Color(0xFF558B2F);
  static const riskMedium = Color(0xFFF57F17);
  static const riskHigh = Color(0xFFBF360C);
  static const riskCritical = Color(0xFFB71C1C);

  // Neutrals
  static const surface = Color(0xFFF8F9FA);
  static const surfaceDark = Color(0xFF121212);
  static const onSurface = Color(0xFF202124);
  static const onSurfaceDark = Color(0xFFE8EAED);
  static const divider = Color(0xFFE0E0E0);
  static const dividerDark = Color(0xFF2D2D2D);
}

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SentriColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: SentriColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: SentriColors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: SentriColors.divider),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SentriColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        dividerTheme: const DividerThemeData(color: SentriColors.divider),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SentriColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: SentriColors.surfaceDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: SentriColors.onSurfaceDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: SentriColors.dividerDark),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        dividerTheme: const DividerThemeData(color: SentriColors.dividerDark),
      );
}
