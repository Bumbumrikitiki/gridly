enum CableMaterial { cu, al }

enum CableApplication {
  electrical,    // Elektryczne (instalacyjne)
  fireproof,     // Pożaroodporne
  control,       // Sterownicze
  telecom,       // Teletechniczne
  power,         // Zasilające (energetyczne)
  industrial,    // Przemysłowe
}

enum CableType {
  // Grupa 1: Elektryczne i instalacyjne (nN 450/750V)
  ydy,          // YDY (okrągły Cu, PVC)
  ydyp,         // YDYp (płaski Cu, PVC)
  omy,          // OMY / OWY (warsztatowe)
  
  // Grupa 2: Zasilające i ziemne (0.6/1kV)
  yky,          // YKY (Cu, PVC)
  yaky,         // YAKY (Al, PVC)
  n2xh,         // N2XH (Cu, bezhalogenowy)
  
  // Grupa 3: Pożarowe i bezpieczeństwa (E90/PH90)
  hdgs,         // HDGs (pożarowy)
  hlgs,         // HLGs (pożarowy)
  nhxh,         // NHXH E90 (pożarowy, CPR)
  htksh,        // HTKSH (pożarowy, ekranowany)
  
  // Grupa 4: Teletechniczne i DATA
  utp5e,        // U/UTP 5e (LAN)
  utp6,         // U/UTP 6 (LAN)
  futp6,        // F/UTP 6 (ekranowany)
  sftp7,        // S/FTP 7 (podwójny ekran)
  rg6,          // RG6 (koncentryczny SAT)
  rg11,         // RG11 (koncentryczny SAT)
  ytnksy,       // YnTKSY (teletechniczny)
  xztkmxpwz,    // XzTKMXpwZ (światłowód)
  
  // Grupa 5: Sterownicze i przemysłowe
  liyy,         // LiYY (sterowniczy)
  liycyekaprn,  // LiYCY ekranowany
  ysly,         // YSLY / JZ-500 (sterowniczy)
  bit500cy,     // BiT 500 CY (ekranowany)
  h07rnf,       // H07RN-F (OnPD, guma)
  
  // Grupa 6: Średnie napięcie (12/20kV, 18/30kV)
  yhakxs,       // YHAKXS (Al, XLPE)
  xhakxs,       // XHAKXS (Cu, XLPE)
  xruhakxs,     // XRUHAKXS (Cu, XLPE, pancerz)
  a2xsy,        // A2XSY (Al, XLPE)
  na2xsy,       // NA2XSY (Al, XLPE, bezhalogen)
}

enum CoreType { re, sm }

enum WireConfiguration {
  single,       // Pojedyncza żyła
  pair,         // Para
  twoWire,      // 2 żyły
  threeWire,    // 3 żyły
  fourWire,     // 4 żyły
  fiveWire,     // 5 żyły
  sevenWire,    // 7 żył
  twelvWire,    // 12 żył
  twentyFiveWire, // 25 żył
}

enum WorkingCondition {
  interior,         // Wnętrze / szafa / puszka
  humid,           // Wilgoć / agresywne środowisko
  ground,          // Ziemia / przyłącze / SN / duże siły
}

enum HeatShrinkStandard {
  rc,   // Cienkościenne (bez kleju) 2:1
  rck,  // Cienkościenne z klejem 3:1 / 4:1
  rgk,  // Grubościenne z klejem 3:1 / 4:1
}

class HeatShrinkTube {
  const HeatShrinkTube({
    required this.standard,
    required this.beforeDiameter,
    required this.afterDiameter,
    required this.minCableDiameter,
    required this.maxCableDiameter,
    required this.shrinkRatio,
    required this.description,
  });

  final HeatShrinkStandard standard;
  final double beforeDiameter;
  final double afterDiameter;
  final double minCableDiameter;
  final double maxCableDiameter;
  final double shrinkRatio; // 2:1, 3:1, 4:1
  final String description;

  static String standardToString(HeatShrinkStandard std) {
    switch (std) {
      case HeatShrinkStandard.rc:
        return 'RC (Cienkościenna bez kleju, 2:1)';
      case HeatShrinkStandard.rck:
        return 'RCK (Cienkościenna z klejem, 3:1/4:1)';
      case HeatShrinkStandard.rgk:
        return 'RGK (Grubościenna z klejem, 3:1/4:1)';
    }
  }
}

class CableData {
  const CableData({
    required this.material,
    required this.type,
    required this.crossSection,
    required this.coreType,
    required this.outerDiameter,
    required this.heatShrinkSleeve,
    required this.heatShrinkLabel,
    required this.application,
    required this.maxVoltage,
    required this.temperatureRange,
    this.wireConfiguration = WireConfiguration.single,
    this.groupNumber = 1,
    this.recommendedTubeStandard = HeatShrinkStandard.rck,
  });

  final CableMaterial material;
  final CableType type;
  final double crossSection;
  final CoreType coreType;
  final double outerDiameter;
  final String heatShrinkSleeve;
  final String heatShrinkLabel;
  final CableApplication application;
  final String maxVoltage;
  final String temperatureRange;
  final WireConfiguration wireConfiguration;
  final int groupNumber; // 1-6 grupy
  final HeatShrinkStandard recommendedTubeStandard;

  static String materialToString(CableMaterial material) {
    return material == CableMaterial.cu ? 'Cu' : 'Al';
  }

  static String typeToString(CableType type) {
    switch (type) {
      // Grupa 1: Elektryczne
      case CableType.ydy:
        return 'YDY (Cu, PVC, okrągły)';
      case CableType.ydyp:
        return 'YDYp (Cu, PVC, płaski)';
      case CableType.omy:
        return 'OMY / OWY (Cu, warsztatowy)';
      
      // Grupa 2: Zasilające i ziemne
      case CableType.yky:
        return 'YKY (Cu, PVC, ziemny)';
      case CableType.yaky:
        return 'YAKY (Al, PVC, ziemny)';
      case CableType.n2xh:
        return 'N2XH (Cu, bezhalogenowy)';
      
      // Grupa 3: Pożarowe
      case CableType.hdgs:
        return 'HDGs (pożarowy Si)';
      case CableType.hlgs:
        return 'HLGs (pożarowy Si)';
      case CableType.nhxh:
        return 'NHXH E90 (pożarowy CPR)';
      case CableType.htksh:
        return 'HTKSH (pożarowy ekranowany)';
      
      // Grupa 4: Teletechniczne
      case CableType.utp5e:
        return 'U/UTP 5e (LAN Cat.5e)';
      case CableType.utp6:
        return 'U/UTP 6 (LAN Cat.6)';
      case CableType.futp6:
        return 'F/UTP 6 (LAN ekranowany)';
      case CableType.sftp7:
        return 'S/FTP 7 (LAN podwójny ekran)';
      case CableType.rg6:
        return 'RG6 (SAT koncentryczny)';
      case CableType.rg11:
        return 'RG11 (SAT koncentryczny)';
      case CableType.ytnksy:
        return 'YnTKSY (telecom)';
      case CableType.xztkmxpwz:
        return 'XzTKMXpwZ (światłowód)';
      
      // Grupa 5: Sterownicze
      case CableType.liyy:
        return 'LiYY (sterowniczy)';
      case CableType.liycyekaprn:
        return 'LiYCY (sterowniczy ekranowany)';
      case CableType.ysly:
        return 'YSLY / JZ-500 (sterowniczy)';
      case CableType.bit500cy:
        return 'BiT 500 CY (sterowniczy ekranowany)';
      case CableType.h07rnf:
        return 'H07RN-F (gumowy, OnPD)';
      
      // Grupa 6: Średnie napięcie
      case CableType.yhakxs:
        return 'YHAKXS (Al, XLPE, SN)';
      case CableType.xhakxs:
        return 'XHAKXS (Cu, XLPE, SN)';
      case CableType.xruhakxs:
        return 'XRUHAKXS (Cu, pancerz, SN)';
      case CableType.a2xsy:
        return 'A2XSY (Al, XLPE)';
      case CableType.na2xsy:
        return 'NA2XSY (Al, bezhalogen)';
    }
  }

  static String wireConfigToString(WireConfiguration config) {
    switch (config) {
      case WireConfiguration.single:
        return '1 żyła';
      case WireConfiguration.pair:
        return 'Para (2x)';
      case WireConfiguration.twoWire:
        return '2 żyły';
      case WireConfiguration.threeWire:
        return '3 żyły';
      case WireConfiguration.fourWire:
        return '4 żyły';
      case WireConfiguration.fiveWire:
        return '5 żył';
      case WireConfiguration.sevenWire:
        return '7 żył';
      case WireConfiguration.twelvWire:
        return '12 żył';
      case WireConfiguration.twentyFiveWire:
        return '25 żył';
    }
  }

  static String workingConditionToString(WorkingCondition condition) {
    switch (condition) {
      case WorkingCondition.interior:
        return 'Wnętrze / Szafa / Puszka';
      case WorkingCondition.humid:
        return 'Wilgoć / Agresywne środowisko';
      case WorkingCondition.ground:
        return 'Ziemia / Przyłącze / SN / Duże siły';
    }
  }

  static String applicationToString(CableApplication app) {
    switch (app) {
      case CableApplication.electrical:
        return 'Elektryczne';
      case CableApplication.fireproof:
        return 'Pożarowe';
      case CableApplication.control:
        return 'Sterownicze';
      case CableApplication.telecom:
        return 'Teletechniczne';
      case CableApplication.power:
        return 'Zasilające';
      case CableApplication.industrial:
        return 'Przemysłowe';
    }
  }

  static String coreTypeToString(CoreType type) {
    switch (type) {
      case CoreType.re:
        return 'RE (okrągła)';
      case CoreType.sm:
        return 'SM (sektorowa)';
    }
  }

  // Wybór typu rury bazo wany na warunkach pracy
  static HeatShrinkStandard suggestTubeStandard(WorkingCondition condition) {
    switch (condition) {
      case WorkingCondition.interior:
        return HeatShrinkStandard.rc; // Cienkościenne bez kleju
      case WorkingCondition.humid:
        return HeatShrinkStandard.rck; // Cienkościenne z klejem
      case WorkingCondition.ground:
        return HeatShrinkStandard.rgk; // Grubościenne z klejem
    }
  }

  // Sugestia rury termokurczliwej na podstawie średnicy kabla
  static List<HeatShrinkTube> suggestTubesForCableDiameter(
    double cableDiameter,
    HeatShrinkStandard standard,
  ) {
    // Mapa rur dla każdego standardu
    const rcTubes = [
      HeatShrinkTube(
        standard: HeatShrinkStandard.rc,
        beforeDiameter: 2.4,
        afterDiameter: 1.2,
        minCableDiameter: 1.3,
        maxCableDiameter: 2.0,
        shrinkRatio: 2.0,
        description: 'RC 2.4/1.2',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rc,
        beforeDiameter: 4.8,
        afterDiameter: 2.4,
        minCableDiameter: 2.5,
        maxCableDiameter: 4.0,
        shrinkRatio: 2.0,
        description: 'RC 4.8/2.4',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rc,
        beforeDiameter: 9.5,
        afterDiameter: 4.8,
        minCableDiameter: 5.0,
        maxCableDiameter: 8.0,
        shrinkRatio: 2.0,
        description: 'RC 9.5/4.8',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rc,
        beforeDiameter: 19.1,
        afterDiameter: 9.5,
        minCableDiameter: 10.0,
        maxCableDiameter: 16.0,
        shrinkRatio: 2.0,
        description: 'RC 19.1/9.5',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rc,
        beforeDiameter: 38.1,
        afterDiameter: 19.1,
        minCableDiameter: 20.0,
        maxCableDiameter: 32.0,
        shrinkRatio: 2.0,
        description: 'RC 38.1/19.1',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rc,
        beforeDiameter: 76.2,
        afterDiameter: 38.1,
        minCableDiameter: 40.0,
        maxCableDiameter: 65.0,
        shrinkRatio: 2.0,
        description: 'RC 76.2/38.1',
      ),
    ];

    const rckTubes = [
      HeatShrinkTube(
        standard: HeatShrinkStandard.rck,
        beforeDiameter: 3.0,
        afterDiameter: 1.0,
        minCableDiameter: 1.1,
        maxCableDiameter: 2.5,
        shrinkRatio: 3.0,
        description: 'RCK 3/1 z klejem',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rck,
        beforeDiameter: 6.0,
        afterDiameter: 2.0,
        minCableDiameter: 2.1,
        maxCableDiameter: 5.0,
        shrinkRatio: 3.0,
        description: 'RCK 6/2 z klejem',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rck,
        beforeDiameter: 12.0,
        afterDiameter: 4.0,
        minCableDiameter: 4.2,
        maxCableDiameter: 10.0,
        shrinkRatio: 3.0,
        description: 'RCK 12/4 z klejem',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rck,
        beforeDiameter: 24.0,
        afterDiameter: 8.0,
        minCableDiameter: 8.5,
        maxCableDiameter: 20.0,
        shrinkRatio: 3.0,
        description: 'RCK 24/8 z klejem',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rck,
        beforeDiameter: 40.0,
        afterDiameter: 13.0,
        minCableDiameter: 14.0,
        maxCableDiameter: 33.0,
        shrinkRatio: 3.0,
        description: 'RCK 40/13 z klejem',
      ),
    ];

    const rgkTubes = [
      HeatShrinkTube(
        standard: HeatShrinkStandard.rgk,
        beforeDiameter: 13.0,
        afterDiameter: 4.0,
        minCableDiameter: 5.0,
        maxCableDiameter: 11.0,
        shrinkRatio: 3.0,
        description: 'RGK 13/4 grubościenna',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rgk,
        beforeDiameter: 33.0,
        afterDiameter: 8.0,
        minCableDiameter: 10.0,
        maxCableDiameter: 28.0,
        shrinkRatio: 3.0,
        description: 'RGK 33/8 grubościenna',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rgk,
        beforeDiameter: 55.0,
        afterDiameter: 15.0,
        minCableDiameter: 18.0,
        maxCableDiameter: 47.0,
        shrinkRatio: 3.0,
        description: 'RGK 55/15 grubościenna',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rgk,
        beforeDiameter: 95.0,
        afterDiameter: 25.0,
        minCableDiameter: 30.0,
        maxCableDiameter: 80.0,
        shrinkRatio: 3.0,
        description: 'RGK 95/25 grubościenna',
      ),
      HeatShrinkTube(
        standard: HeatShrinkStandard.rgk,
        beforeDiameter: 130.0,
        afterDiameter: 36.0,
        minCableDiameter: 45.0,
        maxCableDiameter: 110.0,
        shrinkRatio: 3.0,
        description: 'RGK 130/36 grubościenna',
      ),
    ];

    List<HeatShrinkTube> allTubes = [];
    if (standard == HeatShrinkStandard.rc) {
      allTubes = rcTubes;
    } else if (standard == HeatShrinkStandard.rck) {
      allTubes = rckTubes;
    } else {
      allTubes = rgkTubes;
    }

    // Filtruj rurki pasujące do średnicy kabla z 20% zapasem
    final adjustedMin = cableDiameter * 0.8;
    final adjustedMax = cableDiameter * 1.2;

    return allTubes
        .where((tube) =>
            tube.maxCableDiameter >= adjustedMin &&
            tube.minCableDiameter <= adjustedMax)
        .toList();
  }
}

