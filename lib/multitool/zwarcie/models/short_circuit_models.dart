enum CableMaterial {
  copper(
    'Cu',
    'Miedź',
    0.01785,
    0.0225,
  ),
  aluminum(
    'Al',
    'Aluminium',
    0.02826,
    0.0365,
  );

  final String code;
  final String name;
  final double resistivityAt20C; // [Ω·mm²/m]
  final double resistivityAt70C;

  const CableMaterial(
    this.code,
    this.name,
    this.resistivityAt20C,
    this.resistivityAt70C,
  );

  double getResistivity(bool isWarm) =>
      isWarm ? resistivityAt70C : resistivityAt20C;
}

class ProtectionDevice {
  final String name;
  final double ratedCurrent; // [A]
  final bool isMcb; // true = wyłącznik, false = bezpiecznik
  final double breakingCapacity; // [kA]

  const ProtectionDevice({
    required this.name,
    required this.ratedCurrent,
    required this.isMcb,
    required this.breakingCapacity,
  });

  bool canWithstand(double iscKa) => iscKa <= breakingCapacity;
}

class ShortCircuitInput {
  final double iscNetwork; // Initial short circuit at source [kA]
  final double cableLength; // [m]
  final double cableCrossSection; // [mm²]
  final CableMaterial cableMaterial;
  final bool isWarmCable; // true = 70°C (operational), false = 20°C
  final double nominalVoltage; // [V] - usually 230 or 400V

  const ShortCircuitInput({
    required this.iscNetwork,
    required this.cableLength,
    required this.cableCrossSection,
    required this.cableMaterial,
    required this.isWarmCable,
    required this.nominalVoltage,
  });
}

class ShortCircuitResult {
  final double iscatPoint; // Calculated Isc at measurement point [kA]
  final double cableResistance; // [Ω]
  final double cableReactance; // Estimated as 0.08 Ω/m per phase
  final double impedance; // [Ω]

  // Device checks
  final List<DeviceCheck> deviceChecks;
  final List<String> warnings;
  final bool isHazardous;

  const ShortCircuitResult({
    required this.iscatPoint,
    required this.cableResistance,
    required this.cableReactance,
    required this.impedance,
    required this.deviceChecks,
    required this.warnings,
    required this.isHazardous,
  });
}

class DeviceCheck {
  final String deviceName;
  final double ratedCurrent;
  final double breakingCapacity;
  final bool canWithstand;
  final String status; // "✅ Wystarczająco", "⚠️ Granicznie", "❌ Niewystarczające"

  const DeviceCheck({
    required this.deviceName,
    required this.ratedCurrent,
    required this.breakingCapacity,
    required this.canWithstand,
    required this.status,
  });
}

class ReferenceTable {
  static const List<Map<String, dynamic>> commonFuses = [
    {'name': 'Bezpiecznik 10A', 'rated': 10.0, 'breaking': 6.0},
    {'name': 'Bezpiecznik 16A', 'rated': 16.0, 'breaking': 6.0},
    {'name': 'Bezpiecznik 20A', 'rated': 20.0, 'breaking': 6.0},
    {'name': 'Bezpiecznik 25A', 'rated': 25.0, 'breaking': 6.0},
    {'name': 'Bezpiecznik 32A', 'rated': 32.0, 'breaking': 6.0},
    {'name': 'Bezpiecznik 40A', 'rated': 40.0, 'breaking': 6.0},
    {'name': 'Bezpiecznik 50A', 'rated': 50.0, 'breaking': 6.0},
  ];

  static const List<Map<String, dynamic>> commonMcbs = [
    {'name': 'Wyłącznik 10A C', 'rated': 10.0, 'breaking': 10.0},
    {'name': 'Wyłącznik 16A C', 'rated': 16.0, 'breaking': 10.0},
    {'name': 'Wyłącznik 20A C', 'rated': 20.0, 'breaking': 10.0},
    {'name': 'Wyłącznik 25A C', 'rated': 25.0, 'breaking': 10.0},
    {'name': 'Wyłącznik 32A C', 'rated': 32.0, 'breaking': 10.0},
    {'name': 'Wyłącznik 40A C', 'rated': 40.0, 'breaking': 10.0},
  ];

  static const List<Map<String, dynamic>> cableResistance = [
    // [mm², Cu @ 20°C, Cu @ 70°C, Al @ 20°C, Al @ 70°C]
    {'section': 1.0, 'cuWarm': 0.018, 'cuHot': 0.0225, 'alWarm': 0.0283, 'alHot': 0.0365},
    {'section': 1.5, 'cuWarm': 0.0121, 'cuHot': 0.015, 'alWarm': 0.0189, 'alHot': 0.0249},
    {'section': 2.5, 'cuWarm': 0.0072, 'cuHot': 0.009, 'alWarm': 0.0113, 'alHot': 0.0149},
    {'section': 4.0, 'cuWarm': 0.0045, 'cuHot': 0.00562, 'alWarm': 0.00707, 'alHot': 0.00931},
    {'section': 6.0, 'cuWarm': 0.003, 'cuHot': 0.00375, 'alWarm': 0.00471, 'alHot': 0.00621},
    {'section': 10.0, 'cuWarm': 0.0018, 'cuHot': 0.00225, 'alWarm': 0.00283, 'alHot': 0.00365},
    {'section': 16.0, 'cuWarm': 0.00112, 'cuHot': 0.0014, 'alWarm': 0.00177, 'alHot': 0.00229},
  ];

  static const String disclaimerText =
      'Niniejsze narzędzie wspomagające jest przeznaczone wyłącznie do wstępnej oceny obwodów zwarciowych '
      'i nie stanowi projektu, opinii technicznej ani porady prawnej. Wszelkie obliczenia muszą być '
      'weryfikowane przez uprawnionego projektanta zasilania elektrycznego zgodnie z normą PN-HD 60364. '
      'Odpowiedzialność za poprawność wyboru urządzeń ochronnych spoczywa na projektancie i inspektorze. '
      'Aplikacja nie uwzględnia wszystkich czynników wpływających na Isc (np. impedancja transformatora '
      'może być inna niż założona, długość kabla może być niedokładna, temperatura pracy zmienia rezystancję).';

  static const String standardsNote =
      'Obliczenia zgodne z:\n'
      '• PN-EN 60909:2016 - Prąd zwarcia\n'
      '• PN-HD 60364 series - Instalacje elektryczne niskonapięciowe\n'
      '• Wytyczne producenta Twoich urządzeń ochronnych';
}
