import 'package:flutter/foundation.dart';
import 'package:gridly/multitool/zwarcie/models/short_circuit_models.dart';

class ShortCircuitProvider extends ChangeNotifier {
  late ShortCircuitInput _input;
  ShortCircuitResult? _result;
  String? _errorMessage;

  ShortCircuitInput? get input => _input;
  ShortCircuitResult? get result => _result;
  String? get errorMessage => _errorMessage;

  /// Calculate short circuit current at measurement point
  /// Based on IEC 60909 simplified formula for LV networks
  ///
  /// Isc(at point) = Unom / Z
  /// where Z = R + jX (resistance + reactance of the cable)
  /// 
  /// R = ρ × L / S
  /// ρ = resistivity [Ω·mm²/m]
  /// L = length [m]
  /// S = cross-section [mm²]
  ///
  /// X ≈ 0.08 Ω/m (per phase, typical for AC 50Hz LV)
  Future<void> calculateShortCircuit(ShortCircuitInput input) async {
    try {
      _errorMessage = null;
      _input = input;

      // 1. Calculate cable resistance
      final resistivity =
          input.cableMaterial.getResistivity(input.isWarmCable);
      final cableResistance =
          (resistivity * input.cableLength) / input.cableCrossSection;

      // 2. Estimate cable reactance (0.08 Ω/m per phase for AC 50Hz)
      final cableReactance = 0.08 * input.cableLength;

      // 3. Calculate impedance (simplified: Z ≈ R for LV)
      final impedance = cableResistance; // In practice, R >> X for LV

      // 4. Calculate Isc at measurement point
      // From Isc(source) = Unom / Zk, we get:
      // Zk_total = Unom / Isc(source)
      // Zk at point = Zk_source + Z_cable
      // Isc(at point) = Unom / Zk_total
      final zkSource = input.nominalVoltage / (input.iscNetwork * 1000); // Convert kA to A
      final zkTotal = zkSource + impedance;
      final iscAtPoint = input.nominalVoltage / (zkTotal * 1000); // Convert to kA

      // 5. Verify protection devices
      final deviceChecks = _verifyDevices(iscAtPoint);

      // 6. Generate warnings
      final warnings = _generateWarnings(iscAtPoint, cableResistance);

      // 7. Determine hazard level
      final isHazardous = iscAtPoint > input.iscNetwork * 0.8;

      _result = ShortCircuitResult(
        iscatPoint: iscAtPoint,
        cableResistance: cableResistance,
        cableReactance: cableReactance,
        impedance: impedance,
        deviceChecks: deviceChecks,
        warnings: warnings,
        isHazardous: isHazardous,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Błąd obliczenia: $e';
      _result = null;
      notifyListeners();
    }
  }

  List<DeviceCheck> _verifyDevices(double iscKa) {
    final checks = <DeviceCheck>[];

    // Check common fuses
    for (final fuse in ReferenceTable.commonFuses) {
      final canWithstand = iscKa <= (fuse['breaking'] as double);
      final status = canWithstand
          ? '✅ Wystarczająco'
          : iscKa <= (fuse['breaking'] as double) + 1
              ? '⚠️ Granicznie'
              : '❌ Niewystarczające';

      checks.add(
        DeviceCheck(
          deviceName: fuse['name'] as String,
          ratedCurrent: fuse['rated'] as double,
          breakingCapacity: fuse['breaking'] as double,
          canWithstand: canWithstand,
          status: status,
        ),
      );
    }

    // Check common MCBs
    for (final mcb in ReferenceTable.commonMcbs) {
      final canWithstand = iscKa <= (mcb['breaking'] as double);
      final status = canWithstand
          ? '✅ Wystarczająco'
          : iscKa <= (mcb['breaking'] as double) + 1
              ? '⚠️ Granicznie'
              : '❌ Niewystarczające';

      checks.add(
        DeviceCheck(
          deviceName: mcb['name'] as String,
          ratedCurrent: mcb['rated'] as double,
          breakingCapacity: mcb['breaking'] as double,
          canWithstand: canWithstand,
          status: status,
        ),
      );
    }

    return checks;
  }

  List<String> _generateWarnings(double iscKa, double resistance) {
    final warnings = <String>[];

    if (iscKa > 6.0) {
      warnings.add(
          '⚠️ Wysokie zwarcie (>6kA) - wymagane urządzenia o dużej zdolności łącznej!');
    }

    if (resistance > 0.1) {
      warnings.add(
          '⚠️ Wysoki opór kabla - weryfikuj dobór przekroju dla wymaganych obciążeń');
    }

    if (_input.cableCrossSection < 2.5) {
      warnings.add(
          '⚠️ Przekrój poniżej 2.5mm² - zwróć uwagę na spadek napięcia podczas bezpiecznego pracy!');
    }

    warnings.add(
        '💡 Zawsze konsultuj wyniki z projektantem i inspektorem zasilania elektrycznego!');

    return warnings;
  }

  void reset() {
    _input = ShortCircuitInput(
      iscNetwork: 0,
      cableLength: 0,
      cableCrossSection: 2.5,
      cableMaterial: CableMaterial.copper,
      isWarmCable: true,
      nominalVoltage: 230,
    );
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
