import 'package:flutter_test/flutter_test.dart';
import 'package:gridly/multitool/uziemienie/logic/grounding_provider.dart';
import 'package:gridly/multitool/uziemienie/models/grounding_models.dart';

void main() {
  group('Grounding math validation', () {
    GroundingInput buildInput({
      required GroundingElectrodeType electrodeType,
      required int electrodes,
    }) {
      return GroundingInput(
        systemVoltage: 230,
        soilType: SoilType.clay,
        customSoilResistivity: 100,
        electrodeType: electrodeType,
        numberOfElectrodes: electrodes,
        electrodeLength: 1.5,
        electrodeDiameter: 16,
        spacingBetweenElectrodes: 3.0,
        isSeasonalVariation: true,
        elementsToGround: GroundingProvider.getDefaultElements(
          GroundingSystemType.tnS,
        ),
        designCurrent: 40,
        systemType: GroundingSystemType.tnS,
      );
    }

    test('result is positive and finite for typical input', () async {
      final provider = GroundingProvider();
      await provider.calculateGrounding(
        buildInput(
          electrodeType: GroundingElectrodeType.verticalRod,
          electrodes: 1,
        ),
      );

      final result = provider.result;
      expect(result, isNotNull);
      expect(result!.singleElectrodeResistance, greaterThan(0));
      expect(result.totalGroundingResistance, greaterThan(0));
      expect(result.adjustedGroundingResistance, greaterThan(0));
      expect(result.singleElectrodeResistance.isFinite, isTrue);
      expect(result.adjustedGroundingResistance.isFinite, isTrue);
    });

    test('adding electrodes decreases total grounding resistance', () async {
      final providerOne = GroundingProvider();
      final providerMany = GroundingProvider();

      await providerOne.calculateGrounding(
        buildInput(
          electrodeType: GroundingElectrodeType.verticalRod,
          electrodes: 1,
        ),
      );
      await providerMany.calculateGrounding(
        buildInput(
          electrodeType: GroundingElectrodeType.verticalRod,
          electrodes: 4,
        ),
      );

      expect(providerOne.result, isNotNull);
      expect(providerMany.result, isNotNull);
      expect(
        providerMany.result!.totalGroundingResistance,
        lessThan(providerOne.result!.totalGroundingResistance),
      );
    });

    test('plate electrode formula returns valid value', () async {
      final provider = GroundingProvider();
      await provider.calculateGrounding(
        buildInput(
          electrodeType: GroundingElectrodeType.groundingPlate,
          electrodes: 1,
        ),
      );

      final result = provider.result;
      expect(result, isNotNull);
      expect(result!.singleElectrodeResistance, greaterThan(0));
      expect(result.singleElectrodeResistance.isFinite, isTrue);
    });
  });
}
