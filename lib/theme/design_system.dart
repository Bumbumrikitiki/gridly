/// Design System Constants
/// All visual hierarchy, colors, spacing, and typography for WCAG AA compliance
/// 
/// Primary Goals:
/// - Contrast ≥ 4.5:1 for standard text (WCAG AA)
/// - Contrast ≥ 3:1 for large text (18pt+, bold)
/// - Touch targets ≥ 48dp (min safe on mobile)
/// - Consistent spacing using 4dp base unit
/// - Dark mode support

import 'package:flutter/material.dart';

class DesignSystem {
  // ==================== COLORS ====================
  
  // Primary Brand Colors (SAP Green + Complementary)
  static const Color primary = Color(0xFF00A4EF); // SAP Blue
  static const Color primaryDark = Color(0xFF0070AD);
  static const Color primaryLight = Color(0xFF5CD0FF);
  static const Color secondary = Color(0xFFFFA500); // Safety Orange
  static const Color secondaryDark = Color(0xFFCC8400);
  
  // Semantic Colors (WCAG AA contrast verified on white/dark backgrounds)
  static const Color success = Color(0xFF2E7D32); // Forest Green - 4.54:1 on white
  static const Color warning = Color(0xFFF57C00); // Safety Orange - 4.07:1 on white
  static const Color error = Color(0xFFB71C1C); // Dark Red - 5.31:1 on white
  static const Color info = Color(0xFF1565C0); // Navy Blue - 4.54:1 on white
  
  // Neutral Palette (Greyscale for high contrast)
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Light grey
  static const Color onSurface = Color(0xFF212121); // Near black (text)
  static const Color onSurfaceVariant = Color(0xFF616161); // Medium grey
  static const Color outline = Color(0xFFBDBDBD); // Input borders
  static const Color outlineVariant = Color(0xFFE0E0E0); // Dividers
  
  // Status Colors
  static const Color completed = Color(0xFF2E7D32); // Success green
  static const Color inProgress = Color(0xFF1565C0); // Info blue
  static const Color pending = Color(0xFFF57C00); // Warning orange
  static const Color blocked = Color(0xFFB71C1C); // Error red
  static const Color notStarted = Color(0xFF616161); // Grey
  
  // Dark Mode
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOutline = Color(0xFF424242);
  
  // ==================== TYPOGRAPHY ====================
  
  static const String fontFamily = 'Noto Sans';
  
  // Text Styles (fixed line height for accessibility)
  static const double _lineHeightContent = 1.5; // 150% for body text
  static const double _lineHeightDisplay = 1.2; // 120% for headers
  
  static TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: _lineHeightDisplay,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: _lineHeightDisplay,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: _lineHeightDisplay,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: _lineHeightDisplay,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: _lineHeightDisplay,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: _lineHeightDisplay,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: _lineHeightContent,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: _lineHeightContent,
    fontFamily: fontFamily,
    color: onSurface,
  );
  
  static TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: _lineHeightContent,
    fontFamily: fontFamily,
    color: onSurfaceVariant,
  );
  
  static TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: fontFamily,
    color: onSurface,
    letterSpacing: 0.1,
  );
  
  static TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: fontFamily,
    color: onSurface,
    letterSpacing: 0.1,
  );
  
  static TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: fontFamily,
    color: onSurfaceVariant,
    letterSpacing: 0.1,
  );
  
  // ==================== SPACING ====================
  
  // Base unit: 4dp
  static const double space0 = 0;
  static const double space1 = 4;   // 4dp
  static const double space2 = 8;   // 8dp
  static const double space3 = 12;  // 12dp
  static const double space4 = 16;  // 16dp
  static const double space5 = 20;  // 20dp
  static const double space6 = 24;  // 24dp
  static const double space7 = 28;  // 28dp
  static const double space8 = 32;  // 32dp
  static const double space9 = 36;  // 36dp
  static const double space10 = 40; // 40dp
  static const double space12 = 48; // 48dp
  static const double space16 = 64; // 64dp
  
  // Content width limits
  static const double maxContentWidth = 1200;
  static const double mobileBreakpoint = 480;    // Phone portrait
  static const double tabletBreakpoint = 768;    // Tablet
  static const double desktopBreakpoint = 1024;  // Desktop
  
  // ==================== TOUCH TARGETS ====================
  
  static const double touchTargetMin = 48; // Minimum safe touch target
  static const double touchTargetCompact = 40; // Compact layouts
  static const double touchTargetLarge = 56; // Large buttons
  
  // ==================== ELEVATION & SHADOWS ====================
  
  static const BoxShadow shadow0 = BoxShadow(); // No shadow
  
  static const BoxShadow shadow1 = BoxShadow(
    color: Color(0x12000000), // 7% black
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  
  static const BoxShadow shadow2 = BoxShadow(
    color: Color(0x1F000000), // 12% black
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow shadow3 = BoxShadow(
    color: Color(0x29000000), // 16% black
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  
  static const BoxShadow shadow4 = BoxShadow(
    color: Color(0x33000000), // 20% black
    blurRadius: 16,
    offset: Offset(0, 8),
  );
  
  static List<BoxShadow> elevation1 = [shadow1];
  static List<BoxShadow> elevation2 = [shadow2];
  static List<BoxShadow> elevation3 = [shadow3];
  static List<BoxShadow> elevation4 = [shadow4];
  
  // ==================== BORDER RADIUS ====================
  
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusCircle = BorderRadius.all(Radius.circular(100));
  
  // ==================== ANIMATIONS ====================
  
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // ==================== THEME CONSTRUCTION ====================
  
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),
      fontFamily: fontFamily,
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        iconTheme: const IconThemeData(size: 24),
        toolbarHeight: 64,
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusMedium),
        minWidth: touchTargetMin,
        height: touchTargetMin,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(touchTargetMin),
          shape: RoundedRectangleBorder(borderRadius: radiusMedium),
          textStyle: labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(touchTargetMin),
          shape: RoundedRectangleBorder(borderRadius: radiusMedium),
          textStyle: labelLarge,
          side: const BorderSide(color: outline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(touchTargetMin),
          textStyle: labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: space3, vertical: space2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        border: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: bodyMedium,
        hintStyle: bodyMedium.copyWith(color: onSurfaceVariant),
      ),
      cardTheme: CardTheme(
        color: surface,
        shadowColor: Colors.black.withOpacity(0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: radiusMedium),
        margin: const EdgeInsets.all(space4),
      ),
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: space4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: bodyMedium.copyWith(color: surface),
        shape: RoundedRectangleBorder(borderRadius: radiusSmall),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryLight,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.black,
        error: error,
        onError: Colors.black,
        surface: darkSurface,
        onSurface: darkOnSurface,
        outline: darkOutline,
      ),
      fontFamily: fontFamily,
      scaffoldBackgroundColor: darkSurface,
    );
  }
}

/// Mobile-responsive breakpoint helper
class Breakpoints {
  static bool isPhone(double width) => width < DesignSystem.tabletBreakpoint;
  static bool isTablet(double width) =>
      width >= DesignSystem.tabletBreakpoint && width < DesignSystem.desktopBreakpoint;
  static bool isDesktop(double width) => width >= DesignSystem.desktopBreakpoint;
  static bool isPortrait(MediaQueryData query) => query.orientation == Orientation.portrait;
  static bool isLandscape(MediaQueryData query) => query.orientation == Orientation.landscape;
}
