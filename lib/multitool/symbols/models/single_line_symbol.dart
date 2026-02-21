enum SingleLineGraphicType {
  breaker,
  rcd,
  rcbo,
  isolator,
  fuse,
  contactor,
  thermal,
  motor,
  source,
  transformer,
  board,
  terminal,
  phase,
  neutral,
  pe,
  pen,
  grounding,
  meter,
  cable,
  busbar,
  lineReserved,
  noContact,
  ncContact,
  pushButton,
  lamp,
  automation,
  generic,
}

class SingleLineSymbol {
  const SingleLineSymbol({
    required this.code,
    required this.name,
    required this.description,
    required this.useCase,
    required this.category,
    required this.graphicType,
    this.standardRef,
    this.keywords = const <String>[],
  });

  final String code;
  final String name;
  final String description;
  final String useCase;
  final String category;
  final SingleLineGraphicType graphicType;
  final String? standardRef;
  final List<String> keywords;
}
