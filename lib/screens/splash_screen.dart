import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/services/grid_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

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

    final accepted = await _showStartupDisclaimer();
    if (!mounted || !accepted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  Future<bool> _showStartupDisclaimer() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Informacja'),
          content: const Text(
            'Aplikacja prezentuje wyniki orientacyjne i informacyjne. Treści nie stanowią porady wykonawczej ani gwarancji zgodności.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Rozumiem'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GRIDLY ELECTRICAL CHECKER',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 32),
                const SizedBox(width: 180, child: LinearProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
