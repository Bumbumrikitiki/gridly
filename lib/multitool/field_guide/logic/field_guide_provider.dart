import 'package:flutter/foundation.dart';
import 'package:gridly/multitool/field_guide/models/field_guide_models.dart';
import 'package:gridly/multitool/field_guide/services/field_guide_database.dart';

class FieldGuideProvider extends ChangeNotifier {
  InspectionScenario? _currentScenario;
  final List<MeasurementResult> _measurementResults = [];

  // Getters
  InspectionScenario? get currentScenario => _currentScenario;
  List<MeasurementResult> get measurementResults => _measurementResults;
  MeasurementChecklist? get currentMeasureChecklist {
    if (_currentScenario == null) return null;
    return FieldGuideDatabase.getMeasurementChecklist(_currentScenario!);
  }

  /// Ostatnie wyniki pomiarów (do porównania)
  List<MeasurementResult> get recentResults {
    return _measurementResults.isNotEmpty
        ? _measurementResults
        : <MeasurementResult>[];
  }

  /// Status bieżącego scenariusza - ile pomiarów ukończonych
  int get completedMeasurements {
    if (currentMeasureChecklist == null) return 0;
    final measurements = currentMeasureChecklist!.measurements;
    int completed = 0;
    for (final measurement in measurements) {
      if (_measurementResults
          .any((result) => result.type.id == measurement.id)) {
        completed++;
      }
    }
    return completed;
  }

  int get totalMeasurements {
    return currentMeasureChecklist?.measurements.length ?? 0;
  }

  bool get allMeasurementsComplete =>
      totalMeasurements > 0 && completedMeasurements == totalMeasurements;

  /// Zmienia aktualny scenariusz inspekcji
  void setScenario(InspectionScenario scenario) {
    _currentScenario = scenario;
    clearMeasurements(); // Czyści poprzednie pomiary
    notifyListeners();
  }

  /// Dodaje lub aktualizuje wynik pomiaru
  void addMeasurementResult(MeasurementResult result) {
    final existingIndex = _measurementResults
        .indexWhere((r) => r.type.id == result.type.id);

    if (existingIndex >= 0) {
      _measurementResults[existingIndex] = result;
    } else {
      _measurementResults.add(result);
    }
    notifyListeners();
  }

  /// Usuwa wynik pomiaru
  void removeMeasurementResult(String typeId) {
    _measurementResults.removeWhere((r) => r.type.id == typeId);
    notifyListeners();
  }

  /// Czyści wszystkie pomiary dla bieżącego scenariusza
  void clearMeasurements() {
    _measurementResults.clear();
    notifyListeners();
  }

  /// Zwraca wynik pomiaru dla danego typu
  MeasurementResult? getMeasurementResult(String typeId) {
    try {
      return _measurementResults.firstWhere((r) => r.type.id == typeId);
    } catch (e) {
      return null;
    }
  }

  /// Zwraca status pomiaru (przejdź/nie przejdź) na podstawie wartości
  bool isMeasurementPassed(MeasurementResult result) {
    if (result.value.isEmpty) return false;

    try {
      final value = double.parse(result.value);
      final type = result.type;

      // Jeśli jest wartość max
      if (type.maxValue != null) {
        final maxVal = double.parse(type.maxValue!);
        if (value > maxVal) return false;
      }

      // Jeśli jest wartość min
      if (type.minValue != null) {
        final minVal = double.parse(type.minValue!);
        if (value < minVal) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pobiera pełny raport z pomiarów
  InspectionReport getReport() {
    return InspectionReport(
      scenario: _currentScenario,
      timestamp: DateTime.now(),
      measurements: _measurementResults,
      passedCount: _measurementResults.where((r) => r.passed).length,
      failedCount: _measurementResults.where((r) => !r.passed).length,
    );
  }
}

/// Model raportu z inspekcji
class InspectionReport {
  final InspectionScenario? scenario;
  final DateTime timestamp;
  final List<MeasurementResult> measurements;
  final int passedCount;
  final int failedCount;

  InspectionReport({
    required this.scenario,
    required this.timestamp,
    required this.measurements,
    required this.passedCount,
    required this.failedCount,
  });

  bool get allPassed => failedCount == 0 && measurements.isNotEmpty;
  int get totalCount => passedCount + failedCount;
  double get passPercentage =>
      totalCount > 0 ? (passedCount / totalCount * 100) : 0;
}
