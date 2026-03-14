import 'package:flutter/foundation.dart';
import 'package:gridly/multitool/uziemienie/models/grounding_models.dart';
import 'dart:math';

/// Provider for grounding system calculations
/// Based on PN-HD 60364-5-54 and simplified engineering formulas
class GroundingProvider extends ChangeNotifier {
  GroundingInput? _input;
  GroundingResult? _result;
  String? _errorMessage;

  GroundingInput? get input => _input;
  GroundingResult? get result => _result;
  String? get errorMessage => _errorMessage;

  /// Get default elements to ground based on system type
  static List<GroundableElement> getDefaultElements(GroundingSystemType systemType) {
    final allElements = [
      GroundableElement(
        id: 'metal_structures',
        name: 'Konstrukcje metalowe budynku',
        description: 'Ramy, belki, słupy metalowe',
        required: true,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'water_gas_pipes',
        name: 'Przewody wody i gazu',
        description: 'Rury metalowe wodociągu i gazociągu',
        required: true,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'central_heating',
        name: 'Centralny system grzewczy',
        description: 'Rury grzejnika, kotły metalowe',
        required: true,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'lightning_protection',
        name: 'System ochrony przed błyskawicą',
        description: 'Piorunochrony, przewody zstępujące',
        required: true,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'control_panels',
        name: 'Rozdzielnice i pomieszczenia elektryczne',
        description: 'Obudowy rozdzielnic, szyny ochronne',
        required: true,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'electrical_equipment',
        name: 'Urządzenia elektryczne (obudowy metalowe)',
        description: 'Pralki, piece, elektryczne urządzenia gospodarcze',
        required: true,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'communication_systems',
        name: 'Systemy telekomunikacyjne',
        description: 'Anteny, przewody międzysystemowe',
        required: false,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'lifts',
        name: 'Windy i urządzenia transportu pionowego',
        description: 'Ramy wind, urządzenia podnoszące',
        required: true,
        systemType: 'All',
      ),
      GroundableElement(
        id: 'swimming_pool',
        name: 'Baseny i fontanny',
        description: 'Urządzenia wodne w zasięgu towarzyszącego przewodnika',
        required: true,
        systemType: 'TT',
      ),
      GroundableElement(
        id: 'outdoor_structures',
        name: 'Konstrukcje zewnętrzne (metalowe bramy, ogrodzenia)',
        description: 'Elementy na zewnątrz budynku',
        required: false,
        systemType: 'TT',
      ),
    ];

    return allElements
        .where((e) => e.systemType == 'All' || e.systemType == systemType.code)
        .toList();
  }

  /// Calculate grounding system resistance
  /// Using a simplified model for a vertical rod: R = (ρ/2πL) × ln(2L/d)
  Future<void> calculateGrounding(GroundingInput input) async {
    try {
      _errorMessage = null;
      _input = input;

      // 1. Get soil resistivity
      final soilResistivity = input.getSoilResistivity();

      // 2. Calculate single electrode resistance (simplified rod model)
      final singleResistance = _calculateElectrodeResistance(
        soilResistivity: soilResistivity,
        length: input.electrodeLength,
        diameter: input.electrodeDiameter,
        type: input.electrodeType,
      );

      // 3. Calculate total resistance with multiple electrodes
      // Simplified: parallel connection with reduction factor
      final reductionFactor = _calculateReductionFactor(
        numberOfElectrodes: input.numberOfElectrodes,
        spacing: input.spacingBetweenElectrodes,
        electrodeLength: input.electrodeLength,
      );
      final totalResistance =
          singleResistance / (input.numberOfElectrodes * reductionFactor);

      // 4. Apply seasonal adjustment (if applicable)
      final seasonalFactor = input.isSeasonalVariation ? 2.0 : 1.0;
      final adjustedResistance = totalResistance * seasonalFactor;

      // 5. Determine max allowed resistance based on system type & protection
      final maxAllowedResistance = _getMaxAllowedResistance(
        systemType: input.systemType,
        designCurrent: input.designCurrent,
      );

      // 6. Check requirements
      final meetsRequirements = adjustedResistance <= maxAllowedResistance;

      // 7. Generate requirement checks
      final checks = _generateRequirementChecks(
        meetsRequirements: meetsRequirements,
        actualResistance: adjustedResistance,
        allowedResistance: maxAllowedResistance,
        systemType: input.systemType,
        designCurrent: input.designCurrent,
      );

      // 8. Suggest cables based on PE requirements
      final suggestedCables = _suggestCables(
        input.systemType,
        input.designCurrent,
      );

      // 9. Check protection devices
      final protectionChecks = _checkProtectionDevices(
        adjustedResistance,
        input.systemType,
      );

      _result = GroundingResult(
        input: input,
        singleElectrodeResistance: singleResistance,
        totalGroundingResistance: totalResistance,
        seasonalAdjustmentFactor: seasonalFactor,
        adjustedGroundingResistance: adjustedResistance,
        maxAllowedResistance: maxAllowedResistance,
        meetsRequirements: meetsRequirements,
        requirementChecks: checks,
        suggestedCables: suggestedCables,
        protectionDevices: protectionChecks,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Błąd kalkulacji: $e';
      notifyListeners();
    }
  }

  /// Calculate single electrode resistance using simplified engineering formulas
  /// R = (ρ/2πL) × ln(2L/d) where d is diameter
  double _calculateElectrodeResistance({
    required double soilResistivity,
    required double length,
    required double diameter,
    required GroundingElectrodeType type,
  }) {
    // Convert diameter to length units (mm to m)
    final diameterM = diameter / 1000;

    switch (type) {
      case GroundingElectrodeType.verticalRod:
        // R = (ρ/2πL) × ln(2L/d) - simplified rod formula with diameter
        return (soilResistivity / (2 * pi * length)) *
            log(2 * length / diameterM);

      case GroundingElectrodeType.horizontalStrip:
        // Simplified: strip is 2m long by default, use rod-like formula
        // R ≈ (ρ/πL) (for shallow horizontal conductor)
        return soilResistivity / (pi * length);

      case GroundingElectrodeType.groundingPlate:
        // Simplified square plate model: R ≈ ρ / (4a), where a is plate side [m]
        // Assume square plate with side approximated by input diameter.
        final side = diameter / 1000;
        return soilResistivity / (4 * side);

      case GroundingElectrodeType.pipeConcrete:
        // Pipeline in concrete: R ≈ 0.5 × (ρ/2πL) × ln(2L/d)
        return 0.5 *
            (soilResistivity / (2 * pi * length)) *
            log(2 * length / diameterM);

      case GroundingElectrodeType.concreteFooting:
        // Footing in concrete: R ≈ 0.7 × (ρ/2πL) × ln(2L/d)
        return 0.7 *
            (soilResistivity / (2 * pi * length)) *
            log(2 * length / diameterM);
    }
  }

  /// Calculate reduction factor for multiple electrodes (Sunde's formula)
  /// Simplified version based on spacing
  double _calculateReductionFactor({
    required int numberOfElectrodes,
    required double spacing,
    required double electrodeLength,
  }) {
    if (numberOfElectrodes <= 1) return 1.0;

    // Simplified: reduction factor based on spacing ratio
    // If spacing >= 5×length: fully independent (factor = 1)
    // If spacing < length: significant coupling (factor < 1)
    final spacingRatio = spacing / electrodeLength;

    if (spacingRatio >= 5.0) {
      return 0.95; // Nearly independent
    } else if (spacingRatio >= 2.0) {
      return 0.85;
    } else if (spacingRatio >= 1.0) {
      return 0.70;
    } else {
      return 0.50; // Very close electrodes
    }
  }

  /// Get maximum allowed grounding resistance based on system type
  double _getMaxAllowedResistance({
    required GroundingSystemType systemType,
    required double designCurrent,
  }) {
    switch (systemType) {
      case GroundingSystemType.tnS:
      case GroundingSystemType.tnCS:
        // TN systems: typically 1Ω (for main earthing conductor)
        // PN-HD 60364: max 1Ω for urban areas, flexible for rural
        return 1.0;

      case GroundingSystemType.tt:
        // TT system: Rg × IΔn ≤ 50V
        // Typically IΔn = 30mA, so Rg ≤ 50/0.03 ≈ 1667Ω
        // But practically aims for Rg ≤ 10-100Ω for reliability
        const defaultTTResistance = 50.0; // [Ω]
        return defaultTTResistance;

      case GroundingSystemType.it:
        // IT systems: special requirements, typically 10-50Ω
        return 10.0;
    }
  }

  /// Generate detailed requirement checks
  List<String> _generateRequirementChecks({
    required bool meetsRequirements,
    required double actualResistance,
    required double allowedResistance,
    required GroundingSystemType systemType,
    required double designCurrent,
  }) {
    final checks = <String>[];

    checks.add(
      'Rezystancja uziemienia: ${actualResistance.toStringAsFixed(2)} Ω'
      ' (limit: ${allowedResistance.toStringAsFixed(2)} Ω)',
    );

    if (meetsRequirements) {
      checks.add('✅ Rezystancja uziemienia SPEŁNIA wymagania');
    } else {
      checks.add('❌ Rezystancja uziemienia PRZEKRACZA limit');
    }

    // System-specific checks
    switch (systemType) {
      case GroundingSystemType.tnS:
      case GroundingSystemType.tnCS:
        checks.add('System ${systemType.code}: projektowo zwykle dąży się do Rg ≤ 1 Ω');
        checks.add('Warunek samoczynnego wyłączenia zasilania należy zweryfikować przez impedancję pętli zwarcia.');

      case GroundingSystemType.tt:
        final protectionVoltage = (30 / 1000) * actualResistance; // 30mA RCD
        checks.add(
          'System TT: wymaga RCD 30 mA, przyjęto kryterium projektowe Rg ≤ 50 Ω',
        );
        checks.add(
          'Napięcie ochronne: ${protectionVoltage.toStringAsFixed(2)} V'
          ' (max 50V)',
        );
        if (protectionVoltage <= 50) {
          checks.add('✅ Napięcie ochronne SPEŁNIA wymagania');
        } else {
          checks.add('❌ Napięcie ochronne PRZEKRACZA limit');
        }

      case GroundingSystemType.it:
        checks.add(
          'System IT: wymaga ciągłego monitorowania izolacji',
        );
    }

    return checks;
  }

  /// Suggest PE/PEN cable sizes based on system type and design current
  List<CableRequirement> _suggestCables(
    GroundingSystemType systemType,
    double designCurrent,
  ) {
    const standard = 'PN-HD 60364-5-54';

    return [
      if (designCurrent <= 20)
        CableRequirement(
          minCrossSectionMm2: 2.5,
          material: 'Cu',
          minCurrent: 20,
          description: 'PE dla projektów małych (≤20A)',
          standard: standard,
        )
      else if (designCurrent <= 63)
        CableRequirement(
          minCrossSectionMm2: 4.0,
          material: 'Cu',
          minCurrent: 63,
          description: 'PE dla instalacji średnich (≤63A)',
          standard: standard,
        )
      else if (designCurrent <= 160)
        CableRequirement(
          minCrossSectionMm2: 6.0,
          material: 'Cu',
          minCurrent: 160,
          description: 'PE dla instalacji większych (≤160A)',
          standard: standard,
        )
      else
        CableRequirement(
          minCrossSectionMm2: 10.0,
          material: 'Cu',
          minCurrent: 250,
          description: 'PE dla głównych rozdzielnic (>160A)',
          standard: standard,
        ),
      CableRequirement(
        minCrossSectionMm2: 2.5,
        material: 'Cu',
        minCurrent: 16,
        description: 'Przewód wyrównawczy (zaciski uziemiające)',
        standard: standard,
      ),
    ];
  }

  /// Check which protection devices are suitable
  List<ProtectionDeviceCheck> _checkProtectionDevices(
    double groundingResistance,
    GroundingSystemType systemType,
  ) {
    final devices = [
      ProtectionDevice(
        name: 'RCD Typ A 30mA / 40A',
        ratedCurrent: 40,
        ratedSensitivity: 30,
        isRcd: true,
        type: 'A',
      ),
      ProtectionDevice(
        name: 'RCD Typ AC 30mA / 63A',
        ratedCurrent: 63,
        ratedSensitivity: 30,
        isRcd: true,
        type: 'AC',
      ),
      ProtectionDevice(
        name: 'RCD Typ A 100mA / 40A',
        ratedCurrent: 40,
        ratedSensitivity: 100,
        isRcd: true,
        type: 'A',
      ),
    ];

    return devices.map((device) {
      final suitable = device.canProtect(groundingResistance);
      final requiredResistance = 50.0 / (device.ratedSensitivity / 1000);

      return ProtectionDeviceCheck(
        device: device,
        suitable: suitable,
        reason: suitable
            ? 'Ochrona wystarczająca dla Rg=${groundingResistance.toStringAsFixed(2)}Ω'
            : 'Ochrona niewystarczająca, wymagana Rg ≤ ${requiredResistance.toStringAsFixed(1)}Ω',
        requiredResistance: requiredResistance,
        actualResistance: groundingResistance,
      );
    }).toList();
  }

  void reset() {
    _input = null;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
