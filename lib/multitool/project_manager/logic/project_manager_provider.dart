import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/checklist_generator.dart';
import 'package:gridly/multitool/project_manager/logic/project_area_catalog.dart';
import 'package:gridly/services/local_notifications_service.dart';

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
            final rawProject = ConstructionProject.fromJson(projectData);
            final project = _normalizeProject(rawProject);
            _projects.add(project);
          } catch (e) {
            print('[Provider] Błąd przy ładowaniu projektu: $e');
          }
        }

        print('[Provider] Załadowano ${_projects.length} projektów');
      } else {
        print('[Provider] Brak zapisanych projektów');
      }

      unawaited(_refreshRecurringNotificationSchedules());
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
      print('[Provider] JSON length: ${projectsJson.length} bytes');
      await prefs.setString(_storageKey, projectsJson);
      print('[Provider] Projekty zapisane');
    } catch (e, stackTrace) {
      print('[Provider] Błąd zapisywania projektów: $e');
      print('[Provider] Stack trace: $stackTrace');
      rethrow;
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

      print(
          '[Provider] Projekt wygenerowany: ${project.allTasks.length} zadań, ${project.units.length} mieszkań');

      final syncedProject = _normalizeProject(project);
      _currentProject = syncedProject;
      _projects.add(syncedProject);

      // Zapisz do SharedPreferences
      await _saveProjects();
      unawaited(_refreshRecurringNotificationSchedules());
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
      print(
          '[Provider] Config: name="${config.projectName}", units=${config.estimatedUnits}');
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
        recurringAlerts: _currentProject!.recurringAlerts,
        units: mergedUnits,
        areaProgress: _currentProject!.areaProgress,
        createdAt: _currentProject!.createdAt,
        lastModifiedAt: DateTime.now(),
      );

      final normalizedProject = _normalizeProject(projectWithId);

      // Zamień w liście
      final index = _projects
          .indexWhere((p) => p.projectId == _currentProject!.projectId);
      if (index != -1) {
        _projects[index] = normalizedProject;
      }

      _currentProject = normalizedProject;

      // Zapisz do SharedPreferences
      await _saveProjects();
      unawaited(_refreshRecurringNotificationSchedules());
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

      final mergedDates = Map<String, DateTime?>.from(unit.taskCompletionDates);
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

    final syncedProject = _normalizeProject(project);
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index != -1) {
      _projects[index] = syncedProject;
    }
    _currentProject = syncedProject;
    notifyListeners();
  }

  /// Usuń projekt
  Future<void> deleteProject(String projectId) async {
    try {
      _projects.removeWhere((p) => p.projectId == projectId);
      if (_currentProject?.projectId == projectId) {
        _currentProject = null;
      }

      await _saveProjects();
      unawaited(_refreshRecurringNotificationSchedules());
      notifyListeners();
    } catch (e, stackTrace) {
      print('[Provider] Błąd przy usuwaniu projektu: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZARZĄDZANIE ZADANIAMI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Zmień status zadania
  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    if (_currentProject == null) return;

    final taskIndex =
        _currentProject!.allTasks.indexWhere((t) => t.id == taskId);
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

    final unitIndex =
        _currentProject!.units.indexWhere((u) => u.unitId == unitId);
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

    final unitIndex =
        _currentProject!.units.indexWhere((u) => u.unitId == unitId);
    if (unitIndex == -1) throw Exception('Mieszkanie nie znalezione');

    final unit = _currentProject!.units[unitIndex];
    final updatedStatuses = Map<String, TaskStatus>.from(unit.taskStatuses);
    final updatedDates = Map<String, DateTime?>.from(unit.taskCompletionDates);

    if (isAlternate) {
      updatedStatuses.putIfAbsent(
          kAlternateProjectTaskId, () => TaskStatus.pending);
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

    final unitIndex =
        _currentProject!.units.indexWhere((u) => u.unitId == unitId);
    if (unitIndex == -1) throw Exception('Mieszkanie nie znalezione');

    final unit = _currentProject!.units[unitIndex];
    final updatedNotes =
        unit.defectsNotes.isEmpty ? defect : '${unit.defectsNotes}\n$defect';

    _currentProject!.units[unitIndex] = unit.copyWith(
      defectsNotes: updatedNotes,
    );

    _updateProject();
    notifyListeners();
  }

  /// Dodaj zdjęcie do mieszkania
  void addUnitPhoto(String unitId, String photoPath) {
    if (_currentProject == null) return;

    final unitIndex =
        _currentProject!.units.indexWhere((u) => u.unitId == unitId);
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
      recurringAlerts: _currentProject!.recurringAlerts,
      units: _currentProject!.units,
      areaProgress: _currentProject!.areaProgress,
    );

    _currentProject = updatedProject;
    _updateProject();
    notifyListeners();
  }

  void addRecurringAlert({
    required String title,
    required String message,
    required int intervalDays,
    AlertSeverity severity = AlertSeverity.warning,
    String actionSuggestion = '',
    required DateTime firstOccurrenceAt,
    int remindBeforeMinutes = 0,
    int? preferredWeekday,
  }) {
    if (_currentProject == null) return;
    if (intervalDays <= 0) return;
    if (remindBeforeMinutes < 0) return;

    final normalizedWeekday = intervalDays % 7 == 0
        ? preferredWeekday?.clamp(1, 7)
        : null;
    final normalizedOccurrenceAt = normalizedWeekday != null
        ? _alignDateTimeToWeekday(firstOccurrenceAt, normalizedWeekday)
        : firstOccurrenceAt;

    final recurring = RecurringProjectAlert(
      id: _uuid.v4(),
      severity: severity,
      title: title,
      message: message,
      actionSuggestion: actionSuggestion,
      intervalDays: intervalDays,
      nextOccurrenceAt: normalizedOccurrenceAt,
      remindBeforeMinutes: remindBeforeMinutes,
      preferredWeekday: normalizedWeekday,
    );

    final recurringAlerts = List<RecurringProjectAlert>.from(
      _currentProject!.recurringAlerts,
    )..add(recurring);

    _currentProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: _currentProject!.alerts,
      recurringAlerts: recurringAlerts,
      units: _currentProject!.units,
      areaProgress: _currentProject!.areaProgress,
      createdAt: _currentProject!.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    _updateProject();
    unawaited(_refreshRecurringNotificationSchedules());
    notifyListeners();
  }

  void removeRecurringAlert(String recurringAlertId) {
    if (_currentProject == null) return;

    final recurringAlerts = List<RecurringProjectAlert>.from(
      _currentProject!.recurringAlerts,
    )..removeWhere((item) => item.id == recurringAlertId);

    _currentProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: _currentProject!.alerts,
      recurringAlerts: recurringAlerts,
      units: _currentProject!.units,
      areaProgress: _currentProject!.areaProgress,
      createdAt: _currentProject!.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    _updateProject();
    unawaited(_refreshRecurringNotificationSchedules());
    notifyListeners();
  }

  int syncRecurringAlerts() {
    if (_currentProject == null) return 0;

    final synced = _syncRecurringAlertsForProject(_currentProject!);
    if (identical(synced, _currentProject)) {
      return 0;
    }

    final index = _projects.indexWhere((p) => p.projectId == synced.projectId);
    if (index != -1) {
      _projects[index] = synced;
    }
    _currentProject = synced;
    _updateProject();
    unawaited(_refreshRecurringNotificationSchedules());
    notifyListeners();

    return 1;
  }

  Future<void> _refreshRecurringNotificationSchedules({
    bool requestPermission = false,
  }) async {
    try {
      await LocalNotificationsService.instance.replaceAllRecurringNotifications(
        _projects,
        requestPermission: requestPermission,
      );
    } catch (e) {
      print('[Provider] Nie udalo sie zsynchronizowac notyfikacji: $e');
    }
  }

  ConstructionProject _syncRecurringAlertsForProject(
    ConstructionProject project,
  ) {
    if (project.recurringAlerts.isEmpty) {
      return project;
    }

    final now = DateTime.now();
    final updatedRecurring = <RecurringProjectAlert>[];
    final generatedAlerts = <ProjectAlert>[];
    var hasChanges = false;

    for (final recurring in project.recurringAlerts) {
      if (!recurring.isActive || recurring.intervalDays <= 0) {
        updatedRecurring.add(recurring);
        continue;
      }

      final normalizedWeekday = recurring.intervalDays % 7 == 0
          ? recurring.preferredWeekday?.clamp(1, 7)
          : null;
      var nextOccurrence = normalizedWeekday != null
          ? _alignDateTimeToWeekday(recurring.nextOccurrenceAt, normalizedWeekday)
          : recurring.nextOccurrenceAt;
      if (nextOccurrence != recurring.nextOccurrenceAt ||
          normalizedWeekday != recurring.preferredWeekday) {
        hasChanges = true;
      }
      var generated = 0;
      while (!recurring
          .copyWith(nextOccurrenceAt: nextOccurrence)
          .nextTriggerAt
          .isAfter(now)) {
        generated++;
        generatedAlerts.add(
          ProjectAlert(
            id: _uuid.v4(),
            severity: recurring.severity,
            title: recurring.title,
            message: recurring.message,
            actionSuggestion: recurring.actionSuggestion,
          ),
        );
        nextOccurrence = nextOccurrence.add(
          Duration(days: recurring.intervalDays),
        );
      }

      if (generated > 0) {
        hasChanges = true;
        updatedRecurring.add(
          recurring.copyWith(
            nextOccurrenceAt: nextOccurrence,
            preferredWeekday: normalizedWeekday,
          ),
        );
      } else {
        updatedRecurring.add(
          recurring.copyWith(
            nextOccurrenceAt: nextOccurrence,
            preferredWeekday: normalizedWeekday,
          ),
        );
      }
    }

    if (!hasChanges) {
      return project;
    }

    return ConstructionProject(
      projectId: project.projectId,
      config: project.config,
      phases: project.phases,
      allTasks: project.allTasks,
      alerts: <ProjectAlert>[...project.alerts, ...generatedAlerts],
      recurringAlerts: updatedRecurring,
      units: project.units,
      areaProgress: project.areaProgress,
      createdAt: project.createdAt,
      lastModifiedAt: DateTime.now(),
    );
  }

  /// Szybkie replanowanie harmonogramu od aktywnej fazy.
  /// Przesuwa daty etapów i przelicza terminy otwartych zadań.
  Future<void> shiftSchedule({
    required int days,
    String reason = '',
  }) async {
    if (_currentProject == null || days == 0) return;

    final project = _currentProject!;
    if (project.phases.isEmpty) return;

    final startIndex = _resolveReplanStartIndex(project.phases);
    if (startIndex < 0) return;

    final shiftedPhases = <ProjectPhase>[];
    for (var i = 0; i < project.phases.length; i++) {
      final phase = project.phases[i];
      if (i < startIndex) {
        shiftedPhases.add(phase);
        continue;
      }

      shiftedPhases.add(
        ProjectPhase(
          stage: phase.stage,
          startDate: phase.startDate.add(Duration(days: days)),
          endDate: phase.endDate.add(Duration(days: days)),
          description: phase.description,
          criticalTasks: phase.criticalTasks,
        ),
      );
    }

    final phaseByStage = <BuildingStage, ProjectPhase>{
      for (final phase in shiftedPhases) phase.stage: phase,
    };

    final updatedTasks = project.allTasks
        .map((task) => _copyTaskWithReplannedDueDate(task, phaseByStage))
        .toList();

    final details = reason.trim().isEmpty ? '' : ' Powod: ${reason.trim()}.';
    final updatedAlerts = List<ProjectAlert>.from(project.alerts)
      ..add(
        ProjectAlert(
          id: _uuid.v4(),
          severity: AlertSeverity.info,
          title: 'Harmonogram zaktualizowany',
          message: 'Przesunieto etapy od aktywnej fazy o $days dni.$details',
          actionSuggestion:
              'Zweryfikuj zadania na dzis i zakres na najblizsze 3 dni.',
        ),
      );

    final updatedProject = ConstructionProject(
      projectId: project.projectId,
      config: project.config,
      phases: shiftedPhases,
      allTasks: updatedTasks,
      alerts: updatedAlerts,
      recurringAlerts: project.recurringAlerts,
      units: project.units,
      areaProgress: project.areaProgress,
      createdAt: project.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    final index = _projects.indexWhere((p) => p.projectId == project.projectId);
    if (index != -1) {
      _projects[index] = updatedProject;
    }

    _currentProject = updatedProject;
    await _saveProjects();
    notifyListeners();
  }

  /// Ustaw wybrany etap jako aktualny na osi czasu.
  /// Technicznie: przesuwa caly harmonogram tak, by wskazany etap byl aktywny dzis.
  Future<void> alignScheduleToStage(
    BuildingStage stage, {
    String reason = '',
  }) async {
    if (_currentProject == null) return;

    final project = _currentProject!;
    if (project.phases.isEmpty) return;

    final selected = project.phases.where((p) => p.stage == stage).toList();
    if (selected.isEmpty) return;

    final selectedPhase = selected.first;
    final targetStart = DateTime.now().subtract(const Duration(days: 1));
    final delta = targetStart.difference(selectedPhase.startDate);

    final shiftedPhases = project.phases
        .map(
          (phase) => ProjectPhase(
            stage: phase.stage,
            startDate: phase.startDate.add(delta),
            endDate: phase.endDate.add(delta),
            description: phase.description,
            criticalTasks: phase.criticalTasks,
          ),
        )
        .toList();

    final phaseByStage = <BuildingStage, ProjectPhase>{
      for (final phase in shiftedPhases) phase.stage: phase,
    };

    final updatedTasks = project.allTasks
        .map((task) => _copyTaskWithReplannedDueDate(task, phaseByStage))
        .toList();

    final details = reason.trim().isEmpty ? '' : ' Powod: ${reason.trim()}.';
    final updatedAlerts = List<ProjectAlert>.from(project.alerts)
      ..add(
        ProjectAlert(
          id: _uuid.v4(),
          severity: AlertSeverity.info,
          title: 'Ustawiono aktualny etap',
          message: 'Aktualny etap ustawiono na: ${stage.name}.$details',
          actionSuggestion:
              'Zweryfikuj zadania dla aktualnej fazy i potwierdz priorytety tygodnia.',
        ),
      );

    final updatedProject = ConstructionProject(
      projectId: project.projectId,
      config: project.config,
      phases: shiftedPhases,
      allTasks: updatedTasks,
      alerts: updatedAlerts,
      recurringAlerts: project.recurringAlerts,
      units: project.units,
      areaProgress: project.areaProgress,
      createdAt: project.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    final index = _projects.indexWhere((p) => p.projectId == project.projectId);
    if (index != -1) {
      _projects[index] = updatedProject;
    }

    _currentProject = updatedProject;
    await _saveProjects();
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

    return _currentProject!.allTasks.where((task) => task.isDelayed).toList();
  }

  ProjectAreaProgress? getAreaProgress(String areaId) {
    if (_currentProject == null) return null;

    for (final area in _currentProject!.areaProgress) {
      if (area.areaId == areaId) {
        return area;
      }
    }
    return null;
  }

  void updateAreaTaskStatus(
    String areaId,
    String taskId,
    TaskStatus newStatus,
  ) {
    if (_currentProject == null) return;

    final areaIndex = _currentProject!.areaProgress.indexWhere(
      (area) => area.areaId == areaId,
    );
    if (areaIndex == -1) return;

    final currentArea = _currentProject!.areaProgress[areaIndex];
    final updatedStatuses = Map<String, TaskStatus>.from(currentArea.taskStatuses);
    final updatedDates =
        Map<String, DateTime?>.from(currentArea.taskCompletionDates);

    updatedStatuses[taskId] = newStatus;
    updatedDates[taskId] =
        newStatus == TaskStatus.completed ? DateTime.now() : null;

    final updatedAreas = List<ProjectAreaProgress>.from(
      _currentProject!.areaProgress,
    );
    updatedAreas[areaIndex] = currentArea.copyWith(
      taskStatuses: updatedStatuses,
      taskCompletionDates: updatedDates,
    );

    _currentProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: _currentProject!.alerts,
      recurringAlerts: _currentProject!.recurringAlerts,
      units: _currentProject!.units,
      areaProgress: updatedAreas,
      createdAt: _currentProject!.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    final projectIndex = _projects.indexWhere(
      (project) => project.projectId == _currentProject!.projectId,
    );
    if (projectIndex != -1) {
      _projects[projectIndex] = _currentProject!;
    }

    _updateProject();
    notifyListeners();
  }

  void addAreaPhoto(String areaId, String photoPath) {
    if (_currentProject == null) return;

    final areaIndex = _currentProject!.areaProgress.indexWhere(
      (area) => area.areaId == areaId,
    );
    if (areaIndex == -1) return;

    final currentArea = _currentProject!.areaProgress[areaIndex];
    final updatedPhotos = List<String>.from(currentArea.photoPaths)
      ..add(photoPath);

    final updatedAreas = List<ProjectAreaProgress>.from(
      _currentProject!.areaProgress,
    );
    updatedAreas[areaIndex] = currentArea.copyWith(photoPaths: updatedPhotos);

    _currentProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: _currentProject!.alerts,
      recurringAlerts: _currentProject!.recurringAlerts,
      units: _currentProject!.units,
      areaProgress: updatedAreas,
      createdAt: _currentProject!.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    final projectIndex = _projects.indexWhere(
      (project) => project.projectId == _currentProject!.projectId,
    );
    if (projectIndex != -1) {
      _projects[projectIndex] = _currentProject!;
    }

    _updateProject();
    notifyListeners();
  }

  void addAreaNote(String areaId, String note) {
    if (_currentProject == null) return;

    final areaIndex = _currentProject!.areaProgress.indexWhere(
      (area) => area.areaId == areaId,
    );
    if (areaIndex == -1) return;

    final currentArea = _currentProject!.areaProgress[areaIndex];
    final updatedNotes = currentArea.notes.isEmpty
        ? note
        : '${currentArea.notes}\n$note';

    final updatedAreas = List<ProjectAreaProgress>.from(
      _currentProject!.areaProgress,
    );
    updatedAreas[areaIndex] = currentArea.copyWith(notes: updatedNotes);

    _currentProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: _currentProject!.alerts,
      recurringAlerts: _currentProject!.recurringAlerts,
      units: _currentProject!.units,
      areaProgress: updatedAreas,
      createdAt: _currentProject!.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    final projectIndex = _projects.indexWhere(
      (project) => project.projectId == _currentProject!.projectId,
    );
    if (projectIndex != -1) {
      _projects[projectIndex] = _currentProject!;
    }

    _updateProject();
    notifyListeners();
  }

  void removeAreaPhoto(String areaId, int photoIndex) {
    if (_currentProject == null) return;

    final areaIndex = _currentProject!.areaProgress.indexWhere(
      (area) => area.areaId == areaId,
    );
    if (areaIndex == -1) return;

    final currentArea = _currentProject!.areaProgress[areaIndex];
    if (photoIndex < 0 || photoIndex >= currentArea.photoPaths.length) return;

    final updatedPhotos = List<String>.from(currentArea.photoPaths)
      ..removeAt(photoIndex);

    final updatedAreas = List<ProjectAreaProgress>.from(
      _currentProject!.areaProgress,
    );
    updatedAreas[areaIndex] = currentArea.copyWith(photoPaths: updatedPhotos);

    _currentProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: _currentProject!.alerts,
      recurringAlerts: _currentProject!.recurringAlerts,
      units: _currentProject!.units,
      areaProgress: updatedAreas,
      createdAt: _currentProject!.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    final projectIndex = _projects.indexWhere(
      (project) => project.projectId == _currentProject!.projectId,
    );
    if (projectIndex != -1) {
      _projects[projectIndex] = _currentProject!;
    }

    _updateProject();
    notifyListeners();
  }

  void updateAreaNotes(String areaId, String newNotes) {
    if (_currentProject == null) return;

    final areaIndex = _currentProject!.areaProgress.indexWhere(
      (area) => area.areaId == areaId,
    );
    if (areaIndex == -1) return;

    final currentArea = _currentProject!.areaProgress[areaIndex];
    final updatedAreas = List<ProjectAreaProgress>.from(
      _currentProject!.areaProgress,
    );
    updatedAreas[areaIndex] = currentArea.copyWith(notes: newNotes);

    _currentProject = ConstructionProject(
      projectId: _currentProject!.projectId,
      config: _currentProject!.config,
      phases: _currentProject!.phases,
      allTasks: _currentProject!.allTasks,
      alerts: _currentProject!.alerts,
      recurringAlerts: _currentProject!.recurringAlerts,
      units: _currentProject!.units,
      areaProgress: updatedAreas,
      createdAt: _currentProject!.createdAt,
      lastModifiedAt: DateTime.now(),
    );

    final projectIndex = _projects.indexWhere(
      (project) => project.projectId == _currentProject!.projectId,
    );
    if (projectIndex != -1) {
      _projects[projectIndex] = _currentProject!;
    }

    _updateProject();
    notifyListeners();
  }

  /// Zadania na dziś (dla szybkiego widoku mobilnego)
  List<ChecklistTask> get tasksDueToday {
    if (_currentProject == null) return [];

    final now = DateTime.now();
    return _currentProject!.allTasks.where((task) {
      if (task.status == TaskStatus.completed || task.dueDate == null) {
        return false;
      }

      final dueDate = task.dueDate!;
      return dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
    }).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  /// Zadania z najbliższych dni (bez przeterminowanych i bez dzisiejszych)
  List<ChecklistTask> getUpcomingTasks({int withinDays = 7}) {
    if (_currentProject == null) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(Duration(days: withinDays));

    return _currentProject!.allTasks.where((task) {
      if (task.status == TaskStatus.completed || task.dueDate == null) {
        return false;
      }

      final due = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return due.isAfter(today) &&
          (due.isBefore(end) || due.isAtSameMomentAs(end));
    }).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  /// Tygodniowy snapshot: plan kontra wykonanie.
  WeeklyExecutionSnapshot getWeeklyExecutionSnapshot(
      {DateTime? referenceDate}) {
    if (_currentProject == null) {
      final now = DateTime.now();
      final weekStart = _startOfIsoWeek(now);
      return WeeklyExecutionSnapshot.empty(
        weekStart: weekStart,
        weekEnd: weekStart.add(const Duration(days: 6)),
      );
    }

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = _startOfIsoWeek(today);
    final weekEnd = weekStart.add(const Duration(days: 6));

    bool inWeek(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
    }

    final tasks = _currentProject!.allTasks;

    final plannedThisWeek = tasks
        .where(
          (task) => task.dueDate != null && inWeek(task.dueDate!),
        )
        .toList();

    final completedThisWeek = tasks
        .where(
          (task) =>
              task.status == TaskStatus.completed &&
              task.completedDate != null &&
              inWeek(task.completedDate!),
        )
        .toList();

    final plannedCompletedThisWeek = plannedThisWeek
        .where(
          (task) =>
              task.status == TaskStatus.completed &&
              task.completedDate != null &&
              inWeek(task.completedDate!),
        )
        .toList();

    final plannedOpen = plannedThisWeek
        .where(
          (task) => task.status != TaskStatus.completed,
        )
        .toList();

    final carryOver = tasks
        .where(
          (task) =>
              task.status != TaskStatus.completed &&
              task.dueDate != null &&
              DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              ).isBefore(weekStart),
        )
        .toList();

    final overdueOpen = tasks
        .where(
          (task) =>
              task.status != TaskStatus.completed &&
              task.dueDate != null &&
              DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              ).isBefore(today),
        )
        .toList();

    final onTimeCompleted = plannedThisWeek
        .where(
          (task) =>
              task.status == TaskStatus.completed &&
              task.completedDate != null &&
              !task.completedDate!.isAfter(task.dueDate!),
        )
        .length;

    return WeeklyExecutionSnapshot(
      weekStart: weekStart,
      weekEnd: weekEnd,
      plannedCount: plannedThisWeek.length,
      completedCount: completedThisWeek.length,
      plannedCompletedCount: plannedCompletedThisWeek.length,
      plannedOpenCount: plannedOpen.length,
      overdueOpenCount: overdueOpen.length,
      carryOverCount: carryOver.length,
      onTimeCompletedCount: onTimeCompleted,
      topOverdueTasks: overdueOpen
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)),
    );
  }

  DateTime _startOfIsoWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final offset = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: offset));
  }

  DateTime _alignDateTimeToWeekday(DateTime dateTime, int weekday) {
    final targetWeekday = weekday.clamp(1, 7);
    final delta = (targetWeekday - dateTime.weekday + 7) % 7;
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day + delta,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
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
        .where((task) => task.unitIds == null || task.unitIds!.contains(unitId))
        .toList();
  }

  /// Pobierz mieszkania dla konkretnego piętra
  List<ProjectUnit> getUnitsForFloor(int floor) {
    if (_currentProject == null) return [];

    return _currentProject!.units.where((unit) => unit.floor == floor).toList();
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

  int _resolveReplanStartIndex(List<ProjectPhase> phases) {
    final activeIndex = phases.indexWhere((phase) => phase.isActive);
    if (activeIndex != -1) {
      return activeIndex;
    }

    final now = DateTime.now();
    final firstNotEndedIndex = phases.indexWhere(
      (phase) => now.isBefore(phase.endDate),
    );
    if (firstNotEndedIndex != -1) {
      return firstNotEndedIndex;
    }

    return phases.length - 1;
  }

  ConstructionProject _normalizeProject(ConstructionProject project) {
    final recurringSynced = _syncRecurringAlertsForProject(project);
    return _syncProjectAreasForProject(recurringSynced);
  }

  ConstructionProject _syncProjectAreasForProject(
    ConstructionProject project,
  ) {
    final definitions = ProjectAreaCatalog.buildDefinitions(project);
    final existingById = {
      for (final area in project.areaProgress) area.areaId: area,
    };

    final syncedAreas = definitions.map((definition) {
      final existing = existingById[definition.id];
      final statuses = <String, TaskStatus>{};
      final completionDates = <String, DateTime?>{};

      for (final item in definition.checklist) {
        statuses[item.id] = existing?.taskStatuses[item.id] ?? TaskStatus.pending;
        completionDates[item.id] = existing?.taskCompletionDates[item.id];
      }

      return ProjectAreaProgress(
        areaId: definition.id,
        areaType: definition.type,
        taskStatuses: statuses,
        taskCompletionDates: completionDates,
        photoPaths: existing?.photoPaths ?? const [],
        notes: existing?.notes ?? '',
      );
    }).toList();

    if (_areaProgressEquals(project.areaProgress, syncedAreas)) {
      return project;
    }

    return ConstructionProject(
      projectId: project.projectId,
      config: project.config,
      phases: project.phases,
      allTasks: project.allTasks,
      alerts: project.alerts,
      recurringAlerts: project.recurringAlerts,
      units: project.units,
      areaProgress: syncedAreas,
      createdAt: project.createdAt,
      lastModifiedAt: project.lastModifiedAt,
    );
  }

  bool _areaProgressEquals(
    List<ProjectAreaProgress> left,
    List<ProjectAreaProgress> right,
  ) {
    if (left.length != right.length) return false;

    for (var index = 0; index < left.length; index++) {
      final a = left[index];
      final b = right[index];
      if (a.areaId != b.areaId || a.areaType != b.areaType) {
        return false;
      }
      if (a.notes != b.notes) {
        return false;
      }
      if (a.photoPaths.length != b.photoPaths.length) {
        return false;
      }
      for (var photoIndex = 0; photoIndex < a.photoPaths.length; photoIndex++) {
        if (a.photoPaths[photoIndex] != b.photoPaths[photoIndex]) {
          return false;
        }
      }
      if (a.taskStatuses.length != b.taskStatuses.length) {
        return false;
      }
      for (final entry in a.taskStatuses.entries) {
        if (b.taskStatuses[entry.key] != entry.value) {
          return false;
        }
      }
    }

    return true;
  }

  ChecklistTask _copyTaskWithReplannedDueDate(
    ChecklistTask task,
    Map<BuildingStage, ProjectPhase> phaseByStage,
  ) {
    if (task.status == TaskStatus.completed) {
      return task;
    }

    final phase = phaseByStage[task.stage];
    final dueDate = phase == null
        ? task.dueDate
        : phase.endDate.subtract(Duration(days: task.daysBeforeStageEnd));

    return ChecklistTask(
      id: task.id,
      title: task.title,
      description: task.description,
      system: task.system,
      stage: task.stage,
      daysBeforeStageEnd: task.daysBeforeStageEnd,
      status: task.status,
      completedDate: task.completedDate,
      dueDate: dueDate,
      dependsOnTaskIds: task.dependsOnTaskIds,
      notes: task.notes,
      attachmentPaths: task.attachmentPaths,
      unitIds: task.unitIds,
    );
  }

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
    return system.displayName;
  }
}

class WeeklyExecutionSnapshot {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int plannedCount;
  final int completedCount;
  final int plannedCompletedCount;
  final int plannedOpenCount;
  final int overdueOpenCount;
  final int carryOverCount;
  final int onTimeCompletedCount;
  final List<ChecklistTask> topOverdueTasks;

  const WeeklyExecutionSnapshot({
    required this.weekStart,
    required this.weekEnd,
    required this.plannedCount,
    required this.completedCount,
    required this.plannedCompletedCount,
    required this.plannedOpenCount,
    required this.overdueOpenCount,
    required this.carryOverCount,
    required this.onTimeCompletedCount,
    required this.topOverdueTasks,
  });

  factory WeeklyExecutionSnapshot.empty({
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    return WeeklyExecutionSnapshot(
      weekStart: weekStart,
      weekEnd: weekEnd,
      plannedCount: 0,
      completedCount: 0,
      plannedCompletedCount: 0,
      plannedOpenCount: 0,
      overdueOpenCount: 0,
      carryOverCount: 0,
      onTimeCompletedCount: 0,
      topOverdueTasks: const [],
    );
  }

  double get planCompletionRate {
    if (plannedCount == 0) return 1.0;
    return plannedCompletedCount / plannedCount;
  }

  int get varianceCount => completedCount - plannedCount;

  String get varianceLabel {
    if (varianceCount > 0) return '+$varianceCount';
    return '$varianceCount';
  }
}
