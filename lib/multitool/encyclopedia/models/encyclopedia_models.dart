class ElectricalSymbol {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji lub Unicode
  final String? fullDescription;
  final Map<String, String>? parameters;
  final String? category;

  ElectricalSymbol({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.fullDescription,
    this.parameters,
    this.category,
  });
}

class SymbolCategory {
  final String name;
  final String icon;
  final List<ElectricalSymbol> symbols;

  SymbolCategory({
    required this.name,
    required this.icon,
    required this.symbols,
  });
}
