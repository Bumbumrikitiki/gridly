import 'package:flutter_test/flutter_test.dart';
import 'package:gridly/multitool/zwarcie/logic/short_circuit_provider.dart';
import 'package:gridly/multitool/zwarcie/models/short_circuit_models.dart';

void main() {
  group('ShortCircuit math validation', () {
    test('default case returns physically plausible result', () async {
      final provider = ShortCircuitProvider();

      await provider.calculateShortCircuit(
        const ShortCircuitInput(
          iscNetwork: 3.0,
          cableLength: 50,
          cableCrossSection: 2.5,
          cableMaterial: CableMaterial.copper,
          isWarmCable: true,
          nominalVoltage: 230,
        ),
      );

      final result = provider.result;
      expect(result, isNotNull);
      expect(result!.iscatPoint, greaterThan(0));
      expect(result.iscatPoint, lessThan(3.0));
      expect(result.cableResistance, closeTo(0.45, 0.02));
      expect(result.cableReactance, closeTo(0.004, 0.0005));
      expect(result.impedance, closeTo(0.45, 0.02));
    });

    test('larger cross-section increases short-circuit current', () async {
      final providerSmall = ShortCircuitProvider();
      final providerLarge = ShortCircuitProvider();

      await providerSmall.calculateShortCircuit(
        const ShortCircuitInput(
          iscNetwork: 6.0,
          cableLength: 80,
          cableCrossSection: 2.5,
          cableMaterial: CableMaterial.copper,
          isWarmCable: true,
          nominalVoltage: 230,
        ),
      );

      await providerLarge.calculateShortCircuit(
        const ShortCircuitInput(
          iscNetwork: 6.0,
          cableLength: 80,
          cableCrossSection: 16.0,
          cableMaterial: CableMaterial.copper,
          isWarmCable: true,
          nominalVoltage: 230,
        ),
      );

      expect(providerSmall.result, isNotNull);
      expect(providerLarge.result, isNotNull);
      expect(
        providerLarge.result!.iscatPoint,
        greaterThan(providerSmall.result!.iscatPoint),
      );
    });

    test('invalid input produces error and no result', () async {
      final provider = ShortCircuitProvider();

      await provider.calculateShortCircuit(
        const ShortCircuitInput(
          iscNetwork: 0,
          cableLength: 50,
          cableCrossSection: 2.5,
          cableMaterial: CableMaterial.copper,
          isWarmCable: true,
          nominalVoltage: 230,
        ),
      );

      expect(provider.result, isNull);
      expect(provider.errorMessage, isNotNull);
    });
  });
}
