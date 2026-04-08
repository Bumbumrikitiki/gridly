import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:gridly/firebase_options.dart';
import 'package:gridly/screens/splash_screen.dart';
import 'package:gridly/screens/dashboard_screen.dart';
import 'package:gridly/screens/auth_screen.dart';
import 'package:gridly/screens/paywall_screen.dart';
import 'package:gridly/screens/profile_screen.dart';
import 'package:gridly/screens/topology_screen.dart';
import 'package:gridly/screens/circuit_assessment_screen.dart';
import 'package:gridly/multitool/logic/multitool_provider.dart';
import 'package:gridly/multitool/field_guide/logic/field_guide_provider.dart';
import 'package:gridly/multitool/rcd_selector/logic/rcd_selector_provider.dart';
import 'package:gridly/multitool/zwarcie/logic/short_circuit_provider.dart';
import 'package:gridly/multitool/uziemienie/logic/grounding_provider.dart';
import 'package:gridly/multitool/uziemienie/logic/measurement_analyzer_provider.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/views/multitool_screen.dart';
import 'package:gridly/services/auth_provider.dart';
import 'package:gridly/services/app_settings_provider.dart';
import 'package:gridly/services/grid_provider.dart';
import 'package:gridly/services/monetization_provider.dart';
import 'package:gridly/services/subscription_provider.dart';
import 'package:gridly/theme/grid_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseEnabled = false;
  try {
    if (kIsWeb) {
      final webOptions = DefaultFirebaseOptions.currentPlatform;
      if (webOptions != null) {
        await Firebase.initializeApp(options: webOptions);
        firebaseEnabled = true;
      } else {
        firebaseEnabled = false;
        if (kDebugMode) {
          print(
            'Firebase Web is disabled for this run (missing FIREBASE_WEB_* values). Running in local mode.',
          );
        }
      }
    } else {
      await Firebase.initializeApp();
      firebaseEnabled = true;
    }
  } catch (e) {
    firebaseEnabled = false;
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
  }

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

  runApp(GridlyApp(firebaseEnabled: firebaseEnabled));
}

class GridlyApp extends StatelessWidget {
  const GridlyApp({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GridProvider()),
        ChangeNotifierProvider(create: (_) => MultitoolProvider()),
        ChangeNotifierProvider(create: (_) => FieldGuideProvider()),
        ChangeNotifierProvider(create: (_) => RcdSelectorProvider()),
        ChangeNotifierProvider(create: (_) => ShortCircuitProvider()),
        ChangeNotifierProvider(create: (_) => GroundingProvider()),
        ChangeNotifierProvider(create: (_) => MeasurementAnalyzerProvider()),
        ChangeNotifierProvider(create: (_) => ProjectManagerProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(firebaseEnabled: firebaseEnabled)..init(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(
            firebaseEnabled: firebaseEnabled,
            androidPackageName: 'com.gridlytools.app',
          )..init(),
          update: (_, auth, subscription) {
            final provider =
                subscription ??
                SubscriptionProvider(
                  firebaseEnabled: firebaseEnabled,
                  androidPackageName: 'com.gridlytools.app',
                )
                  ..init();
            provider.setSignedInUser(auth.firebaseUser?.uid);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()..init()),
        ChangeNotifierProxyProvider3<
          AuthProvider,
          SubscriptionProvider,
          AppSettingsProvider,
          MonetizationProvider
        >(
          create: (_) => MonetizationProvider(),
          update: (_, auth, subscription, settings, monetization) {
            final provider = monetization ?? MonetizationProvider();
            final hasPro = auth.isPro || subscription.hasActiveEntitlement;
            provider.setPro(hasPro, shouldNotify: provider.isPro != hasPro);
            provider.setAdsEnabled(
              settings.adsEnabled,
              shouldNotify: provider.adsEnabled != settings.adsEnabled,
            );
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Gridly Electrical Checker',
        theme: GridTheme.themeData(),
        initialRoute: '/dashboard',
        routes: {
          '/': (context) => const SplashScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/auth': (context) => const AuthScreen(),
          '/paywall': (context) => const PaywallScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/construction-power': (context) => const TopologyScreen(),
          '/audit': (context) => const CircuitAssessmentScreen(),
          '/multitool': (context) => const MultitoolScreen(),
        },
      ),
    );
  }
}
