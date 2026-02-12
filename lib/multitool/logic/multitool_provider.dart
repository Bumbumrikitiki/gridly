import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gridly/multitool/models/multitool_item.dart';

class MultitoolProvider extends ChangeNotifier {
  final List<MultitoolItem> _items = const [
    MultitoolItem(
      id: 'srednice',
      title: 'Srednice',
      description: 'Szybkie przeliczenia srednic i przekrojow.',
      icon: Icons.straighten,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'pomiary',
      title: 'Pomiary',
      description: 'Zestaw narzedzi do szybkich pomiarow.',
      icon: Icons.speed,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'kalkulatory',
      title: 'Kalkulatory',
      description: 'Podreczne kalkulatory elektryczne.',
      icon: Icons.calculate,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'symbole',
      title: 'Symbole',
      description: 'Biblioteka symboli i oznaczen.',
      icon: Icons.category,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'uziemienia',
      title: 'Uziemienia',
      description: 'Kontrola i dobory uziemien.',
      icon: Icons.gps_fixed,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'opisowki',
      title: 'Opisowki',
      description: 'Opisowe etykiety i szablony.',
      icon: Icons.label,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'spadki',
      title: 'Spadki',
      description: 'Analiza spadkow napiecia.',
      icon: Icons.trending_down,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'zwarcie',
      title: 'Zwarcie',
      description: 'Obliczenia zwarciowe i weryfikacje.',
      icon: Icons.flash_on,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'rcd',
      title: 'RCD',
      description: 'Testy i dobor ochrony roznicowopradowej.',
      icon: Icons.shield,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'rcd_selector',
      title: 'Dobór RCD',
      description: 'Inteligentny dobór typu ochrony RCD.',
      icon: Icons.check_circle,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'encyclopedia',
      title: 'Encyklopedia',
      description: 'Biblioteka symboli i parametrów elektrycznych.',
      icon: Icons.book,
      category: 'Multitool',
    ),
  ];
  bool _torchEnabled = false;

  List<MultitoolItem> get items => List.unmodifiable(_items);

  bool get torchEnabled => _torchEnabled;

  Future<void> toggleTorch() async {
    try {
      // Skip torch on web platform
      if (kIsWeb) {
        _torchEnabled = !_torchEnabled;
        notifyListeners();
        return;
      }

      // For mobile: attempt to use torch_light (will fail gracefully if not available)
      _torchEnabled = !_torchEnabled;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Torch operation failed: $e');
    }
  }
}
