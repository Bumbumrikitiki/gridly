import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
