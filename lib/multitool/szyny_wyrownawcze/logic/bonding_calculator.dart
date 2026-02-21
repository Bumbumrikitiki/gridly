import 'package:flutter/foundation.dart';
import 'package:gridly/multitool/szyny_wyrownawcze/models/bonding_elements_models.dart';

/// Provider logiki dla kalkulatora szyn wyrównawczych
/// Zarządza stanem, kalkulacjami i rekomendacjami
class BondingCalculatorProvider extends ChangeNotifier {
  static const String disclaimer =
      '''⚠️ OGRANICZENIE ODPOWIEDZIALNOŚCI CYWILNO-PRAWNEJ:
• Wartości w tym narzędziu są ORIENTACYJNE i oparte na normach PN-IEC 60364-5-54, PN-EN 50164
• Wartości stanowią WSPARCIE dla projektanta/inspektora, nie zastępko obliczeń szczegółowych
• OBOWIĄZKOWA weryfikacja przez uprawnionych projektantów i inspektorów ds. bezpieczeństwa
• Użytkownik aplikacji ponosi PEŁNĄ odpowiedzialność za prawidłowość wyboru parametrów
• Producent aplikacji nie ponosi odpowiedzialności''';

  // Stan bieżący
  BondingElementType? _selectedElement;
  PradNominalny? _selectedPrad;
  String _opisBudowy = '';
  bool _wymagaSpawania = false;

  // Результаты калькулятора
  RekomendacjaKabla? _ostatniaRekomendacja;
  String _ostrzezenie = '';

  // Gettery
  BondingElementType? get selectedElement => _selectedElement;
  PradNominalny? get selectedPrad => _selectedPrad;
  String get opisBudowy => _opisBudowy;
  bool get wymagaSpawania => _wymagaSpawania;
  RekomendacjaKabla? get ostatniaRekomendacja => _ostatniaRekomendacja;
  String get ostrzezenie => _ostrzezenie;

  // Settery
  void ustawElement(BondingElementType element) {
    _selectedElement = element;
    _ostrzezenie = '';
    notifyListeners();
  }

  void ustawPrad(PradNominalny prad) {
    _selectedPrad = prad;
    notifyListeners();
  }

  void ustawOpisBudowy(String opis) {
    _opisBudowy = opis;
    notifyListeners();
  }

  void ustawSpawanie(bool wymaga) {
    _wymagaSpawania = wymaga;
    notifyListeners();
  }

  /// Oblicz rekomendację na podstawie wybranych parametrów
  void obliczRekomendacje() {
    if (_selectedElement == null || _selectedPrad == null) {
      _ostatniaRekomendacja = null;
      _ostrzezenie = 'Wybierz element i prąd nominalny';
      notifyListeners();
      return;
    }

    // Pobierz rekomendację z bazy
    _ostatniaRekomendacja = BazaRekomendacji.dajRekomendacje(
      _selectedElement!,
      _selectedPrad!,
    );

    // Ustaw ostrzeżenia specjalne
    _ustawOstrzezenia();

    notifyListeners();
  }

  /// Ustaw ostrzeżenia specjalne na podstawie wybranego elementu
  void _ustawOstrzezenia() {
    _ostrzezenie = '';

    switch (_selectedElement) {
      case BondingElementType.ruGas:
        _ostrzezenie =
            '⚠️ RURA GAZOWA: Wymagane bezwzględnie certyfikowane złącze wg PN-EN 50164!\n'
            'Wykonać przez specjalistę. Inwentaryzacja obowiązkowa.';
        break;

      case BondingElementType.rusztowanie:
        _ostrzezenie =
            '⚠️ RUSZTOWANIE: Min. 2 niezależne połączenia (spawane).\n'
            'Każde połączenie musi wytrzymać min. 200 A²s².\n'
            'Odbiór i sprawdzenie po ustawieniu rusztowania.';
        break;

      case BondingElementType.ruWoda:
        _ostrzezenie =
            '⚠️ RURA WODNA: Oczyścić warstwę ochronną (rdzawienie)!\n'
            'Certyfikowane złącze. Oddalenie od filtrów min. 0,5 m.';
        break;

      case BondingElementType.barak:
        _ostrzezenie =
            '⚠️ BARAK: Min. 2 niezależne punkty podłączenia.\n'
            'Sprawdzać regularnie stan połączeń (korozja, luźne śruby).';
        break;

      case BondingElementType.kontener:
        _ostrzezenie =
            '⚠️ KONTENER: Sprawdzić połączenie co 2-3 tygodnie.\n'
            'Korozja metalowa - konieczna inspekcja.';
        break;

      case BondingElementType.przedzielnica:
        _ostrzezenie =
            '⚠️ ROZDZIELNICA: Połączenie do specjalnej szyny PE/PEN.\n'
            'Dokręcić śrubę/bolec z siłą 25-30 Nm (dla M12).';
        break;

      default:
        _ostrzezenie = 'Patrz normy PN-IEC 60364-4-41 dla szczegółów.';
    }
  }

  /// Pobierz wszystkie dostępne elementy
  List<BondingElementType> getDostepneElementy() {
    return BondingElementType.values;
  }

  /// Pobierz wszystkie dostępne prądy
  List<PradNominalny> getDostepnePrady() {
    return PradNominalny.values;
  }

  /// Pobierz opis elementu dla UI
  String getOpisElementu(BondingElementType element) {
    switch (element) {
      case BondingElementType.przedzielnica:
        return 'Rozdzielnica główna (RB)';
      case BondingElementType.ruPH:
        return 'Rura przewodu handlowego';
      case BondingElementType.ruWoda:
        return 'Rura wodna (stalowa)';
      case BondingElementType.ruKanalizacja:
        return 'Rura kanalizacyjna';
      case BondingElementType.ruGas:
        return 'Rura gazowa (NIEBEZPIECZNA!)';
      case BondingElementType.ruInstalacyjna:
        return 'Rura instalacyjna';
      case BondingElementType.rusztowanie:
        return 'Rusztowanie metalowe';
      case BondingElementType.barak:
        return 'Barak (liczba drzwi)';
      case BondingElementType.kontener:
        return 'Kontener budowlany';
      case BondingElementType.maszyna:
        return 'Maszyna budowlana';
      case BondingElementType.przykladownikStacji:
        return 'Przyławnik stacji trafo';
      case BondingElementType.studzienkaElektryczna:
        return 'Studzienka elektroenergetyczna';
      case BondingElementType.latarnia:
        return 'Słup oświetleniowy';
      case BondingElementType.maszt:
        return 'Maszt (antenowy, sygnalizacyjny)';
    }
  }

  /// Pobierz opis prądu
  String getOpisPradu(PradNominalny prad) {
    switch (prad) {
      case PradNominalny.i16A:
        return '16 A (małe obiekty)';
      case PradNominalny.i20A:
        return '20 A (oświetlenie)';
      case PradNominalny.i25A:
        return '25 A (mały sprzęt)';
      case PradNominalny.i32A:
        return '32 A (średnie obiekty)';
      case PradNominalny.i63A:
        return '63 A (maszyny, żurawie)';
      case PradNominalny.i125A:
        return '125 A (rozdzielnica główna)';
      case PradNominalny.i160A:
        return '160 A (trafo)';
      case PradNominalny.i200A:
        return '200 A (zasilanie główne)';
    }
  }

  /// Eksport rekomendacji do formatu tekstowego
  String eksportRekomendacji() {
    if (_ostatniaRekomendacja == null) {
      return 'Brak rekomendacji do eksportu.';
    }

    final rek = _ostatniaRekomendacja!;
    return '''
══════════════════════════════════════════════════════
REKOMENDACJA DOBORU KABLA - SZYNY WYRÓWNAWCZE
══════════════════════════════════════════════════════

ELEMENT: ${rek.nazwaElementu}
PRĄD NOMINALNY: ${getOpisPradu(_selectedPrad!)}

REKOMENDOWANY PRZEKRÓJ: ${rek.przekrojMM}
NORMA: ${rek.norma}
SPOSÓB POŁĄCZENIA: ${rek.rekomendowanySposob.toString().split('.').last}

UZASADNIENIE:
${rek.dlaczego}

UWAGI:
${rek.uwagi}

${_ostrzezenie.isNotEmpty ? 'OSTRZEŻENIA:\n$_ostrzezenie\n' : ''}

DISCLAIMER:
${_ostatniaRekomendacja!.disclaimer}

Wymaga weryfikacji przez projektanta/inspektora elektryk!
══════════════════════════════════════════════════════
Data: ${DateTime.now().toString()}
''';
  }

  /// Resetuj kalkulator
  void reset() {
    _selectedElement = null;
    _selectedPrad = null;
    _opisBudowy = '';
    _wymagaSpawania = false;
    _ostatniaRekomendacja = null;
    _ostrzezenie = '';
    notifyListeners();
  }

  /// Pobierz szczegółowe informacje o elemencie
  ElementUziemienia? getElementInfo(BondingElementType element) {
    for (final el in BazaRekomendacji.standardoweElementy) {
      if (el.typ == element) {
        return el;
      }
    }
    return null;
  }

  /// Pobierz tabelę przekrojów w zależności od prądu
  Map<String, String> getTabelaPrzekrojow() {
    return {
      '16 A': 'min. 1.5 mm² Cu',
      '20 A': 'min. 2.5 mm² Cu',
      '25 A': 'min. 4 mm² Cu',
      '32 A': 'min. 6 mm² Cu',
      '50 A': 'min. 10 mm² Cu',
      '63 A': 'min. 16 mm² Cu',
      '100 A': 'min. 25 mm² Cu',
      '125 A': 'min. 35 mm² Cu',
      '160 A': 'min. 50 mm² Cu',
      '200 A': 'min. 70 mm² Cu',
    };
  }

  /// Pobierz normatywne wymogi dla głównej szyny wyrównawczej
  Map<String, String> getWymagaSzynyWyrownawczej() {
    return {
      'Materiał': 'Mosiądz (TM02/CW617N) lub miedź',
      'Minimalny rozmiar': '10 x 10 mm = 100 mm²',
      'Rezystancja': '≤ 0.0175 Ω·mm²/m (dla miedzi)',
      'Prąd dozwolony': 'Bez ograniczeń dla ≥100 mm²',
      'Połączenia': 'Śrubowe M10+ lub spawanie, min. 200 A²s²',
      'Norma': 'PN-IEC 60364-5-54, PN-EN 50164',
    };
  }

  /// Pobierz wymogi dla podziału PEN
  Map<String, String> getWymagaPodzialuPEN() {
    return {
      'Miejsce podziału': 'Główna rozdzielnica budowy (na wejściu)',
      'Przekrój PE': '≥ 16 mm² Cu dla I≤63A, ≥25 mm² dla I>63A',
      'Przekrój N': 'Odpowiada przekrojowi fazowemu, min. 16 mm² Cu',
      'Połączenia': 'Oddzielne dla PE i N - BEZPOŚREDNIE z szyny',
      'Odłącznik PEN': 'Zabrania się podziału PEN przed głównym wyłącznikiem',
      'Norma': 'PN-IEC 60364-4-41',
    };
  }
}
