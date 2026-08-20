import 'package:flutter/material.dart';

import '../branding/brand_config.dart';

abstract final class AppTheme {
  static ThemeData light(BrandConfig brand) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brand.primaryColor,
      brightness: Brightness.light,
      primary: brand.primaryColor,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: brand.inkColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brand.canvasColor,
      fontFamily: brand.fontFamily,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9DDE6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9DDE6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: brand.inkColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
