import 'dart:math';

class EngineeringCalculators {
  /// Oblicza spadek napięcia dla obwodu jednofazowego
  /// dU = (200 * P * L) / (γ * S * U²)
  static double calculateVoltageDrop1Phase({
    required double powerKw,
    required double lengthM,
    required double crossSectionMm2,
    required double voltageV,
    required bool isCopper,
  }) {
    final gamma = isCopper ? 56.0 : 34.0;
    return (200 * powerKw * lengthM) /
        (gamma * crossSectionMm2 * voltageV * voltageV);
  }

  /// Oblicza spadek napięcia dla obwodu trójfazowego
  /// dU = (100 * P * L) / (γ * S * U²)
  static double calculateVoltageDrop3Phase({
    required double powerKw,
    required double lengthM,
    required double crossSectionMm2,
    required double voltageV,
    required bool isCopper,
  }) {
    final gamma = isCopper ? 56.0 : 34.0;
    return (100 * powerKw * lengthM) /
        (gamma * crossSectionMm2 * voltageV * voltageV);
  }

  /// Oblicza prąd zwarcia: Ik = U / Zs
  static double calculateShortCircuitCurrent({
    required double voltageV,
    required double impedanceOhm,
  }) {
    if (impedanceOhm == 0) return 0;
    return voltageV / impedanceOhm;
  }

  /// Zwraca wymaganą wytrzymałość osprzętu na podstawie prądu zwarcia
  static String getRequiredStrength(double shortCircuitCurrentA) {
    if (shortCircuitCurrentA < 6000) {
      return '6kA';
    } else if (shortCircuitCurrentA < 10000) {
      return '10kA';
    } else {
      return '25kA';
    }
  }

  /// Szereg prądów znamionowych zabezpieczeń
  static const List<double> nominalCurrents = [
    6,
    10,
    13,
    16,
    20,
    25,
    32,
    40,
    50,
    63,
  ];

  /// Minimalne przekroje kabli dla poszczególnych prądów (Cu)
  static final Map<double, double> minCrossSectionCu = {
    6: 1.5,
    10: 1.5,
    13: 2.5,
    16: 2.5,
    20: 4.0,
    25: 4.0,
    32: 6.0,
    40: 10.0,
    50: 10.0,
    63: 16.0,
  };

  /// Minimalne przekroje kabli dla poszczególnych prądów (Al)
  static final Map<double, double> minCrossSectionAl = {
    6: 2.5,
    10: 2.5,
    13: 4.0,
    16: 4.0,
    20: 6.0,
    25: 6.0,
    32: 10.0,
    40: 16.0,
    50: 16.0,
    63: 25.0,
  };

  /// Dobiera zabezpieczenie na podstawie mocy
  static ProtectionResult selectProtection({
    required double powerKw,
    required double voltageV,
    required bool isThreePhase,
    required bool isCopper,
  }) {
    // Oblicz prąd obliczeniowy
    final current = isThreePhase
        ? (powerKw * 1000) / (sqrt(3) * voltageV)
        : (powerKw * 1000) / voltageV;

    // Znajdź najbliższy wyższy prąd znamionowy
    double selectedIn = nominalCurrents.first;
    for (final in_ in nominalCurrents) {
      if (in_ >= current) {
        selectedIn = in_;
        break;
      }
    }

    // Dobierz minimalny przekrój
    final crossSectionMap = isCopper ? minCrossSectionCu : minCrossSectionAl;
    final minCrossSection = crossSectionMap[selectedIn] ?? 1.5;

    return ProtectionResult(
      calculatedCurrent: current,
      nominalCurrent: selectedIn,
      minCrossSection: minCrossSection,
      material: isCopper ? 'Cu' : 'Al',
    );
  }
}

class ProtectionResult {
  const ProtectionResult({
    required this.calculatedCurrent,
    required this.nominalCurrent,
    required this.minCrossSection,
    required this.material,
  });

  final double calculatedCurrent;
  final double nominalCurrent;
  final double minCrossSection;
  final String material;
}
