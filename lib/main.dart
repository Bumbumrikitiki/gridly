import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:gridly/screens/splash_screen.dart';
import 'package:gridly/screens/dashboard_screen.dart';
import 'package:gridly/screens/construction_power_screen.dart';
import 'package:gridly/screens/circuit_assessment_screen.dart';
import 'package:gridly/multitool/logic/multitool_provider.dart';
import 'package:gridly/multitool/field_guide/logic/field_guide_provider.dart';
import 'package:gridly/multitool/rcd_selector/logic/rcd_selector_provider.dart';
import 'package:gridly/multitool/views/multitool_screen.dart';
import 'package:gridly/services/grid_provider.dart';
import 'package:gridly/services/monetization_provider.dart';
import 'package:gridly/theme/grid_theme.dart';

void main() {
  // Global error handler for Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack Trace: ${details.stack}');
    }
  };

  // Handle async errors
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Async Error: $error');
      print('Stack: $stack');
    }
    return true;
  };

  runApp(const GridlyApp());
}

class GridlyApp extends StatelessWidget {
  const GridlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GridProvider()),
        ChangeNotifierProvider(create: (_) => MultitoolProvider()),
        ChangeNotifierProvider(create: (_) => FieldGuideProvider()),
        ChangeNotifierProvider(create: (_) => RcdSelectorProvider()),
        ChangeNotifierProvider(create: (_) => MonetizationProvider()),
      ],
      child: MaterialApp(
        title: 'Gridly Electrical Checker',
        theme: GridTheme.themeData(),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/construction-power': (context) => const ConstructionPowerScreen(),
          '/audit': (context) => const CircuitAssessmentScreen(),
          '/multitool': (context) => const MultitoolScreen(),
        },
      ),
    );
  }
}
