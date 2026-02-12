import 'package:flutter/material.dart';

class GridTheme {
  static const Color deepNavy = Color(0xFF102A43);
  static const Color azureBlue = Color(0xFF243B53);
  static const Color electricYellow = Color(0xFFF7B500);

  static ThemeData themeData() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: electricYellow,
      brightness: Brightness.dark,
      primary: electricYellow,
      surface: azureBlue,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: deepNavy,
      cardColor: azureBlue,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: electricYellow,
      ),
    );
  }
}
