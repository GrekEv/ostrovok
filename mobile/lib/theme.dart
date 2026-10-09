import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF0F6B4C);
  static const leaf = Color(0xFF1D9A6C);
  static const mint = Color(0xFFE8F6EF);
  static const foam = Color(0xFFF7FCF9);
  static const ink = Color(0xFF1A2E24);
  static const muted = Color(0xFF5A7064);
  static const nope = Color(0xFFC45C4E);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.leaf,
    primary: AppColors.leaf,
    surface: AppColors.foam,
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.foam,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.foam,
      foregroundColor: AppColors.ink,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.mint,
    ),
  );
}
