enum RcdType {
  ac('AC', 'Prąd zmienny sinusoidalny', 'Standardowy RCD dla obwodów domowych'),
  a('A', 'Prąd zmienny + składowa stała', 'Do falowników, urządzeń elektronicznych'),
  f('F', 'Prąd zmienny + wyższa częstotliwość', 'Do zaawansowanych falowników, ładowarek'),
  b('B', 'Prąd stały + zmienny', 'Do fotowoltaiki, systemów EPV'),
  bPlus('B+', 'Rozszerzona ochrona B', 'Nowoczesne stacje EV i fotowoltaika');

  final String code;
  final String description;
  final String details;

  const RcdType(this.code, this.description, this.details);
}

class RcdQuestion {
  final String id;
  final String question;
  final String description;

  RcdQuestion({
    required this.id,
    required this.question,
    required this.description,
  });
}

class RcdSelectionResult {
  final RcdType recommendedType;
  final List<RcdType> alternativeTypes;
  final String reasoning;
  final String details;

  RcdSelectionResult({
    required this.recommendedType,
    required this.alternativeTypes,
    required this.reasoning,
    required this.details,
  });
}
