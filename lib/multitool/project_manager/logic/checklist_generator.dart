import 'package:uuid/uuid.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';

/// Inteligentny generator checklist'u z automatycznym planowaniem
/// System analizuje typ budowy, systemy, etapy i generuje zadania
/// z właściwym czasowaniem i alertami
/// 
/// Integracja z bazą danych harmonogramu budowy:
/// - Dane z dokumentu o etapach budowy budynków mieszkalnych i biurowych
/// - Dynamiczne dostosowywanie harmonogramu na podstawie liczby pięter i garaży
/// - Specjalistyczne kroki dla pomezczczeń podziemnych
class ProjectChecklistGenerator {
  static const _uuid = Uuid();

  /// Generuj kompletnylista checklist dla projektu
  static ConstructionProject generateProject(
    BuildingConfiguration config,
  ) {
    final projectId = _uuid.v4();
    
    // 1. Oblicz harmonogram na podstawie całkowitego czasu budowy
    final schedule = ScheduleCalculator.calculateSchedule(config);
    
    // 2. Generuj fazy budowy (etapy z datami)
    final phases = ScheduleCalculator.generatePhases(config, schedule);
    
    // 3. Generuj wszystkie zadania dla wybranych systemów
    var allTasks = _generateAllTasks(config, phases);
    
    // 4. Oznacz zadania jako wykonane jeśli etap już się skończył
    allTasks = _markCompletedTasksByStage(allTasks, config.currentBuildingStage);
    
    // 5. Generuj jednostki (mieszkania, biura)
    final units = _generateUnits(config, allTasks);
    
    // 6. Stwórz projekt
    var project = ConstructionProject(
      projectId: projectId,
      config: config,
      phases: phases,
      allTasks: allTasks,
      units: units,
    );
    
    // 7. Generuj początkowe alerty
    final initialAlerts = _generateInitialAlerts(project);
    project = ConstructionProject(
      projectId: project.projectId,
      config: project.config,
      phases: project.phases,
      allTasks: project.allTasks,
      alerts: initialAlerts,
      units: project.units,
    );
    
    return project;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OZNACZANIE WYKONANYCH ZADAŃ NA PODSTAWIE AKTUALNEGO ETAPU
  // ═══════════════════════════════════════════════════════════════════════

  static List<ChecklistTask> _markCompletedTasksByStage(
    List<ChecklistTask> tasks,
    BuildingStage currentStage,
  ) {
    final stageOrder = BuildingStage.values.toList();
    final currentStageIndex = stageOrder.indexOf(currentStage);

    return tasks.map((task) {
      final taskStageIndex = stageOrder.indexOf(task.stage);
      
      // Jeśli zadanie jest z etapu wcześniejszego niż aktualny, oznacz jako wykonane
      if (taskStageIndex < currentStageIndex) {
        return ChecklistTask(
          id: task.id,
          title: task.title,
          description: task.description,
          system: task.system,
          stage: task.stage,
          daysBeforeStageEnd: task.daysBeforeStageEnd,
          status: TaskStatus.completed,
          completedDate: DateTime.now(),
          dueDate: task.dueDate,
          dependsOnTaskIds: task.dependsOnTaskIds,
          notes: '${task.notes}\n[AUTOMATYCZNIE OZNACZONE JAKO WYKONANE]',
          attachmentPaths: task.attachmentPaths,
          unitIds: task.unitIds,
        );
      }
      return task;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENEROWANIE ZADAŃ DLA SYSTEMÓW
  // ═══════════════════════════════════════════════════════════════════════

  static List<ChecklistTask> _generateAllTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    final allTasks = <ChecklistTask>[];
    
    // Zadania specyficzne dla lokali mieszkalnych
    if (config.buildingType == BuildingType.mieszkalny && config.estimatedUnits > 1) {
      allTasks.addAll(_generateResidentialUnitTasks(config));
    }
    
    return allTasks;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERATOR ZADAŃ DLA LOKALI MIESZKALNYCH
  // (podstawa: lista prac lokale mieszkalne.xlsx)
  // ═══════════════════════════════════════════════════════════════════════

  static List<ChecklistTask> _generateResidentialUnitTasks(
    BuildingConfiguration config,
  ) {
    final tasks = <ChecklistTask>[];
    final unitIds = _generateUnitIds(config);

    // T1: Projekt zamienny
    tasks.add(ChecklistTask(
      id: 'unit-01-alt-project',
      title: 'Projekt zamienny:',
      description: 'Przygotuj lub zatwierdź projekt zamienny dla lokalu ze zmianami lokatorskimi. Oznacz "Nie dotyczy" jeśli standard.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przygotowanie,
      daysBeforeStageEnd: 14,
      unitIds: unitIds,
    ));

    // T2: Ścianki działowe
    tasks.add(ChecklistTask(
      id: 'unit-02-partition-walls',
      title: 'Ścianki działowe:',
      description: 'Wykonanie ścianek działowych wewnętrznych zgodnie z projektem.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 14,
      unitIds: unitIds,
    ));

    // T3: Montaż okablowania
    tasks.add(ChecklistTask(
      id: 'unit-03-wiring',
      title: 'Montaż okablowania:',
      description: 'Rozprowadzenie przewodów elektrycznych w lokalu. PRZED tynkami!',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-02-partition-walls'],
      unitIds: unitIds,
    ));

    // T4: Montaż okablowania na balkonie/loggi/ogródku
    tasks.add(ChecklistTask(
      id: 'unit-04-wiring-outdoor',
      title: 'Montaż okablowania na balkonie, loggy, ogródku:',
      description: 'Okablowanie zewnętrznych przestrzeni przynależnych do lokalu.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-03-wiring'],
      unitIds: unitIds,
    ));

    // T5: Montaż puszek elektroinstalacyjnych
    tasks.add(ChecklistTask(
      id: 'unit-05-socket-boxes',
      title: 'Montaż puszek elektroinstalacyjnych:',
      description: 'Osadzenie puszek podtynkowych dla gniazd, włączników, lamp. PRZED tynkami!',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 3,
      dependsOnTaskIds: ['unit-03-wiring'],
      unitIds: unitIds,
    ));

    // T6: Dokumentacja fotograficzna okablowania
    tasks.add(ChecklistTask(
      id: 'unit-06-wiring-photos',
      title: 'Dokumentacja fotograficzna okablowania:',
      description: 'Wykonaj zdjęcia tras przewodów PRZED zakryciem tynkami. Ważne dla późniejszych serwisów.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 1,
      dependsOnTaskIds: ['unit-04-wiring', 'unit-05-socket-boxes'],
      unitIds: unitIds,
    ));

    // T7: Doprowadzenie kabla WLZ
    tasks.add(ChecklistTask(
      id: 'unit-07-wlz-cable',
      title: 'Doprowadzenie kabla WLZ:',
      description: 'Kabel od licznika głównego do tablicy mieszkaniowej (Wewnętrzna Linia Zasilająca).',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 7,
      unitIds: unitIds,
    ));

    // T8: Odbiory inspektora nadzoru inwestorskiego
    tasks.add(ChecklistTask(
      id: 'unit-08-inspector-check-1',
      title: 'Odbiory inspektora nadzoru inwestorskiego:',
      description: 'Inspekcja ukrytych tras okablowania przez inspektora nadzoru. PRZED tynkami!',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 1,
      dependsOnTaskIds: ['unit-06-wiring-photos'],
      unitIds: unitIds,
    ));

    // T9: Tynki
    tasks.add(ChecklistTask(
      id: 'unit-09-plastering',
      title: 'Tynki:',
      description: 'Wykonanie tynków wewnętrznych. Status: wykonane / w trakcie.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.tynki,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-08-inspector-check-1'],
      unitIds: unitIds,
    ));

    // T10: Wykonanie pomiaru Riso
    tasks.add(ChecklistTask(
      id: 'unit-10-riso-measurement',
      title: 'Wykonanie pomiaru Riso:',
      description: 'Pomiar rezystancji izolacji instalacji elektrycznej (Riso). Wymagany protokół.',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.tynki,
      daysBeforeStageEnd: 3,
      dependsOnTaskIds: ['unit-09-plastering'],
      unitIds: unitIds,
    ));

    // T11: Ułożenie rur osłonowych pod instalacje teletechniczne
    tasks.add(ChecklistTask(
      id: 'unit-11-telecom-conduits',
      title: 'Ułożenie rur osłonowych pod instalacje teletechniczną:',
      description: 'Rury osłonowe dla kabli teletechnicznych (internet, TV, domofon). PRZED wylewką!',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 7,
      unitIds: unitIds,
    ));

    // T12: Dokumentacja fotograficzna rur osłonowych
    tasks.add(ChecklistTask(
      id: 'unit-12-conduits-photos',
      title: 'Dokumentacja fotograficzna rur osłonowych:',
      description: 'Zdjęcia tras rur teletechnicznych PRZED wylewką.',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 3,
      dependsOnTaskIds: ['unit-11-telecom-conduits'],
      unitIds: unitIds,
    ));

    // T13: Jastrych (wylewka)
    tasks.add(ChecklistTask(
      id: 'unit-13-screed',
      title: 'Jastrych (wylewka):',
      description: 'Wykonanie wylewki podłogowej. Status: wykonane / w trakcie.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-12-conduits-photos'],
      unitIds: unitIds,
    ));

    // T14: Doprowadzenie okablowania teletechnicznego w rurach
    tasks.add(ChecklistTask(
      id: 'unit-14-telecom-cables',
      title: 'Doprowadzenie okablowania teletechnicznego w rurach:',
      description: 'Przeciągnięcie kabli UTP, koncentrycznych, domofonu w rurach osłonowych.',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 3,
      dependsOnTaskIds: ['unit-11-telecom-conduits', 'unit-13-screed'],
      unitIds: unitIds,
    ));

    // T15: Malowanie
    tasks.add(ChecklistTask(
      id: 'unit-15-painting',
      title: 'Malowanie:',
      description: 'Malowanie ścian i sufitów. Status: wykonane / w trakcie.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.malowanie,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-13-screed'],
      unitIds: unitIds,
    ));

    // T16: Montaż tablicy mieszkaniowej elektrycznej - TM
    tasks.add(ChecklistTask(
      id: 'unit-16-electrical-panel',
      title: 'Montaż tablicy mieszkaniowej elektrycznej - TM:',
      description: 'Instalacja rozdzielnicy mieszkaniowej (TM) z zabezpieczeniami.',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 14,
      dependsOnTaskIds: ['unit-07-wlz-cable'],
      unitIds: unitIds,
    ));

    // T17: Podłączenie tablicy mieszkaniowej
    tasks.add(ChecklistTask(
      id: 'unit-17-panel-connection',
      title: 'Podłączenie tablicy mieszkaniowej:',
      description: 'Podłączenie wszystkich obwodów do rozdzielnicy TM. Test zabezpieczeń.',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 10,
      dependsOnTaskIds: ['unit-16-electrical-panel'],
      unitIds: unitIds,
    ));

    // T18: Montaż teletechnicznej skrzynki mieszkaniowej - TSM
    tasks.add(ChecklistTask(
      id: 'unit-18-telecom-box',
      title: 'Montaż teletechnicznej skrzynki mieszkaniowej - TSM:',
      description: 'Instalacja skrzynki TSM dla terminacji kabli teletechnicznych.',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 10,
      dependsOnTaskIds: ['unit-14-telecom-cables'],
      unitIds: unitIds,
    ));

    // T19: Montaż osprzętu
    tasks.add(ChecklistTask(
      id: 'unit-19-fixtures',
      title: 'Montaż osprzętu:',
      description: 'Montaż gniazd, włączników, anten RTV, gniazd RJ45.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-15-painting', 'unit-17-panel-connection'],
      unitIds: unitIds,
    ));

    // T20: Montaż unifonu, wideodomofonu
    tasks.add(ChecklistTask(
      id: 'unit-20-intercom',
      title: 'Montaż unifonu, wideodomofonu:',
      description: 'Instalacja słuchawki/monitora domofonu w mieszkaniu.',
      system: ElectricalSystemType.domofonowa,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-18-telecom-box'],
      unitIds: unitIds,
    ));

    // T21: Montaż czujnika dymu
    tasks.add(ChecklistTask(
      id: 'unit-21-smoke-detector',
      title: 'Montaż czujnika dymu:',
      description: 'Instalacja czujników dymu zgodnie z przepisami p.poż.',
      system: ElectricalSystemType.ppoz,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-15-painting'],
      unitIds: unitIds,
    ));

    // T22: Montaż oprawek oświetleniowych
    tasks.add(ChecklistTask(
      id: 'unit-22-light-fixtures',
      title: 'Montaż oprawek oświetleniowych:',
      description: 'Montaż opraw/żyrandoli sufitowych i kinkietów ściennych.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.malowanie,
      daysBeforeStageEnd: 3,
      dependsOnTaskIds: ['unit-19-fixtures'],
      unitIds: unitIds,
    ));

    // T23: Uruchomienie instalacji domofonowej
    tasks.add(ChecklistTask(
      id: 'unit-23-intercom-activation',
      title: 'Uruchomienie instalacji domofonowej:',
      description: 'Konfiguracja i test połączenia domofonu. Sprawdzenie audio/wideo.',
      system: ElectricalSystemType.domofonowa,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-20-intercom'],
      unitIds: unitIds,
    ));

    // T24: Pomiary teletechniczne
    tasks.add(ChecklistTask(
      id: 'unit-24-telecom-measurements',
      title: 'Pomiary teletechniczne:',
      description: 'Pomiary sieci teletechnicznych (testy UTP, sygnał TV, domofon). Protokoły.',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 5,
      dependsOnTaskIds: ['unit-18-telecom-box', 'unit-23-intercom-activation'],
      unitIds: unitIds,
    ));

    // T25: Pomiary elektryczne
    tasks.add(ChecklistTask(
      id: 'unit-25-electrical-measurements',
      title: 'Pomiary elektryczne:',
      description: 'Kompleksowe pomiary instalacji elektrycznej (Riso, pętle zwarciowe, sprawność wyłączników). Protokoły odbiorcze.',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 5,
      dependsOnTaskIds: ['unit-17-panel-connection', 'unit-19-fixtures'],
      unitIds: unitIds,
    ));

    // T26: Odbiory inspektora nadzoru inwestorskiego - I termin
    tasks.add(ChecklistTask(
      id: 'unit-26-inspector-check-2',
      title: 'Odbiory inspektora nadzoru inwestorskiego I termin:',
      description: 'Pierwszy termin odbioru przez inspektora nadzoru. Weryfikacja kompletności.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: ['unit-24-telecom-measurements', 'unit-25-electrical-measurements'],
      unitIds: unitIds,
    ));

    // T27: Odbiory inspektora nadzoru inwestorskiego - II termin
    tasks.add(ChecklistTask(
      id: 'unit-27-inspector-check-3',
      title: 'Odbiory inspektora nadzoru inwestorskiego II termin:',
      description: 'Drugi termin odbioru - usunięcie uwag z I terminu.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 3,
      dependsOnTaskIds: ['unit-26-inspector-check-2'],
      unitIds: unitIds,
    ));

    // T28: Odbiory inspektora nadzoru inwestorskiego - końcowe
    tasks.add(ChecklistTask(
      id: 'unit-28-inspector-final',
      title: 'Odbiory inspektora nadzoru inwestorskiego końcowe:',
      description: 'Odbiór końcowy lokalu. Protokół przekazania.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.oddawanie,
      daysBeforeStageEnd: 0,
      dependsOnTaskIds: ['unit-27-inspector-check-3'],
      unitIds: unitIds,
    ));

    return tasks;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENEROWANIE JEDNOSTEK (MIESZKAŃ)
  // ═══════════════════════════════════════════════════════════════════════

  static String _getSystemName(ElectricalSystemType system) {
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
        return 'Panele PV';
      case ElectricalSystemType.ladownarki:
        return 'Ładowarki samochodowe';
      case ElectricalSystemType.ppoz:
        return 'System ppoż';
      case ElectricalSystemType.cctv:
        return 'CCTV/Monitoring';
      case ElectricalSystemType.dso:
        return 'DSO (detekcja dymu)';
      case ElectricalSystemType.internet:
        return 'Internet/Lan';
      case ElectricalSystemType.gaszeniGazem:
        return 'Gaszenie gazem';
      case ElectricalSystemType.oddymianieKlatek:
        return 'Oddymianie klatek';
      default:
        return system.toString();
    }
  }

  static List<ProjectUnit> _generateUnits(
    BuildingConfiguration config,
    List<ChecklistTask> allTasks,
  ) {
    final units = <ProjectUnit>[];

    if (config.estimatedUnits <= 1) {
      return units; // Dla domków jednorodzinnych nie ma jednostek
    }

    final unitIds = _generateUnitIds(config);

    for (final unitId in unitIds) {
      final taskStatuses = <String, TaskStatus>{};
      final taskCompletionDates = <String, DateTime?>{};
      final isAlternateUnit = false;

      // Każda jednostka ma te same zadania
      for (final task in allTasks) {
        if (task.id == kAlternateProjectTaskId && !isAlternateUnit) {
          continue;
        }
        if (task.unitIds == null || task.unitIds!.contains(unitId)) {
          taskStatuses[task.id] = TaskStatus.pending;
          taskCompletionDates[task.id] = null;
        }
      }

      units.add(
        ProjectUnit(
          unitId: unitId,
          unitName: _getUnitName(config, unitId),
          floor: _getFloorFromUnitId(unitId),
          stairCase: _getStairCaseFromUnitId(config, unitId),
          isAlternateUnit: isAlternateUnit,
          taskStatuses: taskStatuses,
          taskCompletionDates: taskCompletionDates,
        ),
      );
    }

    return units;
  }

  static List<String> _generateUnitIds(BuildingConfiguration config) {
    final unitIds = <String>[];

    if (config.estimatedUnits <= 1) return unitIds;

    // Iteruj po budynkach
    for (int buildingIdx = 0; buildingIdx < config.buildings.length; buildingIdx++) {
      final building = config.buildings[buildingIdx];
      
      // Iteruj po klatach w budynku
      for (final stairCase in building.stairCases) {
        // Iteruj po piętrach w klatce
        for (int floor = 1; floor <= stairCase.numberOfLevels; floor++) {
          // Pobierz liczbę mieszkań na tym piętrze
          final unitsOnFloor = stairCase.unitsPerFloor[floor] ?? 2;
          
          // Generuj ID dla każdego mieszkania na piętrze
          for (int unitNum = 1; unitNum <= unitsOnFloor; unitNum++) {
            if (unitIds.length < config.estimatedUnits) {
              // Format: B1-A101 (Building 1, Staircase A, Floor 1, Unit 01)
              final buildingNum = buildingIdx + 1;
              final floorCode = floor * 100 + unitNum;
              final unitId = 'B$buildingNum-${stairCase.stairCaseName}$floorCode';
              unitIds.add(unitId);
            }
          }
        }
      }
    }

    return unitIds;
  }

  static String _getUnitName(BuildingConfiguration config, String unitId) {
    return 'Mieszkanie $unitId';
  }

  static int _getFloorFromUnitId(String unitId) {
    // Supported formats:
    // - B1-A101 -> floor 1
    // - A101 -> floor 1
    final parts = unitId.split('-');
    final core = parts.length > 1 ? parts.last : unitId;
    if (core.isEmpty) return 0;
    final numPart = int.tryParse(core.substring(1));
    if (numPart == null) return 0;
    return numPart ~/ 100; // Setki to pietro
  }

  static String _getStairCaseFromUnitId(
    BuildingConfiguration config,
    String unitId,
  ) {
    // Supported formats:
    // - B1-A101 -> stair A
    // - A101 -> stair A
    final parts = unitId.split('-');
    final core = parts.length > 1 ? parts.last : unitId;
    if (core.isEmpty) return '';
    return core[0];
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENEROWANIE ALERTÓW
  // ═══════════════════════════════════════════════════════════════════════

  static List<ProjectAlert> _generateInitialAlerts(ConstructionProject project) {
    final alerts = <ProjectAlert>[];

    // Alert: Pamiętaj o wysłaniu rozdzielnic!
    var prefabDate = project.config.prefabrication4WeeksBefore;
    var daysDifference = prefabDate.difference(DateTime.now()).inDays;

    if (daysDifference > 0 && daysDifference <= 7) {
      alerts.add(ProjectAlert(
        id: _uuid.v4(),
        severity: AlertSeverity.critical,
        title: '⚠️ PILNIE: Rozdzielnice do prefabrykacji!',
        message:
          'Za $daysDifference dni powinny być wysłane rozdzielnice do prefabrykacji. '
          'Czas realizacji: 4-6 tygodni! Brak tego działania spowoduje znaczne opóźnienia projektu.',
        actionSuggestion: 'Natychmiast skontaktuj się z dostawcą i potwierdź wysyłkę',
        relatedTaskId: project.allTasks
            .firstWhere(
              (t) => t.title.contains('prefabrykacji'),
              orElse: () => project.allTasks.first,
            )
            .id,
      ));
    }

    // Alert: Ostatnia szansa na kable!
    final tynkiStage = project.phases.firstWhere((p) => p.stage == BuildingStage.tynki);
    var daysTillTynki = tynkiStage.startDate.difference(DateTime.now()).inDays;

    if (daysTillTynki > 0 && daysTillTynki <= 7) {
      alerts.add(ProjectAlert(
        id: _uuid.v4(),
        severity: AlertSeverity.urgent,
        title: '🚨 Za $daysTillTynki dni zaczynają się tynki!',
        message:
          'OSTATNIA SZANSA ułożyć kable w ścianach, pod posadzkami i wewnątrz struktu ry! '
          'Po tynkach będzie za późno!',
        actionSuggestion: 'Sprawdź status wszystkich zadań związanych z ułożeniem kabli',
      ));
    }

    // Alert: Zadania zaplanowane na dzisiaj
    final tasksForToday = project.allTasks
        .where((t) => t.dueDate?.difference(DateTime.now()).inDays == 0)
        .toList();

    if (tasksForToday.isNotEmpty) {
      alerts.add(ProjectAlert(
        id: _uuid.v4(),
        severity: AlertSeverity.warning,
        title: 'Zadania zaplanowane na dzisiaj',
        message:
          'Masz ${tasksForToday.length} zadań do wykonania dzisiaj. '
          'Pamiętaj o dokumentacji fotograficznej!',
        actionSuggestion: 'Przejrzyj listę zadań na dzisiaj',
      ));
    }

    return alerts;
  }
}
