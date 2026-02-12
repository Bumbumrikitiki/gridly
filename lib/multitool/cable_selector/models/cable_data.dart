enum CableMaterial { cu, al }

enum CableType { ydy, yky, n2xh, nhxh, yaky }

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
        return 'YDY';
      case CableType.yky:
        return 'YKY';
      case CableType.n2xh:
        return 'N2XH';
      case CableType.nhxh:
        return 'NHXH';
      case CableType.yaky:
        return 'YAKY';
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
