/// Integracja bazy danych harmonogramu budowy
/// Mapuje dane z construction_schedule_data.dart do struktury projektu
/// i umożliwia dynamiczne generowanie harmonogramów na podstawie
/// konfiguracji budynku (liczba pięter, garaż, typ budynku)
///
/// Integruje także ElectricalSystemsTaskGenerator dla szczegółowych tasków
/// specjalizowanych dla każdego systemu elektrycznego i teletechnicznego
library;

import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/models/construction_schedule_data.dart' hide BuildingStage;
import 'package:gridly/multitool/project_manager/models/electrical_systems_tasks.dart';

/// Konwerter między wewnętrznymi etapami a standardowymi BuildingStage
class ScheduleDataIntegration {
  /// Mapa konwersji z BuildingStage na BuildingStage
  static final Map<BuildingStage, BuildingStage> stageMapping = {
    BuildingStage.przygotowanie: BuildingStage.przygotowanie,
    BuildingStage.fundamenty: BuildingStage.fundamenty,
    BuildingStage.konstrukcja: BuildingStage.konstrukcja,
    BuildingStage.przegrody: BuildingStage.przegrody,
    BuildingStage.tynki: BuildingStage.tynki,
    BuildingStage.posadzki: BuildingStage.posadzki,
    BuildingStage.osprzet: BuildingStage.osprzet,
    BuildingStage.malowanie: BuildingStage.malowanie,
    BuildingStage.finalizacja: BuildingStage.finalizacja,
    BuildingStage.oddawanie: BuildingStage.oddawanie,
    BuildingStage.ozeInstalacje: BuildingStage.ozeInstalacje,
    BuildingStage.evInfrastruktura: BuildingStage.evInfrastruktura,
  };

  /// Konwersja w drugą stronę
  static final Map<BuildingStage, BuildingStage> reverseStageMapping = {
    BuildingStage.przygotowanie: BuildingStage.przygotowanie,
    BuildingStage.fundamenty: BuildingStage.fundamenty,
    BuildingStage.konstrukcja: BuildingStage.konstrukcja,
    BuildingStage.przegrody: BuildingStage.przegrody,
    BuildingStage.tynki: BuildingStage.tynki,
    BuildingStage.posadzki: BuildingStage.posadzki,
    BuildingStage.osprzet: BuildingStage.osprzet,
    BuildingStage.malowanie: BuildingStage.malowanie,
    BuildingStage.finalizacja: BuildingStage.finalizacja,
    BuildingStage.oddawanie: BuildingStage.oddawanie,
    BuildingStage.ozeInstalacje: BuildingStage.ozeInstalacje,
    BuildingStage.evInfrastruktura: BuildingStage.evInfrastruktura,
  };

  /// Oblicz całkowity czas budowy na podstawie konfiguracji
  static int calculateProjectDurationWeeks(BuildingConfiguration config) {
    return ConstructionScheduleDatabase.calculateTotalWeeks(
      config.totalLevels,
      config.basementLevels,
      config.buildingType,
    );
  }

  /// Generuj harmonogram etapów z dokładnymi datami
  static List<ProjectPhase> generateSchedulePhases(
    BuildingConfiguration config,
  ) {
    final phases = <ProjectPhase>[];
    final stages = ConstructionScheduleDatabase.getStagesForBuildingType(
      config.buildingType,
    );

    DateTime currentDate = config.projectStartDate;

    for (final stageInternal in BuildingStage.values) {
      final stageData = stages[stageInternal];
      if (stageData == null) continue;

      final standardStage = stageMapping[stageInternal]!;
      
      // Oblicz czas dla tego etapu
      final stageWeeks = ConstructionScheduleDatabase.calculateStageWeeks(
        stageInternal,
        config,
      );

      final startDate = currentDate;
      final endDate = currentDate.add(Duration(days: stageWeeks * 7));

      // Identyfikuj zadania krytyczne dla tej fazy
      final criticalTasks = _getCriticalTasksForStage(
        stageInternal,
        config,
      );

      phases.add(
        ProjectPhase(
          stage: standardStage,
          startDate: startDate,
          endDate: endDate,
          description: stageData.description,
          criticalTasks: criticalTasks,
        ),
      );

      currentDate = endDate;
    }

    return phases;
  }

  /// Pobierz listę krytycznych zadań dla etapu
  static List<String> _getCriticalTasksForStage(
    BuildingStage stage,
    BuildingConfiguration config,
  ) {
    final stages = ConstructionScheduleDatabase.getStagesForBuildingType(
      config.buildingType,
    );
    
    final stageData = stages[stage];
    if (stageData == null) return [];

    // Mapuj główne zadania na ID tasków
    final tasks = <String>[];
    for (final task in stageData.tasks.take(3)) {
      // Weź pierwsze 3 główne zadania
      tasks.add('critical-${stage.name}-${task.replaceAll(' ', '-').toLowerCase()}');
    }

    return tasks;
  }

  /// Generuj szczegółowe zadania dla instalacji elektrycznych bazując na etapach budowy
  static List<ChecklistTask> generateElectricalTasksForStages(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    // NOWE: Użyj specjalizowanego generatora dla wszystkich systemów
    // który uwzględnia podział na biuro vs mieszkalny
    return ElectricalSystemsTaskGenerator.generateAllSystemTasks(config, phases);
  }
}
