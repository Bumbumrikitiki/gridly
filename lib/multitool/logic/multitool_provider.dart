import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gridly/multitool/models/multitool_item.dart';

class MultitoolProvider extends ChangeNotifier {
  final List<MultitoolItem> _items = const [
    MultitoolItem(
      id: 'spadki',
      title: 'Obliczanie spadku napięcia',
      description: 'Obliczenia spadku napięcia DC/AC dla 1f i 3f.',
      icon: Icons.trending_down,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'srednice',
      title: 'Dobór rur termokurczliwych',
      description: 'Dobór rur termokurczliwych do kabli i przekrojów.',
      icon: Icons.straighten,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'opisowki',
      title: 'Generator znaczników opisowych',
      description: 'Generator znaczników i etykiet opisowych.',
      icon: Icons.label,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'ekspert_kabli',
      title: 'Ekspert kabli',
      description: 'Weryfikator izolacji i zgodnosci CPR/PN.',
      icon: Icons.verified_user,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'osd_checker',
      title: 'Przygotowanie do odbiorów OSD',
      description: 'Przygotowanie i checklista do odbiorów przyłącza OSD.',
      icon: Icons.rule_folder,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'rcd_selector',
      title: 'RCD',
      description: 'Inteligentny dobór typu ochrony RCD.',
      icon: Icons.check_circle,
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
      id: 'zwarcie',
      title: 'Zwarcie',
      description: 'Obliczenia zwarciowe i weryfikacje.',
      icon: Icons.flash_on,
      category: 'Multitool',
    ),
    MultitoolItem(
      id: 'manager_projektu',
      title: 'Manager Projektu',
      description: 'Inteligentny asystent budowy z checklistą.',
      icon: Icons.construction,
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
