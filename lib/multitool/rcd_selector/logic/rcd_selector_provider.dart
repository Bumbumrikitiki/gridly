import 'package:flutter/foundation.dart';
import 'package:gridly/multitool/rcd_selector/models/rcd_models.dart';

class RcdSelectorProvider extends ChangeNotifier {
  final List<RcdQuestion> questions = [
    RcdQuestion(
      id: 'harmonics',
      question:
          'Czy w instalacji mogą występować prądy odkształcone (harmoniczne)?',
      description:
      'Urządzenia energoelektroniczne, zasilacze impulsowe, filtry EMI, UPS.',
    impact:
      'Wpływa na odporność RCD na składowe nienazwane i częstotliwości wyższe.',
    ),
    RcdQuestion(
      id: 'inverters',
      question:
          'Czy instalacja zawiera falowniki lub urządzenia energoelektroniczne?',
      description:
      'Napędy, pompy ciepła, klimatyzacja, przekształtniki AC/DC.',
    impact:
      'Może wymagać typu F/B zależnie od charakteru prądów upływu.',
    ),
    RcdQuestion(
      id: 'ev_charging',
      question:
          'Czy instalacja zawiera stacje ładowania pojazdów elektrycznych (EV)?',
    description: 'Wallboxy AC lub punkty ładowania EV o znanych/nieznanych funkcjach RDC-DD.',
    impact:
      'Przy możliwej składowej gładkiej DC często rozważa się typ B lub rozwiązania równoważne.',
  ),
  RcdQuestion(
    id: 'pv_storage',
    question: 'Czy obwód dotyczy PV, magazynu energii lub hybrydowego układu zasilania?',
    description:
      'Falowniki PV, bateryjne, systemy hybrydowe i tory AC sprzężone z konwersją energii.',
    impact:
      'Może wymuszać wyższy typ RCD oraz dodatkową weryfikację DTR producenta.',
  ),
  RcdQuestion(
    id: 'nuisance_tripping',
    question:
      'Czy wymagane jest ograniczenie zadziałań niepożądanych (wysokie EMI/dużo filtrów)?',
    description:
      'Serwerownie, biura z dużą liczbą zasilaczy, obiekty automatyki.',
    impact:
      'Wskazuje na warianty o większej odporności (np. A-SI).',
  ),
  RcdQuestion(
    id: 'selectivity',
    question: 'Czy wymagana jest selektywność (kaskadowanie zabezpieczeń RCD)?',
    description:
      'Rozdzielnice wielostopniowe, zasilanie podrzędnych tablic, wymagania ciągłości zasilania.',
    impact:
      'Wskazuje na rozważenie wariantów selektywnych (S).',
    ),
  ];

  final Map<String, bool> _answers = {};
  RcdSelectionResult? _result;

  Map<String, bool> get answers => _answers;
  RcdSelectionResult? get result => _result;
  bool get allAnswered => _answers.length == questions.length;
  int get unansweredCount => questions.length - _answers.length;

  void setAnswer(String questionId, bool answer) {
    _answers[questionId] = answer;
    _result = null; // Resetuj wynik
    notifyListeners();
  }

  void resetAnswers() {
    _answers.clear();
    _result = null;
    notifyListeners();
  }

  void fillMissingAnswersWithDefault({bool defaultValue = false}) {
    for (final question in questions) {
      _answers.putIfAbsent(question.id, () => defaultValue);
    }
    _result = null;
    notifyListeners();
  }

  RcdSelectionResult calculateRecommendation() {
    final hasHarmonics = _answers['harmonics'] ?? false;
    final hasInverters = _answers['inverters'] ?? false;
    final hasEvCharging = _answers['ev_charging'] ?? false;
    final hasPvStorage = _answers['pv_storage'] ?? false;
    final needsNuisanceResistance = _answers['nuisance_tripping'] ?? false;
    final needsSelectivity = _answers['selectivity'] ?? false;

    final score = <RcdType, int>{
      for (final type in RcdType.values) type: 0,
    };

    final reasons = <String>[];
    final checklist = <String>[
      'Zweryfikuj wymagania producenta urządzeń (DTR) i warunki przyłączenia.',
      'Potwierdź wartość i charakter prądu upływu dla obwodu.',
      'Dobierz IΔn zgodnie z funkcją ochrony (np. dodatkowa/pożarowa/selektywność).',
      'Sprawdź koordynację z zabezpieczeniem nadprądowym i zdolność łączeniową.',
      'Potwierdź warunki środowiskowe i kompatybilność EMC.',
    ];

    if (hasEvCharging) {
      score[RcdType.b] = score[RcdType.b]! + 5;
      score[RcdType.bPlus] = score[RcdType.bPlus]! + 4;
      score[RcdType.a] = score[RcdType.a]! + 2;
      reasons.add(
        'Obecność ładowania EV wskazuje na konieczność oceny składowej gładkiej DC i funkcji RDC-DD.',
      );
      checklist.add(
        'Dla EV potwierdź, czy EVSE ma wbudowaną detekcję 6 mA DC oraz jakie są wymagania producenta.',
      );
    }

    if (hasPvStorage) {
      score[RcdType.b] = score[RcdType.b]! + 5;
      score[RcdType.bPlus] = score[RcdType.bPlus]! + 3;
      score[RcdType.f] = score[RcdType.f]! + 1;
      reasons.add(
        'Układy PV/magazynowania energii mogą generować składowe wymagające wyższego typu RCD.',
      );
      checklist.add(
        'Zweryfikuj wymagania producenta falownika PV/magazynu dot. typu RCD i konfiguracji sieci.',
      );
    }

    if (hasInverters) {
      score[RcdType.f] = score[RcdType.f]! + 4;
      score[RcdType.a] = score[RcdType.a]! + 3;
      score[RcdType.b] = score[RcdType.b]! + 1;
      reasons.add(
        'Falowniki i przekształtniki zwiększają zasadność rozważenia typu F/A, a w części przypadków B.',
      );
    }

    if (hasHarmonics) {
      score[RcdType.f] = score[RcdType.f]! + 3;
      score[RcdType.aSi] = score[RcdType.aSi]! + 2;
      score[RcdType.a] = score[RcdType.a]! + 1;
      reasons.add(
        'Prądy odkształcone i wyższe harmoniczne przemawiają za typami o lepszej odporności dynamicznej.',
      );
    }

    if (needsNuisanceResistance) {
      score[RcdType.aSi] = score[RcdType.aSi]! + 5;
      score[RcdType.f] = score[RcdType.f]! + 1;
      reasons.add(
        'Wymagana odporność na zadziałania niepożądane wskazuje na rozważenie wariantów SI.',
      );
    }

    if (needsSelectivity) {
      score[RcdType.aSelective] = score[RcdType.aSelective]! + 4;
      score[RcdType.bSelective] = score[RcdType.bSelective]! + 4;
      score[RcdType.a] = score[RcdType.a]! + 1;
      score[RcdType.b] = score[RcdType.b]! + 1;
      reasons.add(
        'Wymagana selektywność sugeruje dobór wariantów zwłocznych (S) na właściwym poziomie rozdziału.',
      );
      checklist.add(
        'Zweryfikuj czasy zadziałania i stopniowanie RCD między poziomami rozdzielni.',
      );
    }

    final hasAdvancedLoads =
        hasEvCharging ||
        hasPvStorage ||
        hasInverters ||
        hasHarmonics ||
        needsNuisanceResistance;

    if (!hasAdvancedLoads) {
      score[RcdType.a] = score[RcdType.a]! + 4;
      score[RcdType.ac] = score[RcdType.ac]! + 1;
      reasons.add(
        'Dla obwodów ogólnych bez złożonych odbiorników bezpieczniejszym punktem wyjścia jest zwykle typ A.',
      );
    }

    if (hasAdvancedLoads) {
      score[RcdType.ac] = -100;
    }

    final rankedTypes = score.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var recommended = rankedTypes.first.key;

    if (needsSelectivity && recommended == RcdType.a) {
      recommended = RcdType.aSelective;
    }
    if (needsSelectivity && recommended == RcdType.b) {
      recommended = RcdType.bSelective;
    }

    final alternatives = rankedTypes
        .map((entry) => entry.key)
        .where((type) => type != recommended)
        .take(3)
        .toList();

    final reasoning = reasons.isEmpty
        ? 'Brak czynników szczególnych — przyjęto konserwatywne zalecenie bazowe.'
        : reasons.join(' ');

    final details =
      'Rekomendacja ma charakter inżynierskiego wsparcia decyzji i nie stanowi projektu, opinii technicznej ani porady prawnej. Ostateczny dobór należy potwierdzić w dokumentacji projektowej na podstawie norm, DTR producentów i warunków eksploatacji.';

    final standardsNote =
      'Weryfikuj zgodność m.in. z wymaganiami serii PN-HD 60364, dokumentacją producentów, warunkami przyłączenia oraz wymaganiami inwestora i rzeczoznawcy ppoż. (jeśli dotyczy).';

    _result = RcdSelectionResult(
      recommendedType: recommended,
      alternativeTypes: alternatives,
      reasoning: reasoning,
      details: details,
      verificationChecklist: checklist,
      standardsNote: standardsNote,
    );

    notifyListeners();

    return _result!;
  }

  int get questionProgress => _answers.length;
}
