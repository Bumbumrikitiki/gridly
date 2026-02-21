enum RcdType {
  ac(
    'AC',
    'Prądy sinusoidalne AC',
    'Stosowanie ograniczone; w nowych instalacjach zwykle preferowany min. typ A.',
  ),
  a(
    'A',
    'Prądy AC + pulsujące DC',
    'Najczęściej stosowany punkt wyjścia dla obwodów końcowych z odbiornikami elektronicznymi.',
  ),
  aSi(
    'A-SI',
    'Typ A o podwyższonej odporności na zakłócenia',
    'Zmniejsza ryzyko niepożądanych zadziałań (EMI, udary, filtry).',
  ),
  f(
    'F',
    'Typ A + składowe o częstotliwościach mieszanych',
    'Dobór rozważany m.in. dla napędów jednofazowych i przekształtników.',
  ),
  b(
    'B',
    'Prądy AC, pulsujące DC i gładkie DC',
    'Rozważany tam, gdzie może wystąpić składowa gładka DC (np. część układów EV/PV).',
  ),
  bPlus(
    'B+',
    'Rozszerzony typ B (szerszy zakres detekcji)',
    'Wariant specjalistyczny dla instalacji o podwyższonych wymaganiach funkcjonalnych.',
  ),
  aSelective(
    'A-S',
    'Typ A selektywny (zwłoczny)',
    'Stosowany przy wymaganej selektywności stopni ochrony.',
  ),
  bSelective(
    'B-S',
    'Typ B selektywny (zwłoczny)',
    'Wariant dla układów z DC oraz wymaganą selektywnością.',
  );

  final String code;
  final String description;
  final String details;

  const RcdType(this.code, this.description, this.details);
}

class RcdQuestion {
  final String id;
  final String question;
  final String description;
  final String impact;

  RcdQuestion({
    required this.id,
    required this.question,
    required this.description,
    required this.impact,
  });
}

class RcdSelectionResult {
  final RcdType recommendedType;
  final List<RcdType> alternativeTypes;
  final String reasoning;
  final String details;
  final List<String> verificationChecklist;
  final String standardsNote;

  RcdSelectionResult({
    required this.recommendedType,
    required this.alternativeTypes,
    required this.reasoning,
    required this.details,
    required this.verificationChecklist,
    required this.standardsNote,
  });
}
