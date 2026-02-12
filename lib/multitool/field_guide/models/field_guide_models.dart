import 'package:flutter/material.dart';

/// Scenariusz inspekcji
enum InspectionScenario {
  building('Odbiór budynku', '🏢'),
  flooding('Po zalaniu', '💧'),
  modernization('Modernizacja', '🔧'),
  maintenance('Konserwacja', '🔍');

  const InspectionScenario(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Typ pomiaru
class MeasurementType {
  final String id;
  final String name;
  final String description;
  final String unit;
  final String? minValue;
  final String? maxValue;
  final IconData icon;

  MeasurementType({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    this.minValue,
    this.maxValue,
    required this.icon,
  });
}

/// Wynik pomiaru
class MeasurementResult {
  final MeasurementType type;
  final String value;
  final bool passed;
  final DateTime timestamp;
  final String? notes;

  MeasurementResult({
    required this.type,
    required this.value,
    required this.passed,
    DateTime? timestamp,
    this.notes,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Lista pomiarów dla scenariusza
class MeasurementChecklist {
  final InspectionScenario scenario;
  final List<MeasurementType> measurements;

  const MeasurementChecklist({
    required this.scenario,
    required this.measurements,
  });
}

/// Elementy wymagające uziemienia
class GroundingElement {
  final String id;
  final String name;
  final String description;
  final bool isRequired;
  final String? icon;

  GroundingElement({
    required this.id,
    required this.name,
    required this.description,
    this.isRequired = true,
    this.icon,
  });
}

/// Wyjątki od uziemienia
class GroundingException {
  final String id;
  final String name;
  final String description;
  final String reason;

  GroundingException({
    required this.id,
    required this.name,
    required this.description,
    required this.reason,
  });
}

/// Dane o minimalnych przekrojach
class CabelSizeRequirement {
  final String type;
  final String material;
  final String protection;
  final Map<double, String> crossSections; // [length] -> [min cross-section mm²]

  CabelSizeRequirement({
    required this.type,
    required this.material,
    required this.protection,
    required this.crossSections,
  });
}
