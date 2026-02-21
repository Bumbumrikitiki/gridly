enum CableMaterial { cu, al }

enum CableType {
  ydy,
  ydyp,
  yky,
  n2xh,
  nhxh,
  n2xcy,
  ykxs,
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
  });

  final CableMaterial material;
  final CableType type;
  final double crossSection;
  final CoreType coreType;
  final double outerDiameter;
  final String heatShrinkSleeve;
  final String heatShrinkLabel;

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
      case CableType.n2xh:
        return 'N2XH (Cu, bezhalogenowy)';
      case CableType.nhxh:
        return 'NHXH (Cu, bezhalogenowy, CPR)';
      case CableType.n2xcy:
        return 'N2XCY (Cu, ekranowany)';
      case CableType.ykxs:
        return 'YKXS (Cu, XLPE/PVC)';
      case CableType.yaky:
        return 'YAKY (Al, PVC)';
      case CableType.na2xy:
        return 'NA2XY (Al, XLPE/PVC)';
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
