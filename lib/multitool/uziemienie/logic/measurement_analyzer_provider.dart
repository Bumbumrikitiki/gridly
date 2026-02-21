import 'package:flutter/foundation.dart';
import 'package:gridly/multitool/uziemienie/models/measurement_analyzer_models.dart';
import 'package:uuid/uuid.dart';

/// Manager for grounding resistance measurements and analysis
class MeasurementAnalyzerProvider extends ChangeNotifier {
  List<GroundingMeasurement> _measurements = [];
  MeasurementAnalysis? _currentAnalysis;
  MeasurementComparison? _comparison;
  String? _errorMessage;

  List<GroundingMeasurement> get measurements => _measurements;
  MeasurementAnalysis? get currentAnalysis => _currentAnalysis;
  MeasurementComparison? get comparison => _comparison;
  String? get errorMessage => _errorMessage;

  /// Add a new measurement
  Future<void> addMeasurement({
    required double measuredResistance,
    required SoilTemperature temperature,
    required SoilHumidity humidity,
    required Season season,
    required ElectrodeInstallation installation,
    required ElectrodeMaterial material,
    required int numberOfElectrodes,
    required double spacingBetweenElectrodes,
    required double electrodeLength,
    required String location,
    required String notes,
    required String engineer,
    required double allowedResistance,
    required String systemType,
    bool weatherConsiderations = true,
  }) async {
    try {
      _errorMessage = null;

      final measurement = GroundingMeasurement(
        id: const Uuid().v4(),
        date: DateTime.now(),
        measuredResistance: measuredResistance,
        temperature: temperature,
        humidity: humidity,
        season: season,
        installation: installation,
        material: material,
        numberOfElectrodes: numberOfElectrodes,
        spacingBetweenElectrodes: spacingBetweenElectrodes,
        electrodeLength: electrodeLength,
        location: location,
        notes: notes,
        engineer: engineer,
        weatherConsiderations: weatherConsiderations,
      );

      _measurements.add(measurement);

      // Perform analysis
      _currentAnalysis = MeasurementAnalysis(
        measurement: measurement,
        allowedResistance: allowedResistance,
        systemType: systemType,
      );

      // Compare with previous if exists
      if (_measurements.length > 1) {
        final previousMeasurement = _measurements[_measurements.length - 2];
        final previousAnalysis = MeasurementAnalysis(
          measurement: previousMeasurement,
          allowedResistance: allowedResistance,
          systemType: systemType,
        );
        _comparison = MeasurementComparison(
          current: _currentAnalysis!,
          previous: previousAnalysis,
        );
      } else {
        _comparison = MeasurementComparison(
          current: _currentAnalysis!,
          previous: null,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Błąd podczas dodawania pomiaru: $e';
      notifyListeners();
    }
  }

  /// Get measurement by ID
  GroundingMeasurement? getMeasurement(String id) {
    try {
      return _measurements.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all measurements for a specific location
  List<GroundingMeasurement> getMeasurementsForLocation(String location) {
    return _measurements.where((m) => m.location == location).toList();
  }

  /// Get measurement history (sorted by date, newest first)
  List<GroundingMeasurement> getHistory() {
    final sorted = [..._measurements];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Delete measurement
  void deleteMeasurement(String id) {
    _measurements.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  /// Get average resistance over time
  double getAverageResistance() {
    if (_measurements.isEmpty) return 0;
    final sum =
        _measurements.fold<double>(0, (sum, m) => sum + m.measuredResistance);
    return sum / _measurements.length;
  }

  /// Get trend (improving or deteriorating)
  String getTrend() {
    if (_measurements.length < 2) return 'Brak tłedu (potrzeba min 2 pomiarów)';

    final recent = _measurements.sublist(
      (_measurements.length - 3).clamp(0, _measurements.length),
    );
    final oldAvg =
        _measurements.sublist(0, (_measurements.length ~/ 2).clamp(1, _measurements.length))
            .fold<double>(0, (sum, m) => sum + m.measuredResistance) /
        (_measurements.length ~/ 2).clamp(1, _measurements.length);
    final recentAvg = recent.fold<double>(0, (sum, m) => sum + m.measuredResistance) /
        recent.length;

    if (recentAvg < oldAvg * 0.9) {
      return '📈 Poprawa (~${((1 - recentAvg / oldAvg) * 100).toStringAsFixed(0)}%)';
    } else if (recentAvg > oldAvg * 1.1) {
      return '📉 Pogorszenie (~${((recentAvg / oldAvg - 1) * 100).toStringAsFixed(0)}%)';
    } else {
      return '➡️ Bez zmian';
    }
  }

  /// Export measurement as JSON
  Map<String, dynamic> exportMeasurementAsJson(String id) {
    final measurement = getMeasurement(id);
    if (measurement == null) return {};

    return {
      'id': measurement.id,
      'date': measurement.date.toIso8601String(),
      'measuredResistance': measurement.measuredResistance,
      'temperature': measurement.temperature.label,
      'humidity': measurement.humidity.label,
      'season': measurement.season.label,
      'installation': measurement.installation.label,
      'material': measurement.material.label,
      'numberOfElectrodes': measurement.numberOfElectrodes,
      'spacingBetweenElectrodes': measurement.spacingBetweenElectrodes,
      'electrodeLength': measurement.electrodeLength,
      'location': measurement.location,
      'notes': measurement.notes,
      'engineer': measurement.engineer,
    };
  }

  /// Export full report
  String exportFullReport(String id) {
    final measurement = getMeasurement(id);
    if (measurement == null) return 'Pomiar nie znaleziony';

    final analysis = MeasurementAnalysis(
      measurement: measurement,
      allowedResistance: 1.0,
      systemType: 'TN-S',
    );

    final buffer = StringBuffer();
    buffer.writeln('═' * 60);
    buffer.writeln('RAPORT POMIARU REZYSTANCJI UZIEMIENIA');
    buffer.writeln('═' * 60);
    buffer.writeln();

    buffer.writeln('DATA POMIARU: ${measurement.date.toString()}');
    buffer.writeln('INŻYNIER: ${measurement.engineer}');
    buffer.writeln('LOKALIZACJA: ${measurement.location}');
    buffer.writeln();

    buffer.writeln('WYNIK POMIARU');
    buffer.writeln('─' * 60);
    buffer.writeln('Zmierzona rezystancja: ${measurement.measuredResistance.toStringAsFixed(2)} Ω');
    buffer.writeln('Poprawiona rezystancja: ${analysis.correctedResistance.toStringAsFixed(2)} Ω');
    buffer.writeln();

    buffer.writeln('WARUNKI PODCZAS POMIARU');
    buffer.writeln('─' * 60);
    buffer.writeln('Temperatura gruntu: ${measurement.temperature.label}');
    buffer.writeln('  ${measurement.temperature.description}');
    buffer.writeln('Wilgotność gruntu: ${measurement.humidity.label}');
    buffer.writeln('  ${measurement.humidity.description}');
    buffer.writeln('Sezonowość: ${measurement.season.label}');
    buffer.writeln('Osadzenie elektrod: ${measurement.installation.label}');
    buffer.writeln('Materiał: ${measurement.material.label}');
    buffer.writeln();

    buffer.writeln('PARAMETRY SYSTEMU');
    buffer.writeln('─' * 60);
    buffer.writeln('Liczba elektrod: ${measurement.numberOfElectrodes}');
    buffer.writeln('Rozstaw: ${measurement.spacingBetweenElectrodes.toStringAsFixed(1)} m');
    buffer.writeln('Długość: ${measurement.electrodeLength.toStringAsFixed(1)} m');
    buffer.writeln();

    buffer.writeln('WSPÓŁCZYNNIKI KOREKCJI');
    buffer.writeln('─' * 60);
    buffer.writeln(
      'Temperatura: x${measurement.temperature.correctionFactor.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Wilgotność: x${measurement.humidity.correctionFactor.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Sezonowość: x${measurement.season.correctionFactor.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Osadzenie: x${measurement.installation.correctionFactor.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Materiał: x${measurement.material.correctionFactor.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'CAŁKOWITY: x${analysis.totalCorrectionFactor.toStringAsFixed(2)}',
    );
    buffer.writeln();

    buffer.writeln('REKOMENDACJE');
    buffer.writeln('─' * 60);
    for (final recommendation in analysis.getRecommendations()) {
      buffer.writeln(recommendation);
    }
    buffer.writeln();

    buffer.writeln('UWAGI INŻYNIERA');
    buffer.writeln('─' * 60);
    buffer.writeln(measurement.notes.isNotEmpty ? measurement.notes : 'Brak uwag');
    buffer.writeln();

    buffer.writeln('═' * 60);

    return buffer.toString();
  }

  void reset() {
    _measurements = [];
    _currentAnalysis = null;
    _comparison = null;
    _errorMessage = null;
    notifyListeners();
  }
}
