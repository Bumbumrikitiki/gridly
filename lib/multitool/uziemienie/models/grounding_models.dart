// Grounding system models
// Based on PN-IEC 60364, PN-EN 60950, and TN-S/TN-C-S/TT systems

/// Soil types and their characteristics
enum SoilType {
  clay(
    'Glina',
    100,
    200,
    'Wilgotna glina, rezystywność 100-200 Ω·m',
  ),
  loam(
    'Muł',
    200,
    400,
    'Średnia wilgotność, rezystywność 200-400 Ω·m',
  ),
  sand(
    'Piasek',
    400,
    1000,
    'Wysoka rezystywność, rezystywność 400-1000 Ω·m',
  ),
  rock(
    'Skała',
    1000,
    5000,
    'Wysoka rezystywność, rezystywność 1000-5000 Ω·m',
  ),
  peat(
    'Torf',
    30,
    100,
    'Niska rezystywność, rezystywność 30-100 Ω·m',
  );

  final String name;
  final double minResistivity; // [Ω·m]
  final double maxResistivity;
  final String description;

  const SoilType(
    this.name,
    this.minResistivity,
    this.maxResistivity,
    this.description,
  );

  double getAvgResistivity() =>
      (minResistivity + maxResistivity) / 2;
}

/// Grounding electrode types
enum GroundingElectrodeType {
  verticalRod(
    'Pręt pionowy',
    'Rod vertical',
    // L (m), diameter (mm), typical values
    1.5,
    15,
    'Pręt, najmniej drogi, wymaga pęknięcia gruntu',
  ),
  horizontalStrip(
    'Pas poziomy',
    'Horizontal strip',
    2.0,
    10,
    'Taśma/przewód miedziany, łączy elektrody',
  ),
  groundingPlate(
    'Płyta uziemiająca',
    'Grounding plate',
    0.8,
    30,
    'Płyta (Cu/Fe), wysoka zmiana rezystancji ze stażem',
  ),
  pipeConcrete(
    'Rura betonowa',
    'Pipe concrete',
    3.0,
    10,
    'Rura w betonie fundamentów, ekonomiczne',
  ),
  concreteFooting(
    'Fundament betonowy',
    'Concrete footing',
    2.0,
    10,
    'Elektrody w betonie fundamentów budynku',
  );

  final String name;
  final String nameEn;
  final double standardLength; // [m]
  final double standardDiameter; // [mm]
  final String description;

  const GroundingElectrodeType(
    this.name,
    this.nameEn,
    this.standardLength,
    this.standardDiameter,
    this.description,
  );
}

/// Grounding system types (TN-S, TN-C-S, TT, IT)
enum GroundingSystemType {
  tnS(
    'TN-S',
    'Neutral and PE separate throughout',
    'Bezpieczne, wymaga oddzielnych przewodów N i PE',
    true,
  ),
  tnCS(
    'TN-C-S',
    'Neutral and PE combined (PEN) then separated',
    'Połączenie N i PE na rozdzielnica, wymaga ochrony',
    true,
  ),
  tt(
    'TT',
    'Independent grounding at consumer',
    'Elektrody na konsumencie, wymaga RCD 30mA',
    true,
  ),
  it(
    'IT',
    'Floating neutral, grounded through impedance',
    'Systemy medyczne/krytyczne, specjalistyczne',
    false,
  );

  final String code;
  final String description;
  final String examplePl;
  final bool commonInPoland;

  const GroundingSystemType(
    this.code,
    this.description,
    this.examplePl,
    this.commonInPoland,
  );
}

/// Protection device for grounding check (RCD/RCCB)
class ProtectionDevice {
  final String name;
  final double ratedCurrent; // [A] - In
  final double ratedSensitivity; // [mA] - IΔn
  final bool isRcd; // true = RCD, false = MCB
  final String type; // "A", "B", "AC"

  ProtectionDevice({
    required this.name,
    required this.ratedCurrent,
    required this.ratedSensitivity,
    required this.isRcd,
    required this.type,
  });

  /// Check if this device can protect with given grounding resistance
  bool canProtect(double groundingResistance) {
    // U = I × R, max allowed U = 50V (TN) or 120V (TT)
    // IΔn × Rg ≤ 50V
    final maxVoltage = 50.0; // [V]
    return (ratedSensitivity / 1000) * groundingResistance <= maxVoltage;
  }
}

/// Elements to be grounded (checklist)
class GroundableElement {
  final String id;
  final String name;
  final String description;
  final bool required; // PN-IEC 60364 requirement
  final String systemType; // TN-S, TN-C-S, TT, All
  bool isSelected;

  GroundableElement({
    required this.id,
    required this.name,
    required this.description,
    required this.required,
    required this.systemType,
    this.isSelected = false,
  });

  GroundableElement copyWith({bool? isSelected}) {
    return GroundableElement(
      id: id,
      name: name,
      description: description,
      required: required,
      systemType: systemType,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Input parameters for grounding resistance calculation
class GroundingInput {
  final double systemVoltage; // [V] - 230, 400, etc.
  final SoilType soilType;
  final double customSoilResistivity; // [Ω·m] - custom value
  final GroundingElectrodeType electrodeType;
  final int numberOfElectrodes; // quantity of electrodes
  final double electrodeLength; // [m]
  final double electrodeDiameter; // [mm]
  final double spacingBetweenElectrodes; // [m]
  final bool isSeasonalVariation; // apply seasonal correction?
  final List<GroundableElement> elementsToGround;
  final double designCurrent; // [A] - max fault current expected
  final GroundingSystemType systemType;

  GroundingInput({
    required this.systemVoltage,
    required this.soilType,
    required this.customSoilResistivity,
    required this.electrodeType,
    required this.numberOfElectrodes,
    required this.electrodeLength,
    required this.electrodeDiameter,
    required this.spacingBetweenElectrodes,
    required this.isSeasonalVariation,
    required this.elementsToGround,
    required this.designCurrent,
    required this.systemType,
  });

  double getSoilResistivity() =>
      customSoilResistivity > 0
          ? customSoilResistivity
          : soilType.getAvgResistivity();
}

/// Output with calculated grounding parameters
class GroundingResult {
  final GroundingInput input;
  final double singleElectrodeResistance; // [Ω]
  final double totalGroundingResistance; // [Ω] (multiple electrodes)
  final double seasonalAdjustmentFactor; // 1.5-3x depending on season
  final double adjustedGroundingResistance; // [Ω] with seasonal
  final double maxAllowedResistance; // [Ω] based on system type
  final bool meetsRequirements;
  final List<String> requirementChecks; // detailed checks
  final List<CableRequirement> suggestedCables;
  final List<ProtectionDeviceCheck> protectionDevices;

  GroundingResult({
    required this.input,
    required this.singleElectrodeResistance,
    required this.totalGroundingResistance,
    required this.seasonalAdjustmentFactor,
    required this.adjustedGroundingResistance,
    required this.maxAllowedResistance,
    required this.meetsRequirements,
    required this.requirementChecks,
    required this.suggestedCables,
    required this.protectionDevices,
  });
}

/// Cable recommendation for PE/PEN conductor
class CableRequirement {
  final double minCrossSectionMm2; // [mm²]
  final String material; // Cu, Al
  final double minCurrent; // [A]
  final String description;
  final String standard; // PN-IEC 60364

  CableRequirement({
    required this.minCrossSectionMm2,
    required this.material,
    required this.minCurrent,
    required this.description,
    required this.standard,
  });
}

/// Protection device eligibility check
class ProtectionDeviceCheck {
  final ProtectionDevice device;
  final bool suitable;
  final String reason;
  final double requiredResistance; // [Ω]
  final double actualResistance; // [Ω]

  ProtectionDeviceCheck({
    required this.device,
    required this.suitable,
    required this.reason,
    required this.requiredResistance,
    required this.actualResistance,
  });
}

/// Standards reference data
class ReferenceTable {
  static const String standardsNote = '''
PN-IEC 60364-5-54: Ziemnie i urządzenia ochronne
- TN-S/TN-C-S: Rg ≤ 1Ω (zwykle)
- TT: Rg × IΔn ≤ 50V, typowo Rg ≤ 10-100Ω
- Wzór Wenner'a dla pręta: R = (ρ/2πL) × ln(2L/a)
  gdzie L = długość [m], a = promień [mm]

PN-EN 60950: Bezpieczeństwo instalacji elektrycznych
- Max U przy zwarciu: 50V (TN), 120V (TT)
- RCD 30mA wymóg dla TT
''';

  static const String disclaimerText = '''
OGRANICZENIE ODPOWIEDZIALNOŚCI:
Kalkulator wspomaga projektowanie systemu uziemienia, nie zastępuje:
- Pomiaru rzeczywistej rezystywności gruntu (metoda Wennera)
- Pomiaru rezystancji uziemienia w terenie
- Konsultacji z projektantem elektrycznym
- Zatwierdzenia przez UDT/inspektora

Wyniki są orientacyjne. Sezon zmienia rezystywność o 1.5-3x.
''';

  static const soilResistivityNotes = '''
Rezystywność gruntu zależy od:
- Rodzaju gleby (piasek > glina > torf)
- Wilgotności (suchość zwiększa rezystywność)
- Temperatury (zima zwiększa rezystywność, lato zmniejsza)
- Głębokości (zmienia się z głębokością)

Pomiar metodą Wennera lub Schlumberger jest wymagany dla projektów.
''';
}
