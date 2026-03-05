import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/models/building_hierarchy.dart';
import 'package:gridly/multitool/project_manager/logic/checklist_generator.dart';
import 'package:gridly/multitool/project_manager/logic/schedule_calculator.dart';
import 'package:gridly/multitool/project_manager/logic/climate_analyzer.dart';

/// Provider zarządzający stanem projektu budowy
/// - Tworzenie projektów
/// - Zarządzanie checklist's
/// - Śledzenie postępu
/// - Generowanie alertów
class ProjectManagerProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  // Aktualnie wybrany projekt
  ConstructionProject? _currentProject;
  bool _isLoading = false;

  // Lista wszystkich projektów
  final List<ConstructionProject> _projects = [];

  // Gettery
  ConstructionProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  List<ConstructionProject> get allProjects => List.unmodifiable(_projects);

  // ═══════════════════════════════════════════════════════════════════════════
  // ZARZĄDZANIE PROJEKTAMI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stwórz nowy projekt z zaawansowaną hierarchią budynków
  Future<void> createNewProjectAdvanced(AdvancedProjectConfiguration advancedConfig) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('[Provider] Generowanie zaawansowanego projektu...');
      print('[Provider] - Budynków: ${advancedConfig.buildings.length}');
      print('[Provider] - Mieszkań: ${advancedConfig.totalUnits}');
      print('[Provider] - Systemów: ${advancedConfig.selectedSystems.length}');
      
      // Oblicz harmonogram z uwzględnieniem klimatu
      final climateMultiplier = PolishClimateAnalyzer.calculateScheduleMultiplier(
        advancedConfig.projectStartDate,
        advancedConfig.projectEndDate,
      );
      
      print('[Provider] - Mnożnik klimatyczny: ${climateMultiplier.toStringAsFixed(2)}x');
      
      // Generate schedule report (optional - for debugging)
      final scheduleReport = ScheduleCalculator.generateDetailedScheduleReport(
        advancedConfig,
        advancedConfig.totalWeeks,
        climateMultiplier: climateMultiplier,
      );
      print('[Provider] Harmonogram:\n$scheduleReport');
      
      // Konwertuj na stary format BuildingConfiguration
      // (żeby istniejący generator checklist mógł działać)
      final config = _convertToLegacyFormat(advancedConfig);
      
      // Generator tworzy kompletny projekt
      final project = ProjectChecklistGenerator.generateProject(config);
      
      print('[Provider] Projekt wygenerowany: ${project.allTasks.length} zadań, ${project.units.length} mieszkań');
      
      _currentProject = project;
      _projects.add(project);

      print('[Provider] Projekt zapisany w pamięci');
    } catch (e, stackTrace) {
      print('Błąd przy tworzeniu projektu: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Konwertuj zaawansowaną konfigurację hierarchiczną na stary format
  BuildingConfiguration _convertToLegacyFormat(AdvancedProjectConfiguration advanced) {
    // Ustaw domyślny typ budynku na podstawie liczby mieszkań
    BuildingType buildingType;
    if (advanced.totalUnits <= 2) {
      buildingType = BuildingType.dupleks;
    } else if (advanced.totalUnits <= 10) {
      buildingType = BuildingType.wielorodzinny; // 3-5 pięter
    } else if (advanced.totalUnits <= 50) {
      buildingType = BuildingType.wielorodzinnyWysoki; // 6+ pięter
    } else {
      buildingType = BuildingType.mieszany;
    }
    
    // Oblicz średnie wartości z całej hierarchii
    final totalFloors = advanced.totalFloors;
    final totalBasement = advanced.totalBasementLevels;
    final hasParking = advanced.hasAnyParking;
    final hasGarage = advanced.hasAnyGarage;
    
    // Stage durations - użyj szablonu albo dynamicznie wygeneruj
    final stageDurations = BuildingTimingTemplates.wielorodzinny34pietra();
    
    return BuildingConfiguration(
      projectName: advanced.projectName,
      buildingType: buildingType,
      address: advanced.address,
      projectStartDate: advanced.projectStartDate,
      totalLevels: (totalFloors / advanced.buildings.length).ceil(),
      basementLevels: totalBasement > 0 ? (totalBasement / advanced.buildings.where((b) => b.hasGarage).length).ceil() : 0,
      hasParking: hasParking,
      hasGarage: hasGarage,
      powerSupplyType: PowerSupplyType.siecNiskiegoNapieciaBezposrednio,
      connectionType: ConnectionType.rozdzielnicaNN,
      estimatedPowerDemand: advanced.totalUnits * 10.0, // 10kW per unit
      selectedSystems: Set<ElectricalSystemType>.from(
        advanced.selectedSystems.whereType<ElectricalSystemType>(),
      ),
      estimatedUnits: advanced.totalUnits,
      estimatedStairCases: advanced.totalStairCases,
      stageDurations: stageDurations,
    );
  }

  /// Stwórz nowy projekt
  Future<void> createNewProject(BuildingConfiguration config) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('[Provider] Generowanie projektu...');
      // Generator tworzy kompletnylista projekt
      final project = ProjectChecklistGenerator.generateProject(config);
      
      print('[Provider] Projekt wygenerowany: ${project.allTasks.length} zadań, ${project.units.length} mieszkań');
      
      _currentProject = project;
      _projects.add(project);

      print('[Provider] Projekt zapisany w pamięci');
      // Zapisz do pamięci (w realnym app -> SQLite)
      // _saveProjectToDb(project);
    } catch (e, stackTrace) {
      print('Błąd przy tworzeniu projektu: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Przekazanie błędu wyżej
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Załaduj istniejący projekt
  Future<void> loadProject(String projectId) async {
    final project = _projects.firstWhere(
      (p) => p.projectId == projectId,
      orElse: () => throw Exception('Projekt nie znaleziony'),
    );

    _currentProject = project;
    notifyListeners();
  }

  /// Usuń projekt
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.projectId == projectId);
    if (_currentProject?.projectId == projectId) {
      _currentProject = null;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZARZĄDZANIE ZADANIAMI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Zmień status zadania
  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    if (_currentProject == null) return;

    final taskIndex = _currentProject!.allTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _currentProject!.allTasks[taskIndex];
    task.status = newStatus;

    if (newStatus == TaskStatus.completed) {
      task.completedDate = DateTime.now();
      // Jeśli to zadanie było zależy nością dla innych - aktualizuj ich status
      _updateDependentTasks(taskId);
    }

    _updateProject();
    notifyListeners();
  }

  /// Dodaj notatkę do zadania
  void addTaskNote(String taskId, String note) {
    if (_currentProject == null) return;

    final task = _currentProject!.allTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Zadanie nie znalezione'),
    );

    task.notes = (task.notes.isEmpty ? '' : task.notes + '\n') + note;

    _updateProject();
    notifyListeners();
  }

  /// Dodaj zdjęcie do zadania
  void addPhotoToTask(String taskId, String photoPath) {
    if (_currentProject == null) return;

    final task = _currentProject!.allTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Zadanie nie znalezione'),
    );

    final newPaths = List<String>.from(task.attachmentPaths);
    newPaths.add(photoPath);
    task.attachmentPaths.clear();
    task.attachmentPaths.addAll(newPaths);

    _updateProject();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZARZĄDZANIE MIESZKANIAMI / JEDNOSTKAMI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Zmień status zadania dla konkretnego mieszkania
  void updateUnitTaskStatus(
    String unitId,
    String taskId,
    TaskStatus newStatus,
  ) {
    if (_currentProject == null) return;

    final unitIndex = _currentProject!.units.indexWhere((u) => u.unitId == unitId);
    if (unitIndex == -1) throw Exception('Mieszkanie nie znalezione');
    
    final unit = _currentProject!.units[unitIndex];
    final updatedStatuses = Map<String, TaskStatus>.from(unit.taskStatuses);
    updatedStatuses[taskId] = newStatus;
    
    final updatedDates = Map<String, DateTime?>.from(unit.taskCompletionDates);
    if (newStatus == TaskStatus.completed) {
      updatedDates[taskId] = DateTime.now();
    }
    
    _currentProject!.units[unitIndex] = unit.copyWith(
      taskStatuses: updatedStatuses,
      taskCompletionDates: updatedDates,
    );

    _updateProject();
    notifyListeners();
  }

  /// Dodaj notatkę do defektów mieszkania
  void addUnitDefectNote(String unitId, String defect) {
    if (_currentProject == null) return;

    final unitIndex = _currentProject!.units.indexWhere((u) => u.unitId == unitId);
    if (unitIndex == -1) throw Exception('Mieszkanie nie znalezione');
    
    final unit = _currentProject!.units[unitIndex];
    final updatedNotes = unit.defectsNotes.isEmpty 
      ? defect 
      : unit.defectsNotes + '\n' + defect;
    
    _currentProject!.units[unitIndex] = unit.copyWith(
      defectsNotes: updatedNotes,
    );

    _updateProject();
    notifyListeners();
  }

  /// Dodaj zdjęcie do mieszkania
  void addUnitPhoto(String unitId, String photoPath) {
    if (_currentProject == null) return;

    final unitIndex = _currentProject!.units.indexWhere((u) => u.unitId == unitId);
    if (unitIndex == -1) throw Exception('Mieszkanie nie znalezione');
    
    final unit = _currentProject!.units[unitIndex];
    final updatedPaths = List<String>.from(unit.photoPaths);
    updatedPaths.add(photoPath);
    
    _currentProject!.units[unitIndex] = unit.copyWith(
      photoPaths: updatedPaths,
    );

    _updateProject();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZARZĄDZANIE ALERTAMI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Oznacz alert jako przeczytany
  void markAlertAsRead(String alertId) {
    if (_currentProject == null) return;

    final alert = _currentProject!.alerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => throw Exception('Alert nie znaleziony'),
    );

    alert.isRead = true;
    alert.readAt = DateTime.now();

    _updateProject();
    notifyListeners();
  }

  /// Dodaj nowy alert
  void addAlert(
    AlertSeverity severity,
    String title,
    String message, {
    String? relatedTaskId,
    String actionSuggestion = '',
  }) {
    if (_currentProject == null) return;

    final newAlert = ProjectAlert(
      id: _uuid.v4(),
      severity: severity,
      title: title,
      message: message,
      relatedTaskId: relatedTaskId,
      actionSuggestion: actionSuggestion,
    );

    final newAlerts = List<ProjectAlert>.from(_currentProject!.alerts);
    newAlerts.add(newAlert);

    // Utwórz nowy projekt z zaktualizowanymi alertami
    var updatedProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: newAlerts,
      units: _currentProject!.units,
    );

    _currentProject = updatedProject;
    _updateProject();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERY I FILTRY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pobierz zadania dla aktualnej fazy
  List<ChecklistTask> get tasksForCurrentPhase {
    if (_currentProject == null) return [];

    final currentPhase = _currentProject!.activePhase;
    if (currentPhase == null) return [];

    return _currentProject!.allTasks
        .where((task) => task.stage == currentPhase.stage)
        .toList();
  }

  /// Pobierz wszystkie zadania dla danego systemu
  List<ChecklistTask> getTasksForSystem(ElectricalSystemType system) {
    if (_currentProject == null) return [];

    return _currentProject!.allTasks
        .where((task) => task.system == system)
        .toList();
  }

  /// Pobierz zadania opóźnione
  List<ChecklistTask> get delayedTasks {
    if (_currentProject == null) return [];

    return _currentProject!.allTasks
        .where((task) => task.isDelayed)
        .toList();
  }

  /// Pobierz zadania oczekujące
  List<ChecklistTask> get pendingTasks {
    if (_currentProject == null) return [];

    return _currentProject!.allTasks
        .where((task) => task.status == TaskStatus.pending)
        .toList();
  }

  /// Pobierz zadania dla konkretnego mieszkania
  List<ChecklistTask> getTasksForUnit(String unitId) {
    if (_currentProject == null) return [];

    return _currentProject!.allTasks
        .where((task) =>
            task.unitIds == null || task.unitIds!.contains(unitId))
        .toList();
  }

  /// Pobierz mieszkania dla konkretnego piętra
  List<ProjectUnit> getUnitsForFloor(int floor) {
    if (_currentProject == null) return [];

    return _currentProject!.units
        .where((unit) => unit.floor == floor)
        .toList();
  }

  /// Pobierz mieszkania dla konkretnej klatki schodowej
  List<ProjectUnit> getUnitsForStairCase(String stairCase) {
    if (_currentProject == null) return [];

    return _currentProject!.units
        .where((unit) => unit.stairCase == stairCase)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRYWATNE METODY
  // ═══════════════════════════════════════════════════════════════════════════

  void _updateDependentTasks(String completedTaskId) {
    if (_currentProject == null) return;

    // Znajdź wszystkie zadania, które zależy od completed'a
    for (final task in _currentProject!.allTasks) {
      if (task.dependsOnTaskIds.contains(completedTaskId)) {
        // Sprawdź, czy wszystkie zależności są spełnione
        bool allDependenciesmet = task.dependsOnTaskIds.every(
          (depId) {
            final depTask = _currentProject!.allTasks
                .firstWhere((t) => t.id == depId, orElse: () => task);
            return depTask.status == TaskStatus.completed;
          },
        );

        if (allDependenciesmet && task.status == TaskStatus.blocked) {
          task.status = TaskStatus.pending;
        }
      }
    }
  }

  void _updateProject() {
    // W realnym app -> zapisz do bazy danych
    // _saveProjectToDb(_currentProject!);
    _currentProject!.lastModifiedAt = DateTime.now();
  }

  /// Eksportuj projekt do JSON (dla backupu)
  String exportProjectAsJson() {
    if (_currentProject == null) return '{}';

    final data = {
      'projectId': _currentProject!.projectId,
      'projectName': _currentProject!.config.projectName,
      'address': _currentProject!.config.address,
      'startDate': _currentProject!.config.projectStartDate.toIso8601String(),
      'totalTasks': _currentProject!.allTasks.length,
      'completedTasks': _currentProject!.allTasks
          .where((t) => t.status == TaskStatus.completed)
          .length,
      'overallProgress': _currentProject!.overallProgress,
      'unreadAlerts': _currentProject!.unreadAlertCount,
      'delayedTasks': _currentProject!.delayedTaskCount,
    };

    return data.toString();
  }

  /// Wygeneruj raport stanu projektu
  String generateProjectReport() {
    if (_currentProject == null) return 'Brak projektu';

    final project = _currentProject!;
    final config = project.config;

    return '''
╔══════════════════════════════════════════════════════════╗
║           RAPORT POSTĘPU PROJEKTU BUDOWY               ║
╚══════════════════════════════════════════════════════════╝

PROJEKT:           ${config.projectName}
ADRES:             ${config.address}
ROZPOCZĘCIE:       ${config.projectStartDate}
ZAKOŃCZENIE PLANU: ${config.estimatedEndDate}

─── PARAMETRY BUDYNKU ───
Typ:               ${config.buildingType.toString().split('.').last}
Piętra nadziemne:  ${config.totalLevels}
Piętra podziemne:  ${config.basementLevels}
Garaż:             ${config.hasGarage ? 'TAK' : 'NIE'}
Parking:           ${config.hasParking ? 'TAK' : 'NIE'}

─── POSTĘP ───
Ogółem:            ${project.overallProgress.toStringAsFixed(1)}%
Zadania ukończone: ${project.allTasks.where((t) => t.status == TaskStatus.completed).length}/${project.allTasks.length}
Zadania opóźnione: ${project.delayedTaskCount}
Aktywna faza:      ${project.activePhase?.stage.toString().split('.').last ?? 'BRAK'}

─── ALERTY ───
Nieprzeczytane:    ${project.unreadAlertCount}
Krytyczne:         ${project.alerts.where((a) => a.severity == AlertSeverity.critical).length}
Pilne:             ${project.alerts.where((a) => a.severity == AlertSeverity.urgent).length}

─── SYSTEMY ───
${config.selectedSystems.map((s) => '  • ${_getSystemNameForReport(s)}').join('\n')}

Data raportu: ${DateTime.now()}
''';
  }

  String _getSystemNameForReport(ElectricalSystemType system) {
    switch (system) {
      case ElectricalSystemType.oswietlenie:
        return 'Oświetlenie';
      case ElectricalSystemType.zasilanie:
        return 'Zasilanie';
      case ElectricalSystemType.domofonowa:
        return 'Domofon';
      case ElectricalSystemType.odgromowa:
        return 'Ochrona odgromowa';
      case ElectricalSystemType.panelePV:
        return 'Panele słoneczne (PV)';
      case ElectricalSystemType.ladownarki:
        return 'Ładowarki samochodowe';
      case ElectricalSystemType.ppoz:
        return 'System ppoż';
      case ElectricalSystemType.cctv:
        return 'CCTV/Monitoring';
      default:
        return system.toString();
    }
  }
}
