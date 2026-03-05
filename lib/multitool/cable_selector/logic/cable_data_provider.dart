import 'package:gridly/multitool/cable_selector/models/cable_data.dart';

class CableDataProvider {
  static final Map<CableMaterial, Map<CableType, Map<double, CableData>>>
      _data = _buildData();

  static Map<CableMaterial, Map<CableType, Map<double, CableData>>>
      _buildData() {
    final data = <CableMaterial, Map<CableType, Map<double, CableData>>>{
      CableMaterial.cu: _buildCopperCables(),
      CableMaterial.al: _buildAluminumCables(),
    };
    return data;
  }

  static Map<CableType, Map<double, CableData>> _buildCopperCables() {
    return {
      ..._buildYDY(),
      ..._buildYDYP(),
      ..._buildYKY(),
      ..._buildYKXS(),
      ..._buildN2XH(),
      ..._buildNHXH(),
      ..._buildNTSCGEFLOXCY(),
      ..._buildNSGAFOUGEFLOXCY(),
      ..._buildN2XCY(),
      ..._buildNYCY(),
      ..._buildLFLEX(),
      ..._buildKYCH(),
      ..._buildJYY(),
      ..._buildYQQW(),
    };
  }

  static Map<CableType, Map<double, CableData>> _buildAluminumCables() {
    return {
      ..._buildYAKY(),
      ..._buildNA2XY(),
    };
  }

  // YDY - Przewód instalacyjny miedziany
  static Map<CableType, Map<double, CableData>> _buildYDY() {
    return {
      CableType.ydy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.5,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 9.5,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        4.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 4.0,
          coreType: CoreType.re,
          outerDiameter: 11.0,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        6.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 6.0,
          coreType: CoreType.re,
          outerDiameter: 12.5,
          heatShrinkSleeve: '20/7',
          heatShrinkLabel: '10/3',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        10.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 10.0,
          coreType: CoreType.re,
          outerDiameter: 15.0,
          heatShrinkSleeve: '25/8',
          heatShrinkLabel: '12/4',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        16.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 16.0,
          coreType: CoreType.re,
          outerDiameter: 18.0,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        25.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 22.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
      }
    };
  }

  // YDYp - Przewód płaski
  static Map<CableType, Map<double, CableData>> _buildYDYP() {
    return {
      CableType.ydyp: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydyp,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 7.5,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.electrical,
          maxVoltage: '0.45/0.75 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydyp,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 8.5,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.electrical,
          maxVoltage: '0.45/0.75 kV',
          temperatureRange: '-30°C do +70°C',
        ),
      }
    };
  }

  // YKY - Kabel ziemny
  static Map<CableType, Map<double, CableData>> _buildYKY() {
    return {
      CableType.yky: {
        10.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yky,
          crossSection: 10.0,
          coreType: CoreType.re,
          outerDiameter: 16.0,
          heatShrinkSleeve: '25/8',
          heatShrinkLabel: '12/4',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        16.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yky,
          crossSection: 16.0,
          coreType: CoreType.re,
          outerDiameter: 19.0,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        25.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yky,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 23.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
      }
    };
  }

  // YKXS - Kabel z izolacją XLPE
  static Map<CableType, Map<double, CableData>> _buildYKXS() {
    return {
      CableType.ykxs: {
        16.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ykxs,
          crossSection: 16.0,
          coreType: CoreType.re,
          outerDiameter: 18.5,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
        25.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ykxs,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 22.5,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
      }
    };
  }

  // N2XH - Kabel bezhalogenowy (elektryczny, nie pożarowy!)
  static Map<CableType, Map<double, CableData>> _buildN2XH() {
    return {
      CableType.n2xh: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xh,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 9.0,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xh,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 10.0,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
        4.0: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xh,
          crossSection: 4.0,
          coreType: CoreType.re,
          outerDiameter: 11.5,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
      }
    };
  }

  // NHXH - Kabel pożarowy (B2ca)
  static Map<CableType, Map<double, CableData>> _buildNHXH() {
    return {
      CableType.nhxh: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nhxh,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 9.2,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nhxh,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 10.5,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
        4.0: CableData(
          material: CableMaterial.cu,
          type: CableType.nhxh,
          crossSection: 4.0,
          coreType: CoreType.re,
          outerDiameter: 12.0,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
      }
    };
  }

  // NTSCGEFLOXCY - Kabel pożarowy ekranowany
  static Map<CableType, Map<double, CableData>> _buildNTSCGEFLOXCY() {
    return {
      CableType.ntscgefloxcy: {
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ntscgefloxcy,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 13.5,
          heatShrinkSleeve: '20/7',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
        4.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ntscgefloxcy,
          crossSection: 4.0,
          coreType: CoreType.re,
          outerDiameter: 15.0,
          heatShrinkSleeve: '25/8',
          heatShrinkLabel: '10/3',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
      }
    };
  }

  // NSGAFOUGEFLOXCY - Kabel pożarowy
  static Map<CableType, Map<double, CableData>> _buildNSGAFOUGEFLOXCY() {
    return {
      CableType.nsgafougefloxcy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nsgafougefloxcy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 10.5,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nsgafougefloxcy,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 12.0,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
      }
    };
  }

  // N2XCY - Kabel ekranowany
  static Map<CableType, Map<double, CableData>> _buildN2XCY() {
    return {
      CableType.n2xcy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xcy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 10.0,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.industrial,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xcy,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 11.5,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.industrial,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
      }
    };
  }

  // NYCY - Kabel ekranowany PVC
  static Map<CableType, Map<double, CableData>> _buildNYCY() {
    return {
      CableType.nycy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nycy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 9.5,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.industrial,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nycy,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 11.0,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.industrial,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
      }
    };
  }

  // LFLEX - Kabel sterowniczy
  static Map<CableType, Map<double, CableData>> _buildLFLEX() {
    return {
      CableType.lflex: {
        0.75: CableData(
          material: CableMaterial.cu,
          type: CableType.lflex,
          crossSection: 0.75,
          coreType: CoreType.re,
          outerDiameter: 7.5,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.control,
          maxVoltage: '0.3/0.5 kV',
          temperatureRange: '-5°C do +70°C',
        ),
        1.0: CableData(
          material: CableMaterial.cu,
          type: CableType.lflex,
          crossSection: 1.0,
          coreType: CoreType.re,
          outerDiameter: 8.0,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.control,
          maxVoltage: '0.3/0.5 kV',
          temperatureRange: '-5°C do +70°C',
        ),
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.lflex,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.5,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.control,
          maxVoltage: '0.3/0.5 kV',
          temperatureRange: '-5°C do +70°C',
        ),
      }
    };
  }

  // KYCh - Skrętka
  static Map<CableType, Map<double, CableData>> _buildKYCH() {
    return {
      CableType.kych: {
        0.5: CableData(
          material: CableMaterial.cu,
          type: CableType.kych,
          crossSection: 0.5,
          coreType: CoreType.re,
          outerDiameter: 6.0,
          heatShrinkSleeve: '9/3',
          heatShrinkLabel: '3/1',
          application: CableApplication.telecom,
          maxVoltage: '0.3 kV',
          temperatureRange: '-10°C do +60°C',
        ),
        0.8: CableData(
          material: CableMaterial.cu,
          type: CableType.kych,
          crossSection: 0.8,
          coreType: CoreType.re,
          outerDiameter: 7.0,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.telecom,
          maxVoltage: '0.3 kV',
          temperatureRange: '-10°C do +60°C',
        ),
      }
    };
  }

  // JYY - Kabel teletechniczny
  static Map<CableType, Map<double, CableData>> _buildJYY() {
    return {
      CableType.jyy: {
        0.5: CableData(
          material: CableMaterial.cu,
          type: CableType.jyy,
          crossSection: 0.5,
          coreType: CoreType.re,
          outerDiameter: 5.5,
          heatShrinkSleeve: '9/3',
          heatShrinkLabel: '3/1',
          application: CableApplication.telecom,
          maxVoltage: '0.25 kV',
          temperatureRange: '-10°C do +50°C',
        ),
        0.8: CableData(
          material: CableMaterial.cu,
          type: CableType.jyy,
          crossSection: 0.8,
          coreType: CoreType.re,
          outerDiameter: 6.5,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.telecom,
          maxVoltage: '0.25 kV',
          temperatureRange: '-10°C do +50°C',
        ),
      }
    };
  }

  // YQQW - Kabel teletechniczny sygnalizacyjny
  static Map<CableType, Map<double, CableData>> _buildYQQW() {
    return {
      CableType.yqqw: {
        0.5: CableData(
          material: CableMaterial.cu,
          type: CableType.yqqw,
          crossSection: 0.5,
          coreType: CoreType.re,
          outerDiameter: 6.0,
          heatShrinkSleeve: '9/3',
          heatShrinkLabel: '3/1',
          application: CableApplication.telecom,
          maxVoltage: '0.3 kV',
          temperatureRange: '-15°C do +70°C',
        ),
        0.8: CableData(
          material: CableMaterial.cu,
          type: CableType.yqqw,
          crossSection: 0.8,
          coreType: CoreType.re,
          outerDiameter: 7.0,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.telecom,
          maxVoltage: '0.3 kV',
          temperatureRange: '-15°C do +70°C',
        ),
      }
    };
  }

  // YAKY - Kabel aluminiowy
  static Map<CableType, Map<double, CableData>> _buildYAKY() {
    return {
      CableType.yaky: {
        16.0: CableData(
          material: CableMaterial.al,
          type: CableType.yaky,
          crossSection: 16.0,
          coreType: CoreType.sm,
          outerDiameter: 19.0,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        25.0: CableData(
          material: CableMaterial.al,
          type: CableType.yaky,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 23.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        35.0: CableData(
          material: CableMaterial.al,
          type: CableType.yaky,
          crossSection: 35.0,
          coreType: CoreType.sm,
          outerDiameter: 26.0,
          heatShrinkSleeve: '45/15',
          heatShrinkLabel: '25/8',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
      }
    };
  }

  // NA2XY - Kabel aluminiowy XLPE
  static Map<CableType, Map<double, CableData>> _buildNA2XY() {
    return {
      CableType.na2xy: {
        16.0: CableData(
          material: CableMaterial.al,
          type: CableType.na2xy,
          crossSection: 16.0,
          coreType: CoreType.sm,
          outerDiameter: 18.5,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
        25.0: CableData(
          material: CableMaterial.al,
          type: CableType.na2xy,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 22.5,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
        35.0: CableData(
          material: CableMaterial.al,
          type: CableType.na2xy,
          crossSection: 35.0,
          coreType: CoreType.sm,
          outerDiameter: 25.5,
          heatShrinkSleeve: '45/15',
          heatShrinkLabel: '25/8',
          application: CableApplication.power,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
        ),
      }
    };
  }

  // === Metody zapytań ===

  static CableData? getCableData(
    CableMaterial material,
    CableType type,
    double crossSection,
  ) {
    return _data[material]?[type]?[crossSection];
  }

  static List<CableType> getAvailableTypes(CableMaterial material) {
    return _data[material]?.keys.toList() ?? [];
  }

  static List<double> getAvailableCrossSections(
    CableMaterial material,
    CableType type,
  ) {
    return _data[material]?[type]?.keys.toList() ?? [];
  }

  // Nowa metoda: pobierz dostępne zastosowania
  static List<CableApplication> getAvailableApplications() {
    return CableApplication.values;
  }

  // Nowa metoda: filtrowanie po zastosowaniu
  static List<CableType> getTypesByApplication(CableApplication app) {
    final types = <CableType>[];
    for (final materialEntry in _data.entries) {
      for (final typeEntry in materialEntry.value.entries) {
        // Sprawdź pierwsze wpisy każdego typu
        final firstCable = typeEntry.value.values.first;
        if (firstCable.application == app) {
          types.add(typeEntry.key);
        }
      }
    }
    return types.toSet().toList();
  }

  // Nowa metoda: filtrowanie po zastosowaniu i materiale
  static List<CableType> getTypesByApplicationAndMaterial(
    CableApplication app,
    CableMaterial material,
  ) {
    final types = <CableType>[];
    final materialData = _data[material];
    if (materialData != null) {
      for (final typeEntry in materialData.entries) {
        final firstCable = typeEntry.value.values.first;
        if (firstCable.application == app) {
          types.add(typeEntry.key);
        }
      }
    }
    return types;
  }

  // Oblicz rekomendowaną rurę 3:1 na podstawie średnicy kabla
  static String getRecommendedHeatShrink3to1(double outerDiameter) {
    if (outerDiameter <= 6.0) return '9/3';
    if (outerDiameter <= 9.0) return '12/4';
    if (outerDiameter <= 12.0) return '15/5';
    if (outerDiameter <= 15.0) return '18/6';
    if (outerDiameter <= 18.0) return '25/8';
    if (outerDiameter <= 24.0) return '30/10';
    if (outerDiameter <= 32.0) return '40/13';
    if (outerDiameter <= 42.0) return '50/17';
    return '60/20';
  }

  // Oblicz rekomendowaną rurę 2:1 na podstawie średnicy kabla
  static String getRecommendedHeatShrink2to1(double outerDiameter) {
    if (outerDiameter <= 3.0) return '3/1';
    if (outerDiameter <= 4.0) return '4/1.5';
    if (outerDiameter <= 5.0) return '6/2';
    if (outerDiameter <= 7.0) return '8/2.5';
    if (outerDiameter <= 9.0) return '10/3';
    if (outerDiameter <= 11.0) return '12/4';
    if (outerDiameter <= 14.0) return '15/5';
    if (outerDiameter <= 18.0) return '20/6';
    if (outerDiameter <= 23.0) return '25/8';
    return '30/10';
  }
}
