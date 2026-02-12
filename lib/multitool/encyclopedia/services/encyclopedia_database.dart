import 'package:gridly/multitool/encyclopedia/models/encyclopedia_models.dart';

class EncyclopediaDatabase {
  static final List<ElectricalSymbol> protectionSymbols = [
    ElectricalSymbol(
      id: 'surge_protector',
      name: 'Ochronnik przepięć',
      description: 'Zabezpieczenie przed przepięciami',
      icon: '⚡',
      category: 'Ochrona',
      fullDescription:
          'Ochronnik przepięć (SPD) to urządzenie zabezpieczające instalacje elektryczne przed uszkodzeniami spowodowanymi przepięciami atmosferycznymi lub przepięciami przełączeniowymi.',
      parameters: {
        'T1': 'Typ I - ochrona główna (dla wyładowań bezpośrednich)',
        'T2': 'Typ II - ochrona wtórna (dla przepięć przełączeniowych)',
        'T3': 'Typ III - ochrona końcowa (przy odbiornikach)',
        'Uc': 'Napięcie warunkowe (zwykle 275-800V)',
        'Uoc': 'Napięcie ochrony (Max 1500V)',
      },
    ),
    ElectricalSymbol(
      id: 'circuit_breaker',
      name: 'Wyłącznik automatyczny',
      description: 'Zabezpieczenie przed przegrzaniem i zwarciami',
      icon: '🔌',
      category: 'Ochrona',
      fullDescription:
          'Wyłącznik automatyczny stanowi zabezpieczenie główne instalacji. Rozłącza obwód automatycznie przy prądzie zwarciowym lub przeterminowaniu.',
      parameters: {
        'In': 'Prąd nominalny (6A, 10A, 16A, 20A, 25A...)',
        'Ik': 'Prąd короткое zamknięcia',
        'Klasa': 'A, B, C, D - charakterystyka wyłączenia',
      },
    ),
    ElectricalSymbol(
      id: 'rcd',
      name: 'Wyłącznik różnicowoprądowy',
      description: 'Ochrona przed porażeniem prądem',
      icon: '🛡️',
      category: 'Ochrona',
      fullDescription:
          'RCD (Residual Current Device) - wyłącznik różnicowoprądowy stanowi zabezpieczenie przed porażeniem prądem elektrycznym. Rozłącza obwód przy niewielkim niesymetycznym prądzie.',
      parameters: {
        'In': 'Prąd znamionowy RCD (30mA, 100mA, 300mA, 500mA)',
        'Typ': 'AC, A, F, B, B+ - odowiedź na rodzaj prądu',
        'Tn': 'Czas działania (≤300ms dla 30mA)',
      },
    ),
  ];

  static final List<ElectricalSymbol> sourceSymbols = [
    ElectricalSymbol(
      id: 'battery',
      name: 'Bateria/Akumulator',
      description: 'Źródło energii prądu stałego',
      icon: '🔋',
      category: 'Źródła',
      fullDescription:
          'Bateria lub akumulator stanowi źródło energii elektrycznej. Symbol pokazuje stykę dłużej (dodatnie) i krótsze (ujemne).',
      parameters: {
        'U': 'Napięcie znamionowe (1.5V, 12V, 48V...)',
        'E': 'Siła elektromotoryczna',
        'r': 'Opór wewnętrzny',
      },
    ),
    ElectricalSymbol(
      id: 'ac_source',
      name: 'Źródło prądu zmiennego',
      description: 'Zasilanie sieć AC',
      icon: '⊙',
      category: 'Źródła',
      fullDescription: 'Symbol reprezentuje źródło napięcia zmiennego sinusoidalnego.',
      parameters: {
        'U': 'Napięcie skuteczne (230V, 400V...)',
        'f': 'Częstotliwość (50Hz, 60Hz)',
        'P': 'Moc pozorna',
      },
    ),
    ElectricalSymbol(
      id: 'generator',
      name: 'Generator',
      description: 'Urządzenie wytwarzające energię',
      icon: '⚙️',
      category: 'Źródła',
      fullDescription:
          'Generator konwertuje energię mechaniczną na elektryczną. Jego Symbol może być AC lub DC w zależności od typu.',
      parameters: {
        'Pn': 'Moc znamionowa',
        'U': 'Napięcie znamionowe',
        'I': 'Prąd nominalny',
      },
    ),
  ];

  static final List<ElectricalSymbol> componentSymbols = [
    ElectricalSymbol(
      id: 'resistor',
      name: 'Rezystor',
      description: 'Element ograniczający prąd',
      icon: '▭',
      category: 'Komponenty',
      fullDescription:
          'Rezystor to dwójnik pasywny powodujący opór przepływowi prądu. Jego oporność mierzy się w omach (Ω).',
      parameters: {
        'R': 'Opór (Ω)',
        'P': 'Moc znamionowa (W)',
        'Tol': 'Tolerancja (%)',
      },
    ),
    ElectricalSymbol(
      id: 'capactor',
      name: 'Kondensator',
      description: 'Element magazynujący energię',
      icon: '||',
      category: 'Komponenty',
      fullDescription:
          'Kondensator to element pasywny zdolny do magazynowania energii elektrycznej w polu elektrostatycznym.',
      parameters: {
        'C': 'Pojemność (F, µF, nF, pF)',
        'U': 'Napięcie znamionowe',
        'ESR': 'Opór równoważny szeregowy',
      },
    ),
    ElectricalSymbol(
      id: 'inductor',
      name: 'Cewka indukcyjna',
      description: 'Element z właściwością indukcji',
      icon: '⌘',
      category: 'Komponenty',
      fullDescription:
          'Cewka to element pasywny wytwarzający pole magnetyczne przy przepływie prądu. Jej indukcyjność mierzy się w henrach (H).',
      parameters: {
        'L': 'Indukcyjność (H, mH, µH)',
        'R': 'Opór drutu',
        'Q': 'Dobroć cewki',
      },
    ),
  ];

  static final List<ElectricalSymbol> measurementSymbols = [
    ElectricalSymbol(
      id: 'voltmeter',
      name: 'Woltomierz',
      description: 'Pomiar napięcia',
      icon: '▭V',
      category: 'Pomiary',
      fullDescription: 'Woltomierz to przyrząd do pomiaru napięcia elektrycznego.',
      parameters: {
        'U': 'Zakres pomiarowy (V)',
        'Ri': 'Opór wewnętrzny (bardzo wysoki)',
        'Kl': 'Klasa dokładności',
      },
    ),
    ElectricalSymbol(
      id: 'ammeter',
      name: 'Amperomierz',
      description: 'Pomiar prądu',
      icon: '▭A',
      category: 'Pomiary',
      fullDescription: 'Amperomierz to przyrząd do pomiaru prądu elektrycznego.',
      parameters: {
        'I': 'Zakres pomiarowy (A)',
        'Ri': 'Opór wewnętrzny (bardzo niski)',
        'Kl': 'Klasa dokładności',
      },
    ),
    ElectricalSymbol(
      id: 'ohmmeter',
      name: 'Omometr',
      description: 'Pomiar rezystancji',
      icon: '▭Ω',
      category: 'Pomiary',
      fullDescription: 'Omometr to przyrząd do pomiaru rezystancji elektrycznej.',
      parameters: {
        'R': 'Zakres pomiarowy (Ω)',
        'U': 'Napięcie pomiarowe',
        'Kl': 'Klasa dokładności',
      },
    ),
  ];

  static final List<SymbolCategory> categories = [
    SymbolCategory(
      name: 'Ochrona',
      icon: '🛡️',
      symbols: protectionSymbols,
    ),
    SymbolCategory(
      name: 'Źródła',
      icon: '⚡',
      symbols: sourceSymbols,
    ),
    SymbolCategory(
      name: 'Komponenty',
      icon: '🔌',
      symbols: componentSymbols,
    ),
    SymbolCategory(
      name: 'Pomiary',
      icon: '📊',
      symbols: measurementSymbols,
    ),
  ];

  static List<ElectricalSymbol> getAllSymbols() {
    return [
      ...protectionSymbols,
      ...sourceSymbols,
      ...componentSymbols,
      ...measurementSymbols,
    ];
  }

  static ElectricalSymbol? getSymbolById(String id) {
    try {
      return getAllSymbols().firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<ElectricalSymbol> getSymbolsByCategory(String category) {
    return getAllSymbols()
        .where((s) => s.category == category)
        .toList();
  }
}
