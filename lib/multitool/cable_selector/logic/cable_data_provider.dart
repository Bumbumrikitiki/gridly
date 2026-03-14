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
      ..._buildOMY(),
      ..._buildYKY(),
      ..._buildN2XH(),
      ..._buildHDGS(),
      ..._buildHLGS(),
      ..._buildNHXH(),
      ..._buildHTKSH(),
      ..._buildUTP5E(),
      ..._buildUTP6(),
      ..._buildFUTP6(),
      ..._buildSFTP7(),
      ..._buildRG6(),
      ..._buildRG11(),
      ..._buildYTNKSY(),
      ..._buildLIYY(),
      ..._buildLIYCYEK(),
      ..._buildYSLY(),
      ..._buildBIT500CY(),
      ..._buildH07RNF(),
      ..._buildYHAKXS(),
      ..._buildXHAKXS(),
      ..._buildXRUHAKXS(),
      ..._buildA2XSY(),
    };
  }

  static Map<CableType, Map<double, CableData>> _buildAluminumCables() {
    return {
      ..._buildYAKY(),
      ..._buildNA2XSY(),
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
          application: CableApplication.mediumVoltage,
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
          application: CableApplication.mediumVoltage,
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
          application: CableApplication.mediumVoltage,
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
          application: CableApplication.mediumVoltage,
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
          application: CableApplication.mediumVoltage,
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
          application: CableApplication.electrical,
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
          application: CableApplication.electrical,
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
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
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
          application: CableApplication.electrical,
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
          application: CableApplication.electrical,
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
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
      }
    };
  }

  // NA2XSY - Kabel aluminiowy XLPE średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildNA2XSY() {
    return {
      CableType.na2xsy: {
        120.0: CableData(
          material: CableMaterial.al,
          type: CableType.na2xsy,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 48.0,
          heatShrinkSleeve: '70/25',
          heatShrinkLabel: '40/13',
          application: CableApplication.electrical,
          maxVoltage: '18/30 kV',
          temperatureRange: '-40°C do +90°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      }
    };
  }

  // OMY / OWY - Przewód warsztatowy
  static Map<CableType, Map<double, CableData>> _buildOMY() {
    return {
      CableType.omy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.omy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.4,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.electrical,
          maxVoltage: '450/750V',
          temperatureRange: '-30°C do +70°C',
          groupNumber: 1,
        ),
      },
    };
  }

  // HDGS - Kabel pożarowy
  static Map<CableType, Map<double, CableData>> _buildHDGS() {
    return {
      CableType.hdgs: {
        1.0: CableData(
          material: CableMaterial.cu,
          type: CableType.hdgs,
          crossSection: 1.0,
          coreType: CoreType.re,
          outerDiameter: 7.8,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.hdgs,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.4,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // HLGS - Kabel pożarowy
  static Map<CableType, Map<double, CableData>> _buildHLGS() {
    return {
      CableType.hlgs: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.hlgs,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.9,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // NHXH E90 - Kabel pożarowy
  static Map<CableType, Map<double, CableData>> _buildNHXH() {
    return {
      CableType.nhxh: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nhxh,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 15.5,
          heatShrinkSleeve: '24/8',
          heatShrinkLabel: '8/3',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // HTKSH - Kabel pożarowy ekranowany
  static Map<CableType, Map<double, CableData>> _buildHTKSH() {
    return {
      CableType.htksh: {
        0.8: CableData(
          material: CableMaterial.cu,
          type: CableType.htksh,
          crossSection: 0.8,
          coreType: CoreType.re,
          outerDiameter: 6.2,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.fireproof,
          maxVoltage: '300V',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // U/UTP 5e - Kabel sieciowy
  static Map<CableType, Map<double, CableData>> _buildUTP5E() {
    return {
      CableType.utp5e: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.utp5e,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 5.2,
          heatShrinkSleeve: '6/2',
          heatShrinkLabel: '3/1',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // U/UTP 6 - Kabel sieciowy
  static Map<CableType, Map<double, CableData>> _buildUTP6() {
    return {
      CableType.utp6: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.utp6,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 6.3,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // F/UTP 6 - Kabel sieciowy ekranowany
  static Map<CableType, Map<double, CableData>> _buildFUTP6() {
    return {
      CableType.futp6: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.futp6,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 7.2,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // S/FTP 7 - Kabel sieciowy ekranowany podwójnie
  static Map<CableType, Map<double, CableData>> _buildSFTP7() {
    return {
      CableType.sftp7: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.sftp7,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 7.8,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // RG6 - Kabel koaksjalny SAT
  static Map<CableType, Map<double, CableData>> _buildRG6() {
    return {
      CableType.rg6: {
        75.0: CableData(
          material: CableMaterial.cu,
          type: CableType.rg6,
          crossSection: 75.0,
          coreType: CoreType.sm,
          outerDiameter: 6.8,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-40°C do +70°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // RG11 - Kabel koaksjalny SAT
  static Map<CableType, Map<double, CableData>> _buildRG11() {
    return {
      CableType.rg11: {
        75.0: CableData(
          material: CableMaterial.cu,
          type: CableType.rg11,
          crossSection: 75.0,
          coreType: CoreType.sm,
          outerDiameter: 10.3,
          heatShrinkSleeve: '19.1/9.5',
          heatShrinkLabel: '9.5/4.8',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-40°C do +70°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // YnTKSY - Kabel teletechniczny
  static Map<CableType, Map<double, CableData>> _buildYTNKSY() {
    return {
      CableType.ytnksy: {
        0.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ytnksy,
          crossSection: 0.5,
          coreType: CoreType.re,
          outerDiameter: 4.2,
          heatShrinkSleeve: '6/2',
          heatShrinkLabel: '3/1',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-20°C do +70°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // LiYY - Kabel sterowniczy
  static Map<CableType, Map<double, CableData>> _buildLIYY() {
    return {
      CableType.liyy: {
        0.5: CableData(
          material: CableMaterial.cu,
          type: CableType.liyy,
          crossSection: 0.5,
          coreType: CoreType.re,
          outerDiameter: 4.8,
          heatShrinkSleeve: '6/2',
          heatShrinkLabel: '3/1',
          application: CableApplication.control,
          maxVoltage: '300/500V',
          temperatureRange: '-20°C do +70°C',
          wireConfiguration: WireConfiguration.twoWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // LiYCY ekranowany - Kabel sterowniczy ekranowany
  static Map<CableType, Map<double, CableData>> _buildLIYCYEK() {
    return {
      CableType.liycyekaprn: {
        0.75: CableData(
          material: CableMaterial.cu,
          type: CableType.liycyekaprn,
          crossSection: 0.75,
          coreType: CoreType.re,
          outerDiameter: 6.2,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.control,
          maxVoltage: '300/500V',
          temperatureRange: '-20°C do +70°C',
          wireConfiguration: WireConfiguration.twoWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // YSLY / JZ-500 - Kabel sterowniczy
  static Map<CableType, Map<double, CableData>> _buildYSLY() {
    return {
      CableType.ysly: {
        1.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ysly,
          crossSection: 1.0,
          coreType: CoreType.re,
          outerDiameter: 6.5,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.control,
          maxVoltage: '300V',
          temperatureRange: '-30°C do +70°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // BiT 500 CY - Kabel sterowniczy ekranowany
  static Map<CableType, Map<double, CableData>> _buildBIT500CY() {
    return {
      CableType.bit500cy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.bit500cy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 9.2,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.control,
          maxVoltage: '300V',
          temperatureRange: '-20°C do +70°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // H07RN-F - Kabel gumowy OnPD
  static Map<CableType, Map<double, CableData>> _buildH07RNF() {
    return {
      CableType.h07rnf: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.h07rnf,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 10.5,
          heatShrinkSleeve: '19.1/9.5',
          heatShrinkLabel: '9.5/4.8',
          application: CableApplication.industrial,
          maxVoltage: '450/750V',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // YHAKXS - Kabel średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildYHAKXS() {
    return {
      CableType.yhakxs: {
        35.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yhakxs,
          crossSection: 35.0,
          coreType: CoreType.sm,
          outerDiameter: 26.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '19.1/9.5',
          application: CableApplication.electrical,
          maxVoltage: '12/20 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
    };
  }

  // XHAKXS - Kabel średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildXHAKXS() {
    return {
      CableType.xhakxs: {
        120.0: CableData(
          material: CableMaterial.cu,
          type: CableType.xhakxs,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 34.0,
          heatShrinkSleeve: '55/15',
          heatShrinkLabel: '24.0/8',
          application: CableApplication.electrical,
          maxVoltage: '12/20 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
    };
  }

  // XRUHAKXS - Kabel średnie napięcie pancerz
  static Map<CableType, Map<double, CableData>> _buildXRUHAKXS() {
    return {
      CableType.xruhakxs: {
        120.0: CableData(
          material: CableMaterial.cu,
          type: CableType.xruhakxs,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 38.0,
          heatShrinkSleeve: '55/15',
          heatShrinkLabel: '24.0/8',
          application: CableApplication.electrical,
          maxVoltage: '12/20 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
    };
  }

  // A2XSY - Kabel średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildA2XSY() {
    return {
      CableType.a2xsy: {
        120.0: CableData(
          material: CableMaterial.cu,
          type: CableType.a2xsy,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 43.0,
          heatShrinkSleeve: '55/15',
          heatShrinkLabel: '24.0/8',
          application: CableApplication.electrical,
          maxVoltage: '18/30 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
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
    final apps = <CableApplication>{};
    for (final materialEntry in _data.entries) {
      for (final typeEntry in materialEntry.value.entries) {
        final firstCable = typeEntry.value.values.first;
        apps.add(firstCable.application);
      }
    }

    final result = apps.toList();
    result.sort((a, b) => a.index.compareTo(b.index));
    return result;
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

  // Sugestia standardu rury na podstawie warunków pracy
  static HeatShrinkStandard suggestTubeStandardForCondition(
    WorkingCondition condition,
  ) {
    return CableData.suggestTubeStandard(condition);
  }

  // Pobierz sugerowane rury na podstawie średnicy kabla i warunku
  static List<HeatShrinkTube> suggestTubesForCable(
    double cableDiameter,
    WorkingCondition condition,
  ) {
    final standard = CableData.suggestTubeStandard(condition);
    return CableData.suggestTubesForCableDiameter(cableDiameter, standard);
  }

  // Sugerowane srednice rur sztywnych (orientacyjnie) dla pojedynczego kabla.
  // Przyjeto zapas montazowy ok. 30% srednicy zewnetrznej kabla.
  static List<int> suggestRigidConduitDiameters(double outerDiameter) {
    const standardDiameters = <int>[16, 20, 25, 32, 40, 50, 63, 75, 90, 110];
    final minimum = outerDiameter * 1.3;
    final fits = standardDiameters.where((d) => d >= minimum).toList();
    return fits.take(3).toList();
  }

  // Pobierz dostępne warianty warunków pracy
  static List<WorkingCondition> getAvailableWorkingConditions() {
    return WorkingCondition.values;
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
