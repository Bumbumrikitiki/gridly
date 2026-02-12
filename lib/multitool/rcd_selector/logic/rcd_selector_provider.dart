import 'package:flutter/foundation.dart';
import 'package:gridly/multitool/rcd_selector/models/rcd_models.dart';

class RcdSelectorProvider extends ChangeNotifier {
  final List<RcdQuestion> questions = [
    RcdQuestion(
      id: 'harmonics',
      question:
          'Czy w instalacji mogą występować prądy odkształcone (harmoniczne)?',
      description:
          'Urządzenia elektroniczne, wpływy EMI, źródła zasilania awaryjne',
    ),
    RcdQuestion(
      id: 'inverters',
      question:
          'Czy instalacja zawiera falowniki lub urządzenia energoelektroniczne?',
      description:
          'Panele PV, falowniki sieciowe, ładowarki, systemy magazynowania energii',
    ),
    RcdQuestion(
      id: 'ev_charging',
      question:
          'Czy instalacja zawiera stacje ładowania pojazdów elektrycznych (EV)?',
      description: 'Publiczne lub prywatne stacje szybkiego/wolnego ładowania',
    ),
  ];

  final Map<String, bool> _answers = {};
  RcdSelectionResult? _result;

  Map<String, bool> get answers => _answers;
  RcdSelectionResult? get result => _result;
  bool get allAnswered => _answers.length == questions.length;

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

  RcdSelectionResult calculateRecommendation() {
    final hasHarmonics = _answers['harmonics'] ?? false;
    final hasInverters = _answers['inverters'] ?? false;
    final hasEvCharging = _answers['ev_charging'] ?? false;

    late RcdType recommended;
    late List<RcdType> alternatives;
    late String reasoning;
    late String details;

    // Logika dobrania typu RCD
    if (hasEvCharging) {
      // Stacje EV wymagają najwyższej klasy ochrony
      recommended = RcdType.bPlus;
      alternatives = [RcdType.b, RcdType.f];
      reasoning =
          'Obecność stacji ładowania pojazdów elektrycznych może wskazywać na potrzebę rozważenia typu B+ ze względu na charakterystyki prądów.';
      details =
          'Typ B+ obejmuje składowe stałe i zmienne; wynik ma charakter orientacyjny i wymaga weryfikacji projektowej.';
    } else if (hasInverters) {
      // Falowniki i systemy energoelektroniczne
      if (hasHarmonics) {
        recommended = RcdType.f;
        alternatives = [RcdType.a, RcdType.b];
        reasoning =
            'Falowniki z harmonicznymi mogą wskazywać na zasadność rozważenia RCD typu F, odporniejszego na wyższe częstotliwości.';
        details =
            'Typ F bywa stosowany przy zaawansowanych systemach konwersji energii; rezultat jest informacyjny.';
      } else {
        recommended = RcdType.a;
        alternatives = [RcdType.f, RcdType.ac];
        reasoning =
            'Falowniki bez znaczących harmonicznych mogą wskazywać na użycie typu A, obsługującego składową stałą.';
        details =
            'Typ A jest często używany przy nowoczesnych urządzeniach elektronicznych; wynik ma charakter orientacyjny.';
      }
    } else if (hasHarmonics) {
      // Tylko harmoniczne, bez falowników/EV
      recommended = RcdType.a;
      alternatives = [RcdType.f, RcdType.ac];
      reasoning =
          'Prądy odkształcone mogą wskazywać na rozważenie RCD typu A, lepiej obsługującego składowe nienusoidalne.';
      details =
          'Typ A jest często rozpatrywany w instalacjach z sygnałami odkształconymi; wynik jest informacyjny.';
    } else {
      // Standardowa instalacja
      recommended = RcdType.ac;
      alternatives = [RcdType.a];
      reasoning =
          'Instalacja standardowa (bez harmonicznych, falowników i stacji EV) może wskazywać na rozważenie typu AC.';
      details =
          'Typ AC jest często spotykany w prostszych instalacjach; wynik ma charakter orientacyjny.';
    }

    _result = RcdSelectionResult(
      recommendedType: recommended,
      alternativeTypes: alternatives,
      reasoning: reasoning,
      details: details,
    );

    return _result!;
  }

  int get questionProgress => _answers.length;
}
