import 'package:flutter/cupertino.dart';
import 'package:gridly/multitool/field_guide/models/field_guide_models.dart';

/// Baza pomiarów i uziemień dla różnych scenariuszy
class FieldGuideDatabase {
  /// Standardowe pomiary
  static final Map<MeasurementType, MeasurementType> _measurementTypes = {
    MeasurementType(
      id: 'loop',
      name: 'Pętla (Zs)',
      description: 'Impedancja pętli zwarcia',
      unit: 'Ω',
      maxValue: '1.37',
      icon: CupertinoIcons.bolt_circle,
    ): MeasurementType(
      id: 'loop',
      name: 'Pętla (Zs)',
      description: 'Impedancja pętli zwarcia',
      unit: 'Ω',
      maxValue: '1.37',
      icon: CupertinoIcons.bolt_circle,
    ),
    MeasurementType(
      id: 'riso',
      name: 'Riso (RI)',
      description: 'Rezystancja izolacji',
      unit: 'MΩ',
      minValue: '0.5',
      icon: CupertinoIcons.waveform_path,
    ): MeasurementType(
      id: 'riso',
      name: 'Riso (RI)',
      description: 'Rezystancja izolacji',
      unit: 'MΩ',
      minValue: '0.5',
      icon: CupertinoIcons.waveform_path,
    ),
    MeasurementType(
      id: 'rcd',
      name: 'RCD (RRCBO)',
      description: 'Test wyłącznika różnicowoprądowego',
      unit: 'mA',
      maxValue: '30',
      icon: CupertinoIcons.checkmark_shield,
    ): MeasurementType(
      id: 'rcd',
      name: 'RCD (RRCBO)',
      description: 'Test wyłącznika różnicowoprądowego',
      unit: 'mA',
      maxValue: '30',
      icon: CupertinoIcons.checkmark_shield,
    ),
    MeasurementType(
      id: 'continuity',
      name: 'Ciągłość PE',
      description: 'Ciągłość przewodu ochronnego',
      unit: 'Ω',
      maxValue: '0.1',
      icon: CupertinoIcons.arrow_right_square,
    ): MeasurementType(
      id: 'continuity',
      name: 'Ciągłość PE',
      description: 'Ciągłość przewodu ochronnego',
      unit: 'Ω',
      maxValue: '0.1',
      icon: CupertinoIcons.arrow_right_square,
    ),
    MeasurementType(
      id: 'voltage',
      name: 'Napięcie',
      description: 'Pomiar napięcia zasilania',
      unit: 'V',
      minValue: '207',
      maxValue: '253',
      icon: CupertinoIcons.bolt_fill,
    ): MeasurementType(
      id: 'voltage',
      name: 'Napięcie',
      description: 'Pomiar napięcia zasilania',
      unit: 'V',
      minValue: '207',
      maxValue: '253',
      icon: CupertinoIcons.bolt_fill,
    ),
  };

  /// Listy pomiarów dla każdego scenariusza
  static final Map<InspectionScenario, MeasurementChecklist>
      measurementChecklists = {
    InspectionScenario.building: MeasurementChecklist(
      scenario: InspectionScenario.building,
      measurements: [
        _createMeasurement('voltage'),
        _createMeasurement('loop'),
        _createMeasurement('riso'),
        _createMeasurement('rcd'),
        _createMeasurement('continuity'),
      ],
    ),
    InspectionScenario.flooding: MeasurementChecklist(
      scenario: InspectionScenario.flooding,
      measurements: [
        _createMeasurement('riso'),
        _createMeasurement('loop'),
        _createMeasurement('rcd'),
        _createMeasurement('continuity'),
      ],
    ),
    InspectionScenario.modernization: MeasurementChecklist(
      scenario: InspectionScenario.modernization,
      measurements: [
        _createMeasurement('voltage'),
        _createMeasurement('loop'),
        _createMeasurement('riso'),
        _createMeasurement('rcd'),
        _createMeasurement('continuity'),
      ],
    ),
    InspectionScenario.maintenance: MeasurementChecklist(
      scenario: InspectionScenario.maintenance,
      measurements: [
        _createMeasurement('rcd'),
        _createMeasurement('loop'),
        _createMeasurement('continuity'),
      ],
    ),
  };

  /// Elementy wymagające uziemienia
  static final List<GroundingElement> requiredGroundingElements = [
    GroundingElement(
      id: 'water_pipes',
      name: 'Rury wodne',
      description: 'Główna rura wodna (za licznikiem)',
      isRequired: true,
      icon: '🔧',
    ),
    GroundingElement(
      id: 'gas_pipes',
      name: 'Rury gazowe',
      description: 'Główna rura gazowa (za licznikiem)',
      isRequired: true,
      icon: '🔥',
    ),
    GroundingElement(
      id: 'heating_system',
      name: 'Instalacja grzewcza',
      description: 'Główne rury instalacji centralnego ogrzewania',
      isRequired: true,
      icon: '🌡️',
    ),
    GroundingElement(
      id: 'metal_baths',
      name: 'Wanny metalowe',
      description: 'Umywalki i wanny z metalową konstrukcją',
      isRequired: true,
      icon: '🛁',
    ),
    GroundingElement(
      id: 'metal_constructions',
      name: 'Konstrukcje metalowe',
      description: 'Stalowe konstrukcje, ramy, ekrany',
      isRequired: true,
      icon: '🏗️',
    ),
    GroundingElement(
      id: 'cable_ducts',
      name: 'Kanały elektroprzewodów',
      description: 'Puszki i kanały metalowe dla przewodów',
      isRequired: true,
      icon: '📦',
    ),
    GroundingElement(
      id: 'external_metal',
      name: 'Elementy metalowe na elewacji',
      description: 'Oprawy, osłony, części metalowe widoczne z zewnątrz',
      isRequired: true,
      icon: '🏠',
    ),
  ];

  /// Wyjątki od uziemienia
  static final List<GroundingException> groundingExceptions = [
    GroundingException(
      id: 'double_insulated',
      name: 'Urządzenia klasy II',
      description: 'Urządzenia z podwójną izolacją',
      reason: 'Nie wymagają uziemienia ze względu na wbudowaną ochronę',
    ),
    GroundingException(
      id: 'disconnected_pipes',
      name: 'Odłączone przewody',
      description: 'Rury/przewody izolowane lub rozłączone',
      reason: 'Przy braku ciągłości uziemienie bywa niewykorzystywane',
    ),
    GroundingException(
      id: 'plastic_pipes',
      name: 'Rury i połączenia plastikowe',
      description: 'Całe odcinki z materiału izolacyjnego',
      reason:
          'Dla materiałów nieprzewodzących uziemienie zwykle nie jest uwzględniane',
    ),
    GroundingException(
      id: 'small_fittings',
      name: 'Małe urządzenia przenośne',
      description: 'Sprzęty z trójstronnym wtyczem lub klasy II',
      reason: 'Ochrona przez izolację lub układ TN-C-S',
    ),
  ];

  /// Minimalne przekroje bednarki (FeZn)
  static final List<CabelSizeRequirement> cableSizeRequirements = [
    CabelSizeRequirement(
      type: 'Bednarka (FeZn)',
      material: 'Stal cynkowana',
      protection: 'Budownictwo',
      crossSections: {
        10: '6',
        20: '10',
        50: '16',
        100: '25',
        200: '35',
      },
    ),
    CabelSizeRequirement(
      type: 'Linka PE',
      material: 'Miedź, mosiądz',
      protection: 'Instalacje',
      crossSections: {
        10: '2.5',
        20: '4',
        50: '6',
        100: '10',
        200: '16',
      },
    ),
    CabelSizeRequirement(
      type: 'Taśma miedziowa',
      material: 'Miedź',
      protection: 'Alternatywa do linki',
      crossSections: {
        10: '2.5',
        20: '4',
        50: '10',
        100: '16',
        200: '25',
      },
    ),
  ];

  /// Pobiera listę pomiarów dla scenariusza
  static MeasurementChecklist? getMeasurementChecklist(
      InspectionScenario scenario) {
    return measurementChecklists[scenario];
  }

  /// Pobiera typ pomiaru po ID
  static MeasurementType? getMeasurementType(String id) {
    for (var type in _measurementTypes.keys) {
      if (type.id == id) return type;
    }
    return null;
  }

  static MeasurementType _createMeasurement(String id) {
    return getMeasurementType(id) ??
        MeasurementType(
          id: id,
          name: 'Unknown',
          description: '',
          unit: '',
          icon: CupertinoIcons.question_circle,
        );
  }
}
