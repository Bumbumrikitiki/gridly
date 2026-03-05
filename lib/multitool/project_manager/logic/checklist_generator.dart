import 'package:uuid/uuid.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/residential_unit_tasks.dart';

/// Inteligentny generator checklist'u z automatycznym planowaniem
/// System analizuje typ budowy, systemy, etapy i generuje zadania
/// z właściwym czasowaniem i alertami
class ProjectChecklistGenerator {
  static const _uuid = Uuid();

  /// Generuj kompletnylista checklist dla projektu
  static ConstructionProject generateProject(
    BuildingConfiguration config,
  ) {
    final projectId = _uuid.v4();
    
    // 1. Generuj fazy budowy (etapy z datami)
    final phases = _generatePhases(config);
    
    // 2. Generuj wszystkie zadania dla wybranych systemów
    final allTasks = _generateAllTasks(config, phases);
    
    // 3. Generuj jednostki (mieszkania, biura)
    final units = _generateUnits(config, allTasks);
    
    // 4. Stwórz projekt
    var project = ConstructionProject(
      projectId: projectId,
      config: config,
      phases: phases,
      allTasks: allTasks,
      units: units,
    );
    
    // 5. Generuj początkowe alerty
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
  // GENEROWANIE FAZ BUDOWY
  // ═══════════════════════════════════════════════════════════════════════

  static List<ProjectPhase> _generatePhases(BuildingConfiguration config) {
    final phases = <ProjectPhase>[];
    var currentDate = config.projectStartDate;

    for (final stage in BuildingStage.values) {
      final duration = config.stageDurations[stage] ?? 2;
      final endDate = currentDate.add(Duration(days: duration * 7));
      
      phases.add(
        ProjectPhase(
          stage: stage,
          startDate: currentDate,
          endDate: endDate,
          description: _getPhaseDescription(stage),
          criticalTasks: _getCriticalTasks(stage, config),
        ),
      );
      
      currentDate = endDate;
    }

    return phases;
  }

  static String _getPhaseDescription(BuildingStage stage) {
    switch (stage) {
      case BuildingStage.przygotowanie:
        return 'Projekty, harmonogram, zamówienia';
      case BuildingStage.fundamenty:
        return 'Dreny, pasy, pale fundamentowe';
      case BuildingStage.konstrukcja:
        return 'Szkielety, stropy, słupy, wznoszenie';
      case BuildingStage.przegrody:
        return 'Ścianki działowe, przechody, kanały';
      case BuildingStage.tynki:
        return 'Tynki zewnętrzne i wewnętrzne';
      case BuildingStage.posadzki:
        return 'Posadzki, wylewki, przepusty';
      case BuildingStage.osprzet:
        return 'Osprzęt elektryczny, oprawy';
      case BuildingStage.malowanie:
        return 'Malowanie, lakierowanie';
      case BuildingStage.finalizacja:
        return 'Drzwi finalne, meblościany';
      case BuildingStage.ozeInstalacje:
        return 'Instalacje OZE (PV, BESS)';
      case BuildingStage.evInfrastruktura:
        return 'Infrastruktura EV (ładowarki, DLM)';
      case BuildingStage.oddawanie:
        return 'Pomiary, dokumentacja, odbiór';
    }
  }

  static List<String> _getCriticalTasks(
    BuildingStage stage,
    BuildingConfiguration config,
  ) {
    switch (stage) {
      case BuildingStage.przygotowanie:
        return [
          'Zatwierdź harmonogram budowy',
          'Wyślij rozdzielnice do prefabrykacji',
          'Przygotuj dokumentację techniczną',
        ];
      case BuildingStage.przegrody:
        return [
          'UŁÓŻ KABLE W ŚCIANACH - OSTATNIA SZANSA!',
          'Przepusty przez słupy',
          'Kanały w posadzkach',
        ];
      case BuildingStage.tynki:
        return [
          'OSTATNIA SZANSA NA KABLE!',
          'Przygotowanie powierzchni',
        ];
      case BuildingStage.osprzet:
        return [
          'Montaż puszek elektrycznych',
          'Obsadzenie osprzętu',
          'Sprawdzenie połączeń',
        ];
      case BuildingStage.oddawanie:
        return [
          'POMIARY ELEKTRYCZNE (UZT, IP, oporność)',
          'Wykończeń dokumentacji',
          'Odbiór budowy',
        ];
      default:
        return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENEROWANIE ZADAŃ DLA SYSTEMÓW
  // ═══════════════════════════════════════════════════════════════════════

  static List<ChecklistTask> _generateAllTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    final tasks = <ChecklistTask>[];

    // Dla budynków mieszkalnych wielolokalowych generuj zadania mieszkalne (28 zadań)
    if (config.buildingType == BuildingType.wielorodzinny ||
        config.buildingType == BuildingType.wielorodzinnyWysoki ||
        config.buildingType == BuildingType.mieszany) {
      // Generuj 28 zadań dla każdego mieszkania
      tasks.addAll(
        ResidentialUnitTasksGenerator.generateTasksForAllUnits(config),
      );
    }

    // UWAGA: Usunięto generowanie zadań dla systemów elektrycznych
    // Zgodnie z wymaganiami - zostają tylko zadania mieszkalne

    return tasks;
  }

  static List<ChecklistTask> _generateTasksForSystem(
    ElectricalSystemType system,
    BuildingConfiguration config,
    Map<BuildingStage, ProjectPhase> phaseMap,
  ) {
    final tasks = <ChecklistTask>[];
    final taskIdBase = system.toString().split('.').last;

    switch (system) {
      // ════════════════════════════════════════════════════════════════
      // ZASILANIE I ROZDZIELNICE
      // ════════════════════════════════════════════════════════════════
      case ElectricalSystemType.zasilanie:
        // T1: Zamówienie rozdzielnic
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-order',
          title: '🚀 WYSYŁKA: Rozdzielnice do prefabrykacji',
          description:
            'Wyślij rozdzielnice główne i podrzędne do zakładu prefabrykacji. '
            'Czas realizacji: 4-6 tygodni! Konieczne 4 tygodnie PRZED fazą przegród.',
          system: system,
          stage: BuildingStage.przygotowanie,
          daysBeforeStageEnd: 28,
          dependsOnTaskIds: [],
          notes: 'Kontakt z dostawcą, potwierdzenie dostępu do hali',
        ));

        // T2: Przeboje i kanały
        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-holes',
          title: 'Przeboje na trasach zasilaczy',
          description:
            'Wykonaj przeboje w słupach i ścianach nośnych dla zasilaczy głównych. '
            'Etap: podczas wznoszenia konstrukcji.',
          system: system,
          stage: BuildingStage.konstrukcja,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-01-order'],
        ));

        // T3: Przygotowanie węzła głównego
        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-main-node',
          title: 'Przygotowanie węzła centralnego zasilania',
          description:
            'Czyść i przygotuj miejsce dla rozdzielnic (pokój techniczny). '
            'Rozdzielnice powinny już być dostarczone i czekać na montaż.',
          system: system,
          stage: BuildingStage.przegrody,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-02-holes'],
        ));

        // T4: Montaż rozdzielnic
        tasks.add(ChecklistTask(
          id: '$taskIdBase-04-install-dist',
          title: 'Montaż rozdzielnic głównych i podrzędnych',
          description:
            'Zainstaluj rozdzielnice w pokoju technicznym. '
            'Połącz zasilaczy wchodzący. '
            'Konieczne przygotowaniu dokumentacji.',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 14,
          dependsOnTaskIds: ['$taskIdBase-03-main-node'],
        ));

        // T5: Podział zasilania
        tasks.add(ChecklistTask(
          id: '$taskIdBase-05-distribution',
          title: 'Podział zasilania do pięter i mieszkań',
          description:
            'Poprowadź kable zasilające do rozdzielnic piętrowych. '
            'Kable muszą być ułożone PRZED tynkami!',
          system: system,
          stage: BuildingStage.tynki,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-02-holes'],
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        break;

      // ════════════════════════════════════════════════════════════════
      // OŚWIETLENIE
      // ════════════════════════════════════════════════════════════════
      case ElectricalSystemType.oswietlenie:
        // T1: Marki tynkowe
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-marks',
          title: '✏️ Zaznaczenie puszek oświetlenia na ścianach',
          description:
            'Zaznacz położenie puszek dla opraw sufitowych. '
            'Mierz od planów i dokumentacji. '
            'PRZED tynkami wewnętrznymi!',
          system: system,
          stage: BuildingStage.przegrody,
          daysBeforeStageEnd: 3,
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        // T2: Rozprowadzenie kabli
        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-wiring',
          title: 'Rozprowadzenie kabli oświetlenia',
          description:
            'Ułóż kable na sufitach, pod posadzkami i w ścianach. '
            'Zgodnie z planem instalacji. '
            'OSTATNIA szansa PRZED tynkami!',
          system: system,
          stage: BuildingStage.tynki,
          daysBeforeStageEnd: 1,
          dependsOnTaskIds: ['$taskIdBase-01-marks'],
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        // T3: Obsadzenie puszek
        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-socket-prep',
          title: 'Obsadzenie puszek oświetlenia',
          description:
            'Wstaw puszki elektroinstalacyjne w zaznaczone miejsca. '
            'Zabezpiecz przed zabrudzeniem podczas tynków.',
          system: system,
          stage: BuildingStage.tynki,
          daysBeforeStageEnd: 1,
          dependsOnTaskIds: ['$taskIdBase-02-wiring'],
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        // T4: Czyszczenie puszek
        tasks.add(ChecklistTask(
          id: '$taskIdBase-04-clean',
          title: 'Czyszczenie puszek PO tynkach',
          description:
            'Wystrugaj tynk z puszek. Przygotuj do montażu osprzętu. '
            'Uważaj na uszkodzenia kabli!',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 14,
          dependsOnTaskIds: ['$taskIdBase-03-socket-prep'],
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        // T5: Montaż opraw
        tasks.add(ChecklistTask(
          id: '$taskIdBase-05-install',
          title: 'Montaż opraw oświetleniowych',
          description:
            'Zainstaluj oprawy w sufitach i ścianach. '
            'Podłącz kable. Sprawdź działanie.',
          system: system,
          stage: BuildingStage.malowanie,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-04-clean'],
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        break;

      // ════════════════════════════════════════════════════════════════
      // SYSTEMY BEZPIECZEŃSTWA
      // ════════════════════════════════════════════════════════════════
      case ElectricalSystemType.ppoz:
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-design',
          title: 'Przygotowanie projektu systemu ppoż',
          description:
            'Sporządź schemat systemu ppoż (detekcja, zasilanie, sygnalizacja). '
            'Uzgodnij z straż pożarną.',
          system: system,
          stage: BuildingStage.przygotowanie,
          daysBeforeStageEnd: 14,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-wiring',
          title: 'Rozprowadzenie urządzeń ppoż',
          description:
            'Rozmieść detektory dymu/ciepła w pomieszczeniach. '
            'Ułóż kable sygnalizacyjne (przed tynkami!)',
          system: system,
          stage: BuildingStage.przegrody,
          daysBeforeStageEnd: 3,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-test',
          title: 'Test i regulacja systemu ppoż',
          description:
            'Przeprowadź test wszystkich detektorów. '
            'Sprawdzenie centrali, zasilania, sygnalizacji.',
          system: system,
          stage: BuildingStage.finalizacja,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-02-wiring'],
        ));
        break;

      case ElectricalSystemType.cctv:
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-positions',
          title: 'Określenie pozycji kamer CCTV',
          description:
            'Zaznacz miejsca montażu kamer. '
            'Przy wejściach, klatce schodowej, parkingu, halach.',
          system: system,
          stage: BuildingStage.przegrody,
          daysBeforeStageEnd: 7,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-wiring',
          title: 'Ułożenie kabli dla CCTV',
          description:
            'Ułóż kable zasilające i sygnałowe. '
            'Zgodnie ze schematem projektu.',
          system: system,
          stage: BuildingStage.tynki,
          daysBeforeStageEnd: 1,
          dependsOnTaskIds: ['$taskIdBase-01-positions'],
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-install',
          title: 'Montaż i konfiguracja kamer',
          description:
            'Zainstaluj kamery. Konfiguruj rejestrator. '
            'Sprawdzenie transmisji i rejestracji.',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-02-wiring'],
        ));
        break;

      case ElectricalSystemType.domofonowa:
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-project',
          title: 'Projekt systemu domofonowego',
          description:
            'Schemat rozdzielenia domofonu dla każdej klatki schodowej. '
            'Liczba mieszkań, lokalizacja słuchawek.',
          system: system,
          stage: BuildingStage.przygotowanie,
          daysBeforeStageEnd: 14,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-cables',
          title: 'Rozprowadzenie przewodów domofonowych',
          description:
            'Ułóż przewody od wejścia/bramy do rozdzielnic. '
            'Od rozdzielnic do mieszkań.',
          system: system,
          stage: BuildingStage.przegrody,
          daysBeforeStageEnd: 3,          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-mounting',
          title: 'Montaż paneli domofonowych i słuchawek',
          description:
            'Zainstaluj panele wejściowe. Słuchawki w mieszkaniach. '
            'Połączenia i test.',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 14,
          dependsOnTaskIds: ['$taskIdBase-02-cables'],
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));
        break;

      // ════════════════════════════════════════════════════════════════
      // SYSTEMY NOWOCZESNE
      // ════════════════════════════════════════════════════════════════
      case ElectricalSystemType.panelePV:
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-project',
          title: 'Projekt systemu PV z magazynem energii',
          description:
            'Sporządź projekt paneli słonecznych. '
            'Wyznacz miejsce na dachu, inverter w pokoju technicznym.',
          system: system,
          stage: BuildingStage.przygotowanie,
          daysBeforeStageEnd: 14,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-wiring',
          title: 'Przygotowanie tras dla systemu PV',
          description:
            'Ułóż kable zasilające na dachu i do invertera. '
            'Preparacja mocowań na dachu.',
          system: system,
          stage: BuildingStage.tynki,
          daysBeforeStageEnd: 7,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-install',
          title: 'Montaż paneli i invertera PV',
          description:
            'Zainstaluj panele słoneczne na dachu. '
            'Inverter w pokoju technicznym, podłączenie do sieci.',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-02-wiring'],
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-04-test',
          title: 'Uruchomienie i test systemu PV',
          description:
            'Sprawdzenie generacji energii, magazynowania, zasilania. '
            'Dokumentacja i pomiary.',
          system: system,
          stage: BuildingStage.finalizacja,
          daysBeforeStageEnd: 3,
          dependsOnTaskIds: ['$taskIdBase-03-install'],
        ));
        break;

      case ElectricalSystemType.ladownarki:
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-points',
          title: 'Określenie stanowisk ładowarek',
          description:
            'Zaplanuj stanowiska ładowarek w garażu/na parkingu. '
            'Liczba i lokalizacja względem rozdzielnic.',
          system: system,
          stage: BuildingStage.przygotowanie,
          daysBeforeStageEnd: 14,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-cables',
          title: 'Ułożenie kabli zasilających do ładowarek',
          description:
            'Ułóż kable zasilające od rozdzielnic do stanowisk. '
            'Przed zalewaniem posadzek!',
          system: system,
          stage: BuildingStage.posadzki,
          daysBeforeStageEnd: 1,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-install',
          title: 'Montaż ładowarek elektrycznych',
          description:
            'Zainstaluj słupki/pudła ładowarek. Podłącz zasilanie. '
            'Test działania.',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-02-cables'],
        ));
        break;

      case ElectricalSystemType.internet:
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-project',
          title: 'Projekt sieci LAN (strukturalna)',
          description:
            'Sporządź projekt okablowania strukturalnego. '
            'Węzeł główny, serwerownia, gniazda w mieszkaniach.',
          system: system,
          stage: BuildingStage.przygotowanie,
          daysBeforeStageEnd: 14,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-backbone',
          title: 'Ułożenie magistrali (backbone)',
          description:
            'Ułóż kable główne od węzła do rozdzielnic piętrowych. '
            'Instalacja w szachtach przed tynkami.',
          system: system,
          stage: BuildingStage.przegrody,
          daysBeforeStageEnd: 3,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-cables-units',
          title: 'Okablowanie do mieszkań (gniazda RJ45)',
          description:
            'Poprowadź kable UTP/FTP do gniazd w mieszkaniach. '
            'Przed tynkami! Oznacz każdy kabel.',
          system: system,
          stage: BuildingStage.tynki,
          daysBeforeStageEnd: 1,
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-04-sockets',
          title: 'Montaż gniazd RJ45 w mieszkaniach',
          description:
            'Zainstaluj gniazda sieciowe RJ45 w mieszkaniach. '
            'Zaciskanie wg schematu T568A/B.',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 10,
          dependsOnTaskIds: ['$taskIdBase-03-cables-units'],
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-05-test',
          title: 'Test i certyfikacja sieci',
          description:
            'Wykonaj pomiary testerem sieciowym. '
            'Certyfikacja odcinków. Dokumentacja.',
          system: system,
          stage: BuildingStage.finalizacja,
          daysBeforeStageEnd: 7,
          dependsOnTaskIds: ['$taskIdBase-04-sockets'],
        ));
        break;

      default:
        // Dla pozostałych systemów - podstawowe zadania
        tasks.add(ChecklistTask(
          id: '$taskIdBase-01-project',
          title: 'Przygotowanie projektu: ${_getSystemName(system)}',
          description: 'Sporządź projekt dla systemu: ${_getSystemName(system)}',
          system: system,
          stage: BuildingStage.przygotowanie,
          daysBeforeStageEnd: 14,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-02-prep',
          title: 'Przygotowanie tras: ${_getSystemName(system)}',
          description:
            'Przygotuj trasy dla systemu: ${_getSystemName(system)}',
          system: system,
          stage: BuildingStage.przegrody,
          daysBeforeStageEnd: 3,
        ));

        tasks.add(ChecklistTask(
          id: '$taskIdBase-03-install',
          title: 'Montaż systemu: ${_getSystemName(system)}',
          description: 'Zainstaluj system: ${_getSystemName(system)}',
          system: system,
          stage: BuildingStage.osprzet,
          daysBeforeStageEnd: 7,
          // Większość systemów ma instalację per mieszkanie
          unitIds: config.estimatedUnits > 1 ? _generateUnitIds(config) : null,
        ));
    }

    return tasks;
  }

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

  // ═══════════════════════════════════════════════════════════════════════
  // GENEROWANIE JEDNOSTEK (MIESZKAŃ)
  // ═══════════════════════════════════════════════════════════════════════

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

      // Każda jednostka ma te same zadania
      for (final task in allTasks) {
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
          isAlternateUnit: false, // Domyślnie nie są zamienne (użytkownik może zmienić w UI)
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

    // Użyj rzeczywistej liczby klatek z konfiguracji
    final stairCaseLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    final numStairCases = config.estimatedStairCases.clamp(1, stairCaseLetters.length);
    
    // Oblicz ile mieszkań na piętro na klatce
    final totalLevels = config.totalLevels;
    final unitsPerFloorPerStairCase = (config.estimatedUnits / (totalLevels * numStairCases)).ceil();

    // Format: A101, A102, A103, A104 (piętro 1, mieszkanie 1-4)
    //         A201, A202, A203, A204 (piętro 2, mieszkanie 1-4)
    for (int stairIdx = 0; stairIdx < numStairCases; stairIdx++) {
      final stairCase = stairCaseLetters[stairIdx];
      for (int floor = 1; floor <= totalLevels; floor++) {
        for (int unit = 1; unit <= unitsPerFloorPerStairCase; unit++) {
          if (unitIds.length < config.estimatedUnits) {
            // Format: A101 (A + piętro*100 + numer mieszkania)
            unitIds.add('$stairCase${floor * 100 + unit}');
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
    // Przykład: A101 -> 1, A205 -> 2, A304 -> 3
    final numPart = int.tryParse(unitId.substring(1));
    if (numPart == null) return 0;
    return numPart ~/ 100; // Setki to piętro
  }

  static String _getStairCaseFromUnitId(BuildingConfiguration config, String unitId) {
    return unitId[0]; // A, B, C, D
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
          'Za ${daysDifference} dni powinny być wysłane rozdzielnice do prefabrykacji. '
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
        title: '🚨 Za ${daysTillTynki} dni zaczynają się tynki!',
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
