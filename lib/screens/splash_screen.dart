import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/services/grid_provider.dart';
import 'package:gridly/widgets/electrical_loading_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _showDisclaimer = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    // Opóźnij inicjalizację danych do po zakończeniu bieżącej fazy budowania
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMockData();
      _startAppFlow();
    });
  }

  Future<void> _startAppFlow() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }

    setState(() {
      _showDisclaimer = true;
    });
  }

  void _acceptDisclaimerAndContinue() {
    if (_isNavigating) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  void _initializeMockData() {
    final provider = Provider.of<GridProvider>(context, listen: false);
    provider.setBuildingName('Przykładowa budowa', shouldNotify: false);

    final mainBoard = DistributionBoard(
      id: 'main',
      name: 'RG',
      powerKw: 50.0,
      lengthM: 5.0,
      crossSectionMm2: 50.0,
      ratedCurrentA: 125.0,
      material: ConductorMaterial.cu,
      isPenSplitPoint: true,
    );

    final subBoard1 = DistributionBoard(
      id: 'sub1',
      name: 'RB-1',
      powerKw: 15.0,
      lengthM: 25.0,
      crossSectionMm2: 16.0,
      ratedCurrentA: 63.0,
      material: ConductorMaterial.cu,
      isPenSplitPoint: false,
    );

    final subBoard2 = DistributionBoard(
      id: 'sub2',
      name: 'RO-1',
      powerKw: 10.0,
      lengthM: 30.0,
      crossSectionMm2: 10.0,
      ratedCurrentA: 40.0,
      material: ConductorMaterial.cu,
      isPenSplitPoint: false,
    );

    final receiver1 = PowerReceiver(
      id: 'rec1',
      name: 'Gniazda biurowe',
      powerKw: 3.5,
      lengthM: 15.0,
      crossSectionMm2: 2.5,
      ratedCurrentA: 16.0,
      material: ConductorMaterial.cu,
    );

    final receiver2 = PowerReceiver(
      id: 'rec2',
      name: 'Oświetlenie LED',
      powerKw: 1.2,
      lengthM: 20.0,
      crossSectionMm2: 1.5,
      ratedCurrentA: 10.0,
      material: ConductorMaterial.cu,
    );

    final receiver3 = PowerReceiver(
      id: 'rec3',
      name: 'Klimatyzacja',
      powerKw: 8.0,
      lengthM: 12.0,
      crossSectionMm2: 4.0,
      ratedCurrentA: 32.0,
      material: ConductorMaterial.cu,
    );

    final receiver4 = PowerReceiver(
      id: 'rec4',
      name: 'Serwer',
      powerKw: 5.5,
      lengthM: 18.0,
      crossSectionMm2: 2.5,
      ratedCurrentA: 25.0,
      material: ConductorMaterial.cu,
    );

    // Dodaj węzły bez powiadomień, wyjątek ostatni
    provider.addNode(mainBoard, shouldNotify: false);
    provider.addNode(subBoard1, parent: mainBoard, shouldNotify: false);
    provider.addNode(subBoard2, parent: mainBoard, shouldNotify: false);
    provider.addNode(receiver1, parent: subBoard1, shouldNotify: false);
    provider.addNode(receiver2, parent: subBoard1, shouldNotify: false);
    provider.addNode(receiver3, parent: subBoard2, shouldNotify: false);
    provider.addNode(
      receiver4,
      parent: subBoard2,
      shouldNotify: true,
    ); // Ostatnie powiali z notify
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                ShimmerText(
                  text: 'GRIDLY',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                  ) ?? const TextStyle(
                    fontSize: 48,
                    color: Color(0xFFF7B500),
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                  ),
                  shimmerColor: Colors.white,
                ),
                const SizedBox(height: 6),
                Text(
                  'ELECTRICAL CHECKER',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _showDisclaimer
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Card(
                                key: const ValueKey('disclaimer_card'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informacja',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Aplikacja prezentuje wyniki orientacyjne i informacyjne. Treści nie stanowią porady wykonawczej ani gwarancji zgodności.',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isNavigating
                                              ? null
                                              : _acceptDisclaimerAndContinue,
                                          child: const Text('Rozumiem'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            key: const ValueKey('loading_indicator'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElectricalLoadingAnimation(
                                  primaryColor: theme.colorScheme.primary,
                                  size: 200,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Inicjalizacja',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    LoadingDots(
                                      color: theme.colorScheme.primary,
                                      size: 6,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
