import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/checklist_generator.dart';

/// Provider zarządzający stanem projektu budowy
/// - Tworzenie projektów
/// - Zarządzanie checklist's
/// - Śledzenie postępu
/// - Generowanie alertów
class ProjectManagerProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  static const _storageKey = 'construction_projects';

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
  // PERSYSTENCJA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Załaduj zapisane projekty z SharedPreferences
  Future<void> loadSavedProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('[Provider] Ładowanie zapisanych projektów...');
      final prefs = await SharedPreferences.getInstance();
      final String? projectsJson = prefs.getString(_storageKey);

      if (projectsJson != null && projectsJson.isNotEmpty) {
        final List<dynamic> projectsList = jsonDecode(projectsJson);
        _projects.clear();
        
        for (final projectData in projectsList) {
          try {
            final project = ConstructionProject.fromJson(projectData);
            _projects.add(project);
          } catch (e) {
            print('[Provider] Błąd przy ładowaniu projektu: $e');
          }
        }
        
        print('[Provider] Załadowano ${_projects.length} projektów');
      } else {
        print('[Provider] Brak zapisanych projektów');
      }
    } catch (e, stackTrace) {
      print('[Provider] Błąd ładowania projektów: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Zapisz wszystkie projekty do SharedPreferences
  Future<void> _saveProjects() async {
    try {
      print('[Provider] Zapisywanie ${_projects.length} projektów...');
      final prefs = await SharedPreferences.getInstance();
      final projectsList = _projects.map((p) => p.toJson()).toList();
      final projectsJson = jsonEncode(projectsList);
      await prefs.setString(_storageKey, projectsJson);
      print('[Provider] Projekty zapisane');
    } catch (e, stackTrace) {
      print('[Provider] Błąd zapisywania projektów: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZARZĄDZANIE PROJEKTAMI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stwórz nowy projekt
  Future<void> createNewProject(BuildingConfiguration config) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('[Provider] Generowanie projektu...');
      // Generator tworzy kompletny projekt
      final project = ProjectChecklistGenerator.generateProject(config);
      
      print('[Provider] Projekt wygenerowany: ${project.allTasks.length} zadań, ${project.units.length} mieszkań');
      
      _currentProject = project;
      _projects.add(project);

      // Zapisz do SharedPreferences
      await _saveProjects();
      print('[Provider] Projekt zapisany');
    } catch (e, stackTrace) {
      print('Błąd przy tworzeniu projektu: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Przekazanie błędu wyżej
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Zaktualizuj istniejący projekt
  Future<void> updateProject(BuildingConfiguration config) async {
    if (_currentProject == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      print('[Provider] Aktualizowanie projektu...');
      // Regeneruj projekt na podstawie nowych danych i połącz z dotychczasowym postępem
      final updatedProject = ProjectChecklistGenerator.generateProject(config);
      final mergedTasks = _mergeTasks(
        updatedProject.allTasks,
        _currentProject!.allTasks,
      );
      final mergedUnits = _mergeUnits(
        updatedProject.units,
        _currentProject!.units,
      );

      final alerts = _currentProject!.alerts.isNotEmpty
          ? _currentProject!.alerts
          : updatedProject.alerts;

      final projectWithId = ConstructionProject(
        projectId: _currentProject!.projectId,
        config: config,
        phases: updatedProject.phases,
        allTasks: mergedTasks,
        alerts: alerts,
        units: mergedUnits,
        createdAt: _currentProject!.createdAt,
        lastModifiedAt: DateTime.now(),
      );
      
      // Zamień w liście
      final index = _projects.indexWhere((p) => p.projectId == _currentProject!.projectId);
      if (index != -1) {
        _projects[index] = projectWithId;
      }
      
      _currentProject = projectWithId;
      
      // Zapisz do SharedPreferences
      await _saveProjects();
      print('[Provider] Projekt zaktualizowany');
    } catch (e, stackTrace) {
      print('Błąd przy aktualizowaniu projektu: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ChecklistTask> _mergeTasks(
    List<ChecklistTask> newTasks,
    List<ChecklistTask> oldTasks,
  ) {
    final oldMap = {for (final task in oldTasks) task.id: task};

    for (final task in newTasks) {
      final old = oldMap[task.id];
      if (old == null) continue;

      task.status = old.status;
      task.completedDate = old.completedDate;
      task.notes = old.notes;
      task.attachmentPaths
        ..clear()
        ..addAll(old.attachmentPaths);
    }

    return newTasks;
  }

  List<ProjectUnit> _mergeUnits(
    List<ProjectUnit> newUnits,
    List<ProjectUnit> oldUnits,
  ) {
    final oldMap = {for (final unit in oldUnits) unit.unitId: unit};

    return newUnits.map((unit) {
      final old = oldMap[unit.unitId];
      if (old == null) return unit;

      final mergedStatuses = Map<String, TaskStatus>.from(unit.taskStatuses);
      for (final entry in old.taskStatuses.entries) {
        if (mergedStatuses.containsKey(entry.key)) {
          mergedStatuses[entry.key] = entry.value;
        }
      }

      final mergedDates =
          Map<String, DateTime?>.from(unit.taskCompletionDates);
      for (final entry in old.taskCompletionDates.entries) {
        if (mergedDates.containsKey(entry.key)) {
          mergedDates[entry.key] = entry.value;
        }
      }

      return unit.copyWith(
        unitName: old.unitName,
        isAlternateUnit: old.isAlternateUnit,
        specificSystems: old.specificSystems,
        taskStatuses: mergedStatuses,
        taskCompletionDates: mergedDates,
        photoPaths: old.photoPaths,
        defectsNotes: old.defectsNotes,
      );
    }).toList();
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
    if (taskIndex == -1) {
      return;
    }

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

    task.notes = (task.notes.isEmpty ? '' : '${task.notes}\n') + note;

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
    
    // 1️⃣ Aktualizuj task.status w project.allTasks (dla PDF)
    final taskInAllTasks = _currentProject!.allTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Zadanie nie znalezione'),
    );
    taskInAllTasks.status = newStatus;
    if (newStatus == TaskStatus.completed) {
      taskInAllTasks.completedDate = DateTime.now();
    }
    
    // 2️⃣ Aktualizuj unit.taskStatuses (dla UI)
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

  /// Zmień nazwę mieszkania
  void updateUnitName(String unitId, String newName) {
    if (_currentProject == null) return;

    final unitIndex =
        _currentProject!.units.indexWhere((u) => u.unitId == unitId);
    if (unitIndex == -1) throw Exception('Mieszkanie nie znalezione');

    final unit = _currentProject!.units[unitIndex];
    _currentProject!.units[unitIndex] = unit.copyWith(unitName: newName);

    _updateProject();
    notifyListeners();
  }

  /// Zmień status lokalu zamiennego
  void updateUnitAlternateStatus(String unitId, bool isAlternate) {
    if (_currentProject == null) return;

    final unitIndex = _currentProject!.units.indexWhere((u) => u.unitId == unitId);
    if (unitIndex == -1) throw Exception('Mieszkanie nie znalezione');

    final unit = _currentProject!.units[unitIndex];
    final updatedStatuses = Map<String, TaskStatus>.from(unit.taskStatuses);
    final updatedDates = Map<String, DateTime?>.from(unit.taskCompletionDates);

    if (isAlternate) {
      updatedStatuses.putIfAbsent(kAlternateProjectTaskId, () => TaskStatus.pending);
      updatedDates.putIfAbsent(kAlternateProjectTaskId, () => null);
    } else {
      updatedStatuses.remove(kAlternateProjectTaskId);
      updatedDates.remove(kAlternateProjectTaskId);
    }

    _currentProject!.units[unitIndex] = unit.copyWith(
      isAlternateUnit: isAlternate,
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
      : '${unit.defectsNotes}\n$defect';
    
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
  // ZARZĄDZANIE OBSZARAMI BUDYNKU (KLATKI, WINDY, GARAŻ, DACH, POMIESZCZENIA)
  // ═══════════════════════════════════════════════════════════════════════════

  BuildingAreaProgress _getOrCreateBuildingArea(
      String areaId, BuildingAreaType areaType) {
    final index =
        _currentProject!.buildingAreas.indexWhere((a) => a.areaId == areaId);
    if (index != -1) return _currentProject!.buildingAreas[index];
    final area =
        BuildingAreaProgress(areaId: areaId, areaType: areaType);
    _currentProject!.buildingAreas.add(area);
    return area;
  }

  BuildingAreaProgress getBuildingArea(
      String areaId, BuildingAreaType areaType) {
    if (_currentProject == null) {
      return BuildingAreaProgress(areaId: areaId, areaType: areaType);
    }
    return _getOrCreateBuildingArea(areaId, areaType);
  }

  void toggleBuildingAreaTask(
      String areaId, BuildingAreaType areaType, String taskName, bool done) {
    if (_currentProject == null) return;
    final area = _getOrCreateBuildingArea(areaId, areaType);
    area.taskStatuses[taskName] = done;
    _updateProject();
    notifyListeners();
  }

  void addBuildingAreaPhoto(
      String areaId, BuildingAreaType areaType, String photoPath) {
    if (_currentProject == null) return;
    final area = _getOrCreateBuildingArea(areaId, areaType);
    area.photoPaths.add(photoPath);
    _updateProject();
    notifyListeners();
  }

  void addBuildingAreaNote(
      String areaId, BuildingAreaType areaType, String text) {
    if (_currentProject == null) return;
    final area = _getOrCreateBuildingArea(areaId, areaType);
    area.notes = area.notes.isEmpty ? text : '${area.notes}\n$text';
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
    // Zapisz do SharedPreferences przy każdej zmianie
    _saveProjects();
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
