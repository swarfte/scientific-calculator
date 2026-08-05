import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF263238);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFE8ECEF),
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
