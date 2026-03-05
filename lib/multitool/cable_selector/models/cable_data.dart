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
  // Miedziepne elektryczne
  ydy,
  ydyp,
  yky,
  ykxs,
  
  // Pożaroodporne
  n2xh,
  nhxh,
  ntscgefloxcy,
  nsgafougefloxcy,
  
  // Ekranowane
  n2xcy,
  nycy,
  
  // Sterownicze
  lflex,
  
  // Skrętki
  kych,
  
  // Teletechniczne
  jyy,
  yqqw,
  
  // Aluminiowe
  yaky,
  na2xy,
}

enum CoreType { re, sm }

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

  static String materialToString(CableMaterial material) {
    return material == CableMaterial.cu ? 'Cu' : 'Al';
  }

  static String typeToString(CableType type) {
    switch (type) {
      case CableType.ydy:
        return 'YDY (Cu, PVC)';
      case CableType.ydyp:
        return 'YDYp (płaski, Cu, PVC)';
      case CableType.yky:
        return 'YKY (Cu, PVC, ziemny)';
      case CableType.ykxs:
        return 'YKXS (Cu, XLPE/PVC)';
      case CableType.n2xh:
        return 'N2XH (Cu, bezhalogenowy)';
      case CableType.nhxh:
        return 'NHXH (Cu, pożarowy, CPR)';
      case CableType.ntscgefloxcy:
        return 'NTSCGEFLOXCY (pożarowy, ekr.)';
      case CableType.nsgafougefloxcy:
        return 'NSGAFOUGEFLOXCY (pożarowy)';
      case CableType.n2xcy:
        return 'N2XCY (Cu, ekranowany)';
      case CableType.nycy:
        return 'NYCY (Cu, ekranowany PVC)';
      case CableType.lflex:
        return 'LFLEX (sterowniczy)';
      case CableType.kych:
        return 'KYCh (skrętka, Cu)';
      case CableType.jyy:
        return 'JYY (teletechniczny)';
      case CableType.yqqw:
        return 'YQQW (teletechniczny)';
      case CableType.yaky:
        return 'YAKY (Al, PVC)';
      case CableType.na2xy:
        return 'NA2XY (Al, XLPE/PVC)';
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
}
