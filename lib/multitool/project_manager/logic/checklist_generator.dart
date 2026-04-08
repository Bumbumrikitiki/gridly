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
    try {
      final projectId = _uuid.v4();
      print('[Generator] Generowanie projektu dla: ${config.projectName}');
      print('[Generator] - Budynki: ${config.buildings.length}');
      print('[Generator] - Jednostki: ${config.estimatedUnits}');

      // 1. Oblicz harmonogram na podstawie całkowitego czasu budowy
      final schedule = ScheduleCalculator.calculateSchedule(config);

      // 2. Generuj fazy budowy (etapy z datami)
      final phases = ScheduleCalculator.generatePhases(config, schedule);

      // 3. Generuj wszystkie zadania dla wybranych systemów
      var allTasks = _generateAllTasks(config, phases);

      // 3a. Podłącz realne terminy zadań do faz harmonogramu.
      allTasks = _assignTaskDueDates(allTasks, phases);

      // 4. Oznacz zadania jako wykonane jeśli etap już się skończył
      allTasks =
          _markCompletedTasksByStage(allTasks, config.currentBuildingStage);

      // 5. Generuj jednostki (mieszkania, biura)
      final units = _generateUnits(config, allTasks);
      print('[Generator] - Wygenerowane jednostki: ${units.length}');

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
      print('[Generator] - Wygenerowane alerty: ${initialAlerts.length}');

      project = ConstructionProject(
        projectId: project.projectId,
        config: project.config,
        phases: project.phases,
        allTasks: project.allTasks,
        alerts: initialAlerts,
        units: project.units,
      );

      print('[Generator] Projekt wygenerowany pomyślnie');
      return project;
    } catch (e, stackTrace) {
      print('[Generator] Błąd generowania projektu: $e');
      print('[Generator] Stack trace: $stackTrace');
      rethrow;
    }
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

    // Zadania infrastruktury zasilania wspólne dla budynku.
    allTasks.addAll(_generatePowerInfrastructureTasks(config));

    // Zadania dla systemow OZE i backupu wynikajace z konfiguracji zasilania.
    allTasks.addAll(_generatePowerResilienceTasks(config));

    // Dedykowane zadania dla wszystkich wybranych systemow z generatora.
    allTasks.addAll(_generateSelectedSystemsTasks(config));

    // Zadania specyficzne dla lokali mieszkalnych
    if (config.buildingType == BuildingType.mieszkalny &&
        config.estimatedUnits > 1) {
      allTasks.addAll(_generateResidentialUnitTasks(config));
    }

    return allTasks;
  }

  static List<ChecklistTask> _generateSelectedSystemsTasks(
    BuildingConfiguration config,
  ) {
    final tasks = <ChecklistTask>[];

    for (final system in config.selectedSystems) {
      tasks.addAll(_buildDedicatedSystemTasks(system));
    }

    return tasks;
  }

  static List<ChecklistTask> _buildDedicatedSystemTasks(
    ElectricalSystemType system,
  ) {
    final executionStage = _systemExecutionStage(system);
    final acceptanceStage = _systemAcceptanceStage(system);

    final baseId = 'sys-${system.name}';
    final label = system.displayName;

    return [
      ChecklistTask(
        id: '$baseId-01-projekt',
        title: 'Projekt: $label',
        description:
            'Przygotuj projekt wykonawczy systemu "$label" i skoordynuj przebiegi tras z innymi instalacjami.',
        system: system,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 14,
      ),
      ChecklistTask(
        id: '$baseId-02-montaz',
        title: 'Montaż: $label',
        description:
            'Wykonaj montaż i podłączenia systemu "$label" zgodnie z dokumentacją wykonawczą.',
        system: system,
        stage: executionStage,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['$baseId-01-projekt'],
      ),
      ChecklistTask(
        id: '$baseId-03-odbior',
        title: 'Testy i odbiór: $label',
        description:
            'Przeprowadź testy funkcjonalne, pomiary oraz odbiór końcowy systemu "$label".',
        system: system,
        stage: acceptanceStage,
        daysBeforeStageEnd: 1,
        dependsOnTaskIds: ['$baseId-02-montaz'],
      ),
    ];
  }

  static BuildingStage _systemExecutionStage(ElectricalSystemType system) {
    switch (system) {
      case ElectricalSystemType.wlz:
      case ElectricalSystemType.trasyKablowe:
      case ElectricalSystemType.uziemieniePolaczeniaWyrownawcze:
      case ElectricalSystemType.odgromowa:
        return BuildingStage.przegrody;
      case ElectricalSystemType.rozdzielniceRgRnnRsn:
      case ElectricalSystemType.zasilanie:
      case ElectricalSystemType.ups:
      case ElectricalSystemType.szr:
      case ElectricalSystemType.dualFeedSn:
      case ElectricalSystemType.ukladyPomiarowe:
      case ElectricalSystemType.podlicznikiEnergii:
      case ElectricalSystemType.analizatorySieci:
      case ElectricalSystemType.ems:
      case ElectricalSystemType.gniazdaDedykowane:
      case ElectricalSystemType.oswietlenie:
      case ElectricalSystemType.oswietlenieAwaryjneEwakuacyjne:
      case ElectricalSystemType.floorboxy:
      case ElectricalSystemType.zasilanieStanowiskPracy:
      case ElectricalSystemType.ladownarki:
      case ElectricalSystemType.windaAscensor:
      case ElectricalSystemType.podgrzewanePodjazdy:
      case ElectricalSystemType.ogrzewanieRur:
      case ElectricalSystemType.cctv:
      case ElectricalSystemType.kd:
      case ElectricalSystemType.sswim:
      case ElectricalSystemType.ppoz:
      case ElectricalSystemType.dso:
      case ElectricalSystemType.czujnikiRuchu:
      case ElectricalSystemType.gaszeniGazem:
      case ElectricalSystemType.wykrywaniWyciekow:
      case ElectricalSystemType.oddymianieKlatek:
      case ElectricalSystemType.domofonowa:
      case ElectricalSystemType.telewizja:
      case ElectricalSystemType.internet:
      case ElectricalSystemType.lan:
      case ElectricalSystemType.swiatlowod:
      case ElectricalSystemType.wifi:
      case ElectricalSystemType.voip:
      case ElectricalSystemType.dataRoom:
      case ElectricalSystemType.av:
      case ElectricalSystemType.digitalSignage:
      case ElectricalSystemType.klimatyzacja:
      case ElectricalSystemType.wentylacja:
      case ElectricalSystemType.automatykaHvac:
      case ElectricalSystemType.smartHome:
      case ElectricalSystemType.bms:
      case ElectricalSystemType.integracjaSystemow:
      case ElectricalSystemType.psimSms:
      case ElectricalSystemType.rezerwacjaSal:
      case ElectricalSystemType.itp:
        return BuildingStage.osprzet;
      case ElectricalSystemType.panelePV:
      case ElectricalSystemType.magazynEnergii:
      case ElectricalSystemType.agregat:
      case ElectricalSystemType.ewakuacyjne:
        return BuildingStage.finalizacja;
    }
  }

  static BuildingStage _systemAcceptanceStage(ElectricalSystemType system) {
    switch (system) {
      case ElectricalSystemType.panelePV:
      case ElectricalSystemType.magazynEnergii:
        return BuildingStage.ozeInstalacje;
      case ElectricalSystemType.ladownarki:
        return BuildingStage.evInfrastruktura;
      case ElectricalSystemType.ppoz:
      case ElectricalSystemType.dso:
      case ElectricalSystemType.gaszeniGazem:
      case ElectricalSystemType.kd:
      case ElectricalSystemType.cctv:
      case ElectricalSystemType.sswim:
      case ElectricalSystemType.wykrywaniWyciekow:
      case ElectricalSystemType.oswietlenieAwaryjneEwakuacyjne:
      case ElectricalSystemType.ewakuacyjne:
      case ElectricalSystemType.psimSms:
        return BuildingStage.oddawanie;
      default:
        return BuildingStage.finalizacja;
    }
  }

  static List<ChecklistTask> _assignTaskDueDates(
    List<ChecklistTask> tasks,
    List<ProjectPhase> phases,
  ) {
    final phaseByStage = <BuildingStage, ProjectPhase>{
      for (final phase in phases) phase.stage: phase,
    };

    return tasks.map((task) {
      final phase = phaseByStage[task.stage];
      if (phase == null) {
        return task;
      }

      final dueDate = phase.endDate.subtract(
        Duration(days: task.daysBeforeStageEnd),
      );

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
    }).toList();
  }

  static List<ChecklistTask> _generatePowerInfrastructureTasks(
    BuildingConfiguration config,
  ) {
    final tasks = <ChecklistTask>[];

    switch (config.powerSupplyArchitecture) {
      case PowerSupplyArchitectureType.lvDirect:
        tasks.add(
          ChecklistTask(
            id: 'ps-lv-direct-001',
            title: 'Uzgodnij zasilanie LV_DIRECT (ZK -> WLZ -> RG)',
            description:
                'Potwierdz trase i parametry dla ukladu siec nN -> ZK/ZKP -> WLZ -> RG.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.przygotowanie,
            daysBeforeStageEnd: 21,
          ),
        );
        break;
      case PowerSupplyArchitectureType.lvWithMainBoard:
        tasks.addAll([
          ChecklistTask(
            id: 'ps-lv-main-001',
            title: 'Projekt RGnN i pionow dystrybucyjnych',
            description:
                'Opracuj sekcje RGnN oraz podzial pionow i odpływow wewnetrznych.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.przygotowanie,
            daysBeforeStageEnd: 21,
          ),
          ChecklistTask(
            id: 'ps-lv-main-002',
            title: 'Koordynacja selektywnosci i zabezpieczen RGnN',
            description:
                'Zweryfikuj selektywnosc i nastawy zabezpieczen dla rozbudowanej dystrybucji nN.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.osprzet,
            daysBeforeStageEnd: 7,
            dependsOnTaskIds: ['ps-lv-main-001'],
          ),
        ]);
        break;
      case PowerSupplyArchitectureType.mvTransformerSingle:
        tasks.addAll([
          ChecklistTask(
            id: 'ps-mv-single-001',
            title: 'Projekt stacji SN/nN - transformator T1',
            description:
                'Zaprojektuj relacje SN -> RSn -> T1 -> RGnN wraz z zabezpieczeniami.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.przygotowanie,
            daysBeforeStageEnd: 28,
          ),
          ChecklistTask(
            id: 'ps-mv-single-002',
            title: 'Uruchomienie i proby stacji SN/nN',
            description:
                'Wykonaj proby odbiorcze pola SN, transformatora i sekcji RGnN.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.oddawanie,
            daysBeforeStageEnd: 0,
            dependsOnTaskIds: ['ps-mv-single-001'],
          ),
        ]);
        break;
      case PowerSupplyArchitectureType.mvTransformerMulti:
        tasks.addAll([
          ChecklistTask(
            id: 'ps-mv-multi-001',
            title: 'Projekt wielotransformatorowy T1+T2',
            description:
                'Zaprojektuj prace rownolegla/sekwencyjna transformatorow i sekcjonowanie RG.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.przygotowanie,
            daysBeforeStageEnd: 28,
          ),
          ChecklistTask(
            id: 'ps-mv-multi-002',
            title: 'Test redundancji sekcji RG',
            description:
                'Sprawdz przejecie obciazenia pomiedzy sekcjami oraz warunki awaryjne.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.oddawanie,
            daysBeforeStageEnd: 0,
            dependsOnTaskIds: ['ps-mv-multi-001'],
          ),
        ]);
        break;
      case PowerSupplyArchitectureType.mvWithSwitchgear:
        tasks.add(
          ChecklistTask(
            id: 'ps-mv-sg-001',
            title: 'Konfiguracja rozdzielnicy SN wielopolowej',
            description:
                'Uzgodnij pola liniowe, transformatorowe i pomiarowe rozdzielnicy SN.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.przygotowanie,
            daysBeforeStageEnd: 28,
          ),
        );
        break;
      case PowerSupplyArchitectureType.mvDualFeed:
        tasks.addAll([
          ChecklistTask(
            id: 'ps-mv-dual-001',
            title: 'Projekt zasilania dwustronnego SN',
            description:
                'Zapewnij dwa niezalezne tory zasilania SN i warunki pracy rezerwowej.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.przygotowanie,
            daysBeforeStageEnd: 35,
          ),
          ChecklistTask(
            id: 'ps-mv-dual-002',
            title: 'Test automatyki SZR',
            description:
                'Wykonaj proby przelaczenia SZR miedzy zasilaniem podstawowym i rezerwowym.',
            system: ElectricalSystemType.zasilanie,
            stage: BuildingStage.oddawanie,
            daysBeforeStageEnd: 0,
            dependsOnTaskIds: ['ps-mv-dual-001'],
          ),
        ]);
        break;
    }

    return tasks;
  }

  static List<ChecklistTask> _generatePowerResilienceTasks(
    BuildingConfiguration config,
  ) {
    final tasks = <ChecklistTask>[];

    for (final backup in config.backupSystems) {
      switch (backup.type) {
        case BackupSystemType.ups:
          tasks.add(
            ChecklistTask(
              id: 'ps-backup-ups-${backup.priority}',
              title: 'Projekt i test systemu UPS',
              description:
                  'UPS priorytet ${backup.priority}, zakres ${backup.covers.name}, autonomia ${backup.autonomyMinutes ?? 0} min.',
              system: ElectricalSystemType.zasilanie,
              stage: BuildingStage.osprzet,
              daysBeforeStageEnd: 5,
            ),
          );
          break;
        case BackupSystemType.generator:
          tasks.add(
            ChecklistTask(
              id: 'ps-backup-gen-${backup.priority}',
              title: 'Montaż i test agregatu prądotwórczego',
              description:
                  'Generator priorytet ${backup.priority}, zakres ${backup.covers.name}, autonomia ${backup.autonomyMinutes ?? 0} min.',
              system: ElectricalSystemType.agregat,
              stage: BuildingStage.finalizacja,
              daysBeforeStageEnd: 3,
            ),
          );
          break;
        case BackupSystemType.upsGeneratorCombo:
          tasks.add(
            ChecklistTask(
              id: 'ps-backup-combo-${backup.priority}',
              title: 'Integracja UPS + generator',
              description:
                  'Uklad hybrydowy UPS+GEN, priorytet ${backup.priority}, zakres ${backup.covers.name}, autonomia ${backup.autonomyMinutes ?? 0} min.',
              system: ElectricalSystemType.zasilanie,
              stage: BuildingStage.finalizacja,
              daysBeforeStageEnd: 2,
            ),
          );
          break;
      }
    }

    for (final renewable in config.renewableSystems) {
      if (renewable.type == RenewableSystemType.pvOnGrid ||
          renewable.type == RenewableSystemType.pvWithStorage) {
        tasks.add(
          ChecklistTask(
            id: 'ps-pv-${renewable.type.name}',
            title: renewable.type == RenewableSystemType.pvWithStorage
                ? 'Integracja PV z magazynem energii'
                : 'Integracja PV on-grid',
            description:
                'Moc ${renewable.powerKW?.toStringAsFixed(1) ?? '-'} kW, integracja backup: ${renewable.integratedWithBackup ? 'tak' : 'nie'}.',
            system: ElectricalSystemType.panelePV,
            stage: BuildingStage.ozeInstalacje,
            daysBeforeStageEnd: 0,
          ),
        );
      }
    }

    return tasks;
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
      description:
          'Przygotuj lub zatwierdź projekt zamienny dla lokalu ze zmianami lokatorskimi. Oznacz "Nie dotyczy" jeśli standard.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przygotowanie,
      daysBeforeStageEnd: 14,
      unitIds: unitIds,
    ));

    // T2: Ścianki działowe
    tasks.add(ChecklistTask(
      id: 'unit-02-partition-walls',
      title: 'Ścianki działowe:',
      description:
          'Wykonanie ścianek działowych wewnętrznych zgodnie z projektem.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 14,
      unitIds: unitIds,
    ));

    // T3: Montaż okablowania
    tasks.add(ChecklistTask(
      id: 'unit-03-wiring',
      title: 'Montaż okablowania:',
      description:
          'Rozprowadzenie przewodów elektrycznych w lokalu. PRZED tynkami!',
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
      description:
          'Okablowanie zewnętrznych przestrzeni przynależnych do lokalu.',
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
      description:
          'Osadzenie puszek podtynkowych dla gniazd, włączników, lamp. PRZED tynkami!',
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
      description:
          'Wykonaj zdjęcia tras przewodów PRZED zakryciem tynkami. Ważne dla późniejszych serwisów.',
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
      description:
          'Kabel od licznika głównego do tablicy mieszkaniowej (Wewnętrzna Linia Zasilająca).',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 7,
      unitIds: unitIds,
    ));

    // T8: Odbiory inspektora nadzoru inwestorskiego
    tasks.add(ChecklistTask(
      id: 'unit-08-inspector-check-1',
      title: 'Odbiory inspektora nadzoru inwestorskiego:',
      description:
          'Inspekcja ukrytych tras okablowania przez inspektora nadzoru. PRZED tynkami!',
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
      description:
          'Wykonanie tynków wewnętrznych. Status: wykonane / w trakcie.',
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
      description:
          'Pomiar rezystancji izolacji instalacji elektrycznej (Riso). Wymagany protokół.',
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
      description:
          'Rury osłonowe dla kabli teletechnicznych (internet, TV, domofon). PRZED wylewką!',
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
      description:
          'Wykonanie wylewki podłogowej. Status: wykonane / w trakcie.',
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
      description:
          'Przeciągnięcie kabli UTP, koncentrycznych, domofonu w rurach osłonowych.',
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
      description:
          'Instalacja rozdzielnicy mieszkaniowej (TM) z zabezpieczeniami.',
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
      description:
          'Podłączenie wszystkich obwodów do rozdzielnicy TM. Test zabezpieczeń.',
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
      description:
          'Instalacja skrzynki TSM dla terminacji kabli teletechnicznych.',
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
      description:
          'Konfiguracja i test połączenia domofonu. Sprawdzenie audio/wideo.',
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
      description:
          'Pomiary sieci teletechnicznych (testy UTP, sygnał TV, domofon). Protokoły.',
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
      description:
          'Kompleksowe pomiary instalacji elektrycznej (Riso, pętle zwarciowe, sprawność wyłączników). Protokoły odbiorcze.',
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
      description:
          'Pierwszy termin odbioru przez inspektora nadzoru. Weryfikacja kompletności.',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 7,
      dependsOnTaskIds: [
        'unit-24-telecom-measurements',
        'unit-25-electrical-measurements'
      ],
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
    return system.displayName;
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
      final buildingIndex = _getBuildingIndexFromUnitId(unitId);
      if (buildingIndex < 0 || buildingIndex >= config.buildings.length) {
        continue;
      }

      final building = config.buildings[buildingIndex];
      if (building.stairCases.isEmpty) {
        continue;
      }

      final stairCaseName = _getStairCaseFromUnitId(config, unitId);
      final floor = _getFloorFromUnitId(
        config,
        unitId,
        resolvedStairCaseName: stairCaseName,
      );
      final unitPosition = _getUnitPositionOnFloorFromUnitId(
        config,
        unitId,
        resolvedStairCaseName: stairCaseName,
      );
      final stairCase = building.stairCases.firstWhere(
        (candidate) => candidate.stairCaseName == stairCaseName,
        orElse: () => building.stairCases.first,
      );
      final constructionLabels =
          stairCase.getFloorUnitLabels(floor, UnitNamingScheme.construction);
      final targetLabels =
          stairCase.getFloorUnitLabels(floor, UnitNamingScheme.target);
      final constructionUnitId = unitPosition < constructionLabels.length
          ? constructionLabels[unitPosition]
          : unitId;
      final targetUnitId = unitPosition < targetLabels.length
          ? targetLabels[unitPosition]
          : constructionUnitId;
      final preferredUnitId =
          config.defaultUnitNamingScheme == UnitNamingScheme.target
              ? targetUnitId
              : constructionUnitId;

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
          constructionUnitId: constructionUnitId,
          targetUnitId: targetUnitId,
          unitName: _getUnitName(preferredUnitId),
          floor: floor,
          stairCase: stairCaseName,
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
    for (int buildingIdx = 0;
        buildingIdx < config.buildings.length;
        buildingIdx++) {
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
              final unitId =
                  'B$buildingNum-${stairCase.stairCaseName}$floorCode';
              unitIds.add(unitId);
            }
          }
        }
      }
    }

    return unitIds;
  }

  static String _getUnitName(String displayUnitId) {
    return 'Mieszkanie $displayUnitId';
  }

  static int _getBuildingIndexFromUnitId(String unitId) {
    final match = RegExp(r'^B(\d+)-').firstMatch(unitId);
    if (match == null) {
      return 0;
    }
    final parsed = int.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) {
      return 0;
    }
    return parsed - 1;
  }

  static int _getFloorFromUnitId(
    BuildingConfiguration config,
    String unitId, {
    String? resolvedStairCaseName,
  }) {
    // Supported formats:
    // - B1-A101 -> floor 1
    // - A101 -> floor 1
    final core = _getUnitCore(unitId);
    if (core.isEmpty) {
      return 0;
    }

    final stairCaseName =
        resolvedStairCaseName ?? _getStairCaseFromUnitId(config, unitId);
    if (stairCaseName.isEmpty || !core.startsWith(stairCaseName)) {
      return 0;
    }

    final suffix = core.substring(stairCaseName.length);
    final numPart = int.tryParse(suffix);
    if (numPart == null) return 0;
    return numPart ~/ 100; // Setki to pietro
  }

  static int _getUnitPositionOnFloorFromUnitId(
    BuildingConfiguration config,
    String unitId, {
    String? resolvedStairCaseName,
  }) {
    final core = _getUnitCore(unitId);
    if (core.isEmpty) {
      return 0;
    }

    final stairCaseName =
        resolvedStairCaseName ?? _getStairCaseFromUnitId(config, unitId);
    if (stairCaseName.isEmpty || !core.startsWith(stairCaseName)) {
      return 0;
    }

    final suffix = core.substring(stairCaseName.length);
    final numPart = int.tryParse(suffix);
    if (numPart == null) {
      return 0;
    }
    final unitNumber = numPart % 100;
    return unitNumber > 0 ? unitNumber - 1 : 0;
  }

  static String _getStairCaseFromUnitId(
    BuildingConfiguration config,
    String unitId,
  ) {
    // Supported formats:
    // - B1-A101 -> stair A
    // - A101 -> stair A
    final core = _getUnitCore(unitId);
    if (core.isEmpty) {
      return '';
    }

    final buildingIndex = _getBuildingIndexFromUnitId(unitId);
    if (buildingIndex < 0 || buildingIndex >= config.buildings.length) {
      return core[0];
    }

    final stairCaseNames = config.buildings[buildingIndex].stairCases
        .map((stairCase) => stairCase.stairCaseName)
        .where((name) => name.isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final name in stairCaseNames) {
      if (core.startsWith(name)) {
        return name;
      }
    }

    return core[0];
  }

  static String _getUnitCore(String unitId) {
    final match = RegExp(r'^B\d+-(.+)$').firstMatch(unitId);
    if (match != null) {
      return match.group(1) ?? unitId;
    }
    return unitId;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENEROWANIE ALERTÓW
  // ═══════════════════════════════════════════════════════════════════════

  static List<ProjectAlert> _generateInitialAlerts(
      ConstructionProject project) {
    final alerts = <ProjectAlert>[];
    final powerValidation = project.config.validatePowerModel();

    for (final error in powerValidation.errors) {
      alerts.add(
        ProjectAlert(
          id: _uuid.v4(),
          severity: AlertSeverity.critical,
          title: 'Krytyczny blad konfiguracji zasilania',
          message: error,
          actionSuggestion:
              'Popraw ustawienia zasilania przed realizacja projektu.',
        ),
      );
    }

    for (final warning in powerValidation.warnings) {
      alerts.add(
        ProjectAlert(
          id: _uuid.v4(),
          severity: AlertSeverity.warning,
          title: 'Ostrzezenie konfiguracji zasilania',
          message: warning,
          actionSuggestion:
              'Zweryfikuj konfiguracje na etapie projektu wykonawczego.',
        ),
      );
    }

    // Alert: Pamiętaj o wysłaniu rozdzielnic!
    var prefabDate = project.config.prefabrication4WeeksBefore;
    var daysDifference = prefabDate.difference(DateTime.now()).inDays;

    if (daysDifference > 0 && daysDifference <= 7) {
      final relatedTaskId = project.allTasks
          .where((t) => t.title.contains('prefabrykacji'))
          .map((t) => t.id)
          .cast<String?>()
          .firstWhere(
            (_) => true,
            orElse: () =>
                project.allTasks.isEmpty ? null : project.allTasks.first.id,
          );

      alerts.add(ProjectAlert(
        id: _uuid.v4(),
        severity: AlertSeverity.critical,
        title: '⚠️ PILNIE: Rozdzielnice do prefabrykacji!',
        message:
            'Za $daysDifference dni powinny być wysłane rozdzielnice do prefabrykacji. '
            'Czas realizacji: 4-6 tygodni! Brak tego działania spowoduje znaczne opóźnienia projektu.',
        actionSuggestion:
            'Natychmiast skontaktuj się z dostawcą i potwierdź wysyłkę',
        relatedTaskId: relatedTaskId,
      ));
    }

    // Alert: Ostatnia szansa na kable!
    final tynkiStage = project.phases
        .where((p) => p.stage == BuildingStage.tynki)
        .cast<ProjectPhase?>()
        .firstWhere((_) => true, orElse: () => null);
    final daysTillTynki = tynkiStage == null
        ? -1
        : tynkiStage.startDate.difference(DateTime.now()).inDays;

    if (daysTillTynki > 0 && daysTillTynki <= 7) {
      alerts.add(ProjectAlert(
        id: _uuid.v4(),
        severity: AlertSeverity.urgent,
        title: '🚨 Za $daysTillTynki dni zaczynają się tynki!',
        message:
            'OSTATNIA SZANSA ułożyć kable w ścianach, pod posadzkami i wewnątrz struktu ry! '
            'Po tynkach będzie za późno!',
        actionSuggestion:
            'Sprawdź status wszystkich zadań związanych z ułożeniem kabli',
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
        message: 'Masz ${tasksForToday.length} zadań do wykonania dzisiaj. '
            'Pamiętaj o dokumentacji fotograficznej!',
        actionSuggestion: 'Przejrzyj listę zadań na dzisiaj',
      ));
    }

    return alerts;
  }
}
