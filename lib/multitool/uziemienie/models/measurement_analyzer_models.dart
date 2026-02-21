// Measurement analyzer for grounding resistance
// Helps engineers correct measured values based on conditions during measurement

/// Conditions that affect grounding resistance measurement
enum SoilTemperature {
  cold(
    'Zimno (<5°C)',
    1.2,
    'Zima, mróz - rezystywność wyższa',
  ),
  cool(
    'Chłodno (5-15°C)',
    1.05,
    'Jesień/wiosna, wczesny poranek',
  ),
  moderate(
    'Normalne (15-25°C)',
    1.0,
    'Standardowe warunki pomiaru',
  ),
  warm(
    'Ciepło (25-35°C)',
    0.95,
    'Lato, ciepły dzień',
  ),
  hot(
    'Gorąco (>35°C)',
    0.90,
    'Bardzo gorący dzień, sucho',
  );

  final String label;
  final double correctionFactor; // mnoż do rezystywności
  final String description;

  const SoilTemperature(this.label, this.correctionFactor, this.description);
}

/// Soil humidity conditions
enum SoilHumidity {
  veryDry(
    'Bardzo sucho',
    5.0,
    'Długa susza, opady nigdy',
    'Rezystywność BARDZO wysoka!',
  ),
  dry(
    'Sucho',
    2.5,
    'Brak opadów przez tydzień',
    'Rezystywność znacznie wyższa',
  ),
  normal(
    'Normalne',
    1.0,
    'Okresowe opady, normalna wilgotność',
    'Standardowe warunki',
  ),
  moist(
    'Wilgotne',
    0.5,
    'Świeże opady, gleba mokra',
    'Rezystywność niższa',
  ),
  saturated(
    'Nasycone (wysoko stół wody)',
    0.2,
    'Podtopienie, wysoki poziom wody gruntowej',
    'Rezystywność BARDZO niska!',
  );

  final String label;
  final double correctionFactor;
  final String description;
  final String colorNote;

  const SoilHumidity(
    this.label,
    this.correctionFactor,
    this.description,
    this.colorNote,
  );
}

/// Seasonal factor (more accurate than month-based)
enum Season {
  winter(
    'Zima (XII-II)',
    2.5,
    'Zamarzniętym grunt, wysoka rezystywność',
  ),
  spring(
    'Wiosna (III-V)',
    1.3,
    'Roztopy, melting snow',
  ),
  summer(
    'Lato (VI-VIII)',
    0.8,
    'Suche warunki, niższa rezystywność',
  ),
  autumn(
    'Jesień (IX-XI)',
    1.2,
    'Zmienne warunki',
  );

  final String label;
  final double correctionFactor;
  final String description;

  const Season(this.label, this.correctionFactor, this.description);

  static Season fromMonth(int month) {
    // 1=Jan, 12=Dec
    if (month >= 12 || month <= 2) return Season.winter;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    return Season.autumn;
  }
}

/// Electrode depth and installation quality
enum ElectrodeInstallation {
  shallow(
    'Płytkie (<1m)',
    1.5,
    'Za wysoko, niska efektywność',
    'Przebiję głębiej, min 1.5-2m',
  ),
  standard(
    'Standardowe (1-2m)',
    1.0,
    'Zgodne z wytycznymi',
    'OK',
  ),
  deep(
    'Głębokie (>2m)',
    0.8,
    'Doszcząetne osadzenie, lepsza rezystancja',
    'Doskonale',
  ),
  notDrivenProperly(
    'Źle osadzone',
    2.0,
    'Wibo drażyć, zły kontakt z gruntem',
    'Przebadać i przefasować',
  );

  final String label;
  final double correctionFactor;
  final String description;
  final String recommendation;

  const ElectrodeInstallation(
    this.label,
    this.correctionFactor,
    this.description,
    this.recommendation,
  );
}

/// Material of electrode
enum ElectrodeMaterial {
  copper(
    'Miedź (Cu)',
    1.0,
    'Najlepsze właściwości, bez korozji',
  ),
  steel(
    'Stal/żelazo (Fe)',
    1.3,
    'Może się okorsować w wilgotnym gruncie',
  ),
  galvanized(
    'Stal ocynkowana',
    1.05,
    'Lepiej chroniona od korozji',
  ),
  aluminum(
    'Aluminium (Al)',
    1.2,
    'Może się tlenić, gorsza przewodność',
  );

  final String label;
  final double correctionFactor;
  final String description;

  const ElectrodeMaterial(
    this.label,
    this.correctionFactor,
    this.description,
  );
}

/// Single measurement record
class GroundingMeasurement {
  final String id;
  final DateTime date;
  final double measuredResistance; // [Ω] - zmierzona wartość
  final SoilTemperature temperature;
  final SoilHumidity humidity;
  final Season season;
  final ElectrodeInstallation installation;
  final ElectrodeMaterial material;
  final int numberOfElectrodes;
  final double spacingBetweenElectrodes; // [m]
  final double electrodeLength; // [m]
  final String location; // lokalizacja na terenie budowy
  final String notes; // dodatkowe uwagi
  final String engineer; // kto wykonał pomiar
  final bool weatherConsiderations; // czy brać pod uwagę pogodę?

  GroundingMeasurement({
    required this.id,
    required this.date,
    required this.measuredResistance,
    required this.temperature,
    required this.humidity,
    required this.season,
    required this.installation,
    required this.material,
    required this.numberOfElectrodes,
    required this.spacingBetweenElectrodes,
    required this.electrodeLength,
    required this.location,
    required this.notes,
    required this.engineer,
    this.weatherConsiderations = true,
  });

  /// Calculate total correction factor
  double getTotalCorrectionFactor() {
    double factor = 1.0;

    // All factors multiply
    factor *= temperature.correctionFactor;
    factor *= humidity.correctionFactor;
    if (weatherConsiderations) {
      factor *= season.correctionFactor;
    }
    factor *= installation.correctionFactor;
    factor *= material.correctionFactor;

    return factor;
  }

  /// Get corrected resistance value
  double getCorrectedResistance() {
    return measuredResistance * getTotalCorrectionFactor();
  }

  /// Get the value as the system was in "perfect conditions" (normalized)
  double getNormalizedResistance() {
    // Normalized to: temperature moderate, humidity normal, summer, standard install, copper
    double factor = getTotalCorrectionFactor();
    // Reverse correction to get normalized value
    return measuredResistance * factor;
  }
}

/// Analysis result of a measurement
class MeasurementAnalysis {
  final GroundingMeasurement measurement;
  final double allowedResistance; // [Ω] - limit for system type
  final String systemType; // TN-S, TN-C-S, TT, etc.

  double get correctedResistance => measurement.getCorrectedResistance();
  double get normalizedResistance => measurement.getNormalizedResistance();
  double get totalCorrectionFactor => measurement.getTotalCorrectionFactor();

  bool get meetsRequirementsAfterCorrection =>
      correctedResistance <= allowedResistance;

  bool get meetsRequirementsAtMeasured =>
      measurement.measuredResistance <= allowedResistance;

  /// Gets the percentage above/below limit
  double getPercentageOfLimit() {
    return (correctedResistance / allowedResistance) * 100;
  }

  /// Get human-readable status
  String getStatus() {
    final percentage = getPercentageOfLimit();

    if (percentage <= 80) {
      return '✅ BEZPIECZNY MARGINES (${percentage.toStringAsFixed(0)}% limitu)';
    } else if (percentage <= 100) {
      return '✔️ SPEŁNIA WYMOGI (${percentage.toStringAsFixed(0)}% limitu)';
    } else if (percentage <= 120) {
      return '⚠️ PRZEKRACZA O (${(percentage - 100).toStringAsFixed(0)}%)';
    } else {
      return '❌ ZNACZNIE PRZEKRACZA (${percentage.toStringAsFixed(0)}% limitu)';
    }
  }

  /// Get recommendations based on analysis
  List<String> getRecommendations() {
    final recommendations = <String>[];

    if (!meetsRequirementsAfterCorrection) {
      recommendations.add(
        'Zmierzona wartość po korekcji: ${correctedResistance.toStringAsFixed(2)} Ω PRZEKRACZA limit ${allowedResistance.toStringAsFixed(2)} Ω',
      );

      // Check which factors contributed most
      if (measurement.humidity == SoilHumidity.veryDry ||
          measurement.humidity == SoilHumidity.dry) {
        recommendations.add(
          '• Gruntę jest SUCHY - czekaj na opady i powtórz pomiar za kilka dni',
        );
      }

      if (measurement.temperature == SoilTemperature.cold ||
          measurement.temperature == SoilTemperature.cool) {
        recommendations.add(
          '• Temperatura niska - poczekaj na ocieplenie i powtórz pomiar',
        );
      }

      if (measurement.installation == ElectrodeInstallation.shallow ||
          measurement.installation == ElectrodeInstallation.notDrivenProperly) {
        recommendations.add(
          '• Elektrody mogą być zbyt płytko - zwiększ głębokość do minimum 2m',
        );
      }

      if (measurement.numberOfElectrodes < 3) {
        recommendations.add(
          '• Zsup liczby elektrod - dodaj co najmniej jedną dodatkową elektrodę',
        );
      }

      recommendations.add(
        '• Alternatywnie: zwiększ przekrój kabla uziemiającego na obliczenia bazując na zmierzonej wartości',
      );
    } else {
      recommendations.add(
        '✅ System SPEŁNIA wymogi. Zmierzona rezystancja: ${measurement.measuredResistance.toStringAsFixed(2)} Ω',
      );
      recommendations.add(
        'Po korekcji warunków: ${correctedResistance.toStringAsFixed(2)} Ω (${getPercentageOfLimit().toStringAsFixed(0)}% limitu)',
      );

      if (getPercentageOfLimit() > 80) {
        recommendations.add(
          '⚠️ Uwaga: Mały margines bezpieczeństwa. Monitoruj rezystancję w sezonie suchym.',
        );
      }
    }

    return recommendations;
  }

  /// Get factors that had largest impact
  List<String> getImpactingFactors() {
    final factors = <String>[];

    if (measurement.temperature.correctionFactor != 1.0) {
      factors.add(
        'Temperatura: x${measurement.temperature.correctionFactor.toStringAsFixed(2)}',
      );
    }
    if (measurement.humidity.correctionFactor != 1.0) {
      factors.add(
        'Wilgotność: x${measurement.humidity.correctionFactor.toStringAsFixed(2)}',
      );
    }
    if (measurement.season.correctionFactor != 1.0 &&
        measurement.weatherConsiderations) {
      factors.add(
        'Sezonowość: x${measurement.season.correctionFactor.toStringAsFixed(2)}',
      );
    }
    if (measurement.installation.correctionFactor != 1.0) {
      factors.add(
        'Osadzenie elektrod: x${measurement.installation.correctionFactor.toStringAsFixed(2)}',
      );
    }
    if (measurement.material.correctionFactor != 1.0) {
      factors.add(
        'Materiał: x${measurement.material.correctionFactor.toStringAsFixed(2)}',
      );
    }

    return factors;
  }

  MeasurementAnalysis({
    required this.measurement,
    required this.allowedResistance,
    required this.systemType,
  });
}

/// Extended analysis compared to previous measurements
class MeasurementComparison {
  final MeasurementAnalysis current;
  final MeasurementAnalysis? previous;

  MeasurementComparison({
    required this.current,
    this.previous,
  });

  bool hasImproved() {
    if (previous == null) return false;
    return current.correctedResistance < previous!.correctedResistance;
  }

  double getDifference() {
    if (previous == null) return 0;
    return current.correctedResistance - previous!.correctedResistance;
  }

  String getDifferencePercentage() {
    if (previous == null) return 'N/A';
    final diff = getDifference();
    final percentage = (diff / previous!.correctedResistance) * 100;
    return percentage.toStringAsFixed(1);
  }

  String getComparison() {
    if (previous == null) {
      return 'Pierwszy pomiar - brak porównania';
    }

    final diff = getDifference();
    if (diff < 0) {
      return '📈 Poprawa: ${(-diff).toStringAsFixed(2)} Ω (${getDifferencePercentage()}%)';
    } else if (diff > 0) {
      return '📉 Pogorszenie: ${diff.toStringAsFixed(2)} Ω (+${getDifferencePercentage()}%)';
    } else {
      return '➡️ Bez zmian';
    }
  }
}
