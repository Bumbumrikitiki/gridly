import 'package:uuid/uuid.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';

/// Generator zadań specyficznych dla lokali mieszkalnych
/// 28 zadań z pliku Excel "lista prac lokale mieszkalne"
class ResidentialUnitTasksGenerator {
  static const _uuid = Uuid();

  /// Generuj 28 zadań dla lokalu mieszkalnego
  /// 
  /// Zadanie "Projekt zamienny" jest dodawane tylko dla lokali z isAlternateUnit=true
  static List<ChecklistTask> generateTasksForUnit(
    String unitId,
    bool isAlternateUnit,
  ) {
    final tasks = <ChecklistTask>[];

    // T1: Projekt zamienny (tylko dla lokali zamiennych)
    if (isAlternateUnit) {
      tasks.add(ChecklistTask(
        id: 'RU-$unitId-T01',
        title: 'Projekt zamienny:',
        description: 'Przygotowanie projektu zamiennego dla lokalu',
        system: ElectricalSystemType.itp,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 7,
        unitIds: [unitId],
      ));
    }

    // T2: Ścianki działowe
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T02',
      title: 'Ścianki działowe:',
      description: 'Montaż ścianek działowych w lokalu',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 14,
      unitIds: [unitId],
    ));

    // T3: Montaż okablowania
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T03',
      title: 'Montaż okablowania:',
      description: 'Rozprowadzenie okablowania elektrycznego w lokalu',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 10,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T02'],
    ));

    // T4: Montaż okablowania na balkonie, loggy, ogródku
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T04',
      title: 'Montaż okablowania na balkonie, loggy, ogródku:',
      description: 'Rozprowadzenie okablowania w przestrzeniach zewnętrznych lokalu',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 9,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T03'],
    ));

    // T5: Montaż puszek elektroinstalacyjnych
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T05',
      title: 'Montaż puszek elektroinstalacyjnych:',
      description: 'Instalacja puszek podtynkowych dla gniazdek i włączników',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 8,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T03'],
    ));

    // T6: Dokumentacja fotograficzna okablowania
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T06',
      title: 'Dokumentacja fotograficzna okablowania:',
      description: 'Zdjęcia rozprowadzenia kabli przed zakryciem',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 7,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T03', 'RU-$unitId-T04', 'RU-$unitId-T05'],
    ));

    // T7: Doprowadzenie kabla WLZ
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T07',
      title: 'Doprowadzenie kabla WLZ:',
      description: 'Doprowadzenie kabla Własności-Lokator-Zarządca',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 6,
      unitIds: [unitId],
    ));

    // T8: Odbiory inspektora nadzoru inwestorskiego
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T08',
      title: 'Odbiory inspektora nadzoru inwestorskiego:',
      description: 'Odbiór prac przegrodowych przez inspektora',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.przegrody,
      daysBeforeStageEnd: 1,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T06'],
    ));

    // T9: Tynki
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T09',
      title: 'Tynki:',
      description: 'Wykonanie tynków wewnętrznych w lokalu',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.tynki,
      daysBeforeStageEnd: 7,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T08'],
    ));

    // T10: Wykonanie pomiaru Riso
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T10',
      title: 'Wykonanie pomiaru Riso:',
      description: 'Pomiar rezystancji izolacji instalacji elektrycznej',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.tynki,
      daysBeforeStageEnd: 1,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T09'],
    ));

    // T11: Ułożenie rur osłonowych pod instalacje teletechniczną
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T11',
      title: 'Ułożenie rur osłonowych pod instalacje teletechniczną:',
      description: 'Montaż rur osłonowych dla okablowania teletechnicznego',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 10,
      unitIds: [unitId],
    ));

    // T12: Dokumentacja fotograficzna rur osłonowych
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T12',
      title: 'Dokumentacja fotograficzna rur osłonowych:',
      description: 'Zdjęcia rozmieszczenia rur osłonowych przed zalaniem',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 9,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T11'],
    ));

    // T13: Jastrych (wylewka)
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T13',
      title: 'Jastrych (wylewka):',
      description: 'Wykonanie posadzki - jastrychu',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 5,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T12'],
    ));

    // T14: Doprowadzenie okablowania teletechnicznego w rurach
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T14',
      title: 'Doprowadzenie okablowania teletechnicznego w rurach:',
      description: 'Przeciągnięcie kabli teletechnicznych w rurach osłonowych',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.posadzki,
      daysBeforeStageEnd: 1,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T13'],
    ));

    // T15: Malowanie
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T15',
      title: 'Malowanie:',
      description: 'Malowanie pomieszczeń lokalu',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.malowanie,
      daysBeforeStageEnd: 3,
      unitIds: [unitId],
    ));

    // T16: Montaż tablicy mieszkaniowej elektrycznej - TM
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T16',
      title: 'Montaż tablicy mieszkaniowej elektrycznej - TM:',
      description: 'Instalacja rozdzielnicy elektrycznej lokalu',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 12,
      unitIds: [unitId],
    ));

    // T17: Podłączenie tablicy mieszkaniowej
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T17',
      title: 'Podłączenie tablicy mieszkaniowej:',
      description: 'Podłączenie obwodów do tablicy TM i zasilania WLZ',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 11,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T16'],
    ));

    // T18: Montaż teletechnicznej skrzynki mieszkaniowej - TSM
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T18',
      title: 'Montaż teletechnicznej skrzynki mieszkaniowej - TSM:',
      description: 'Instalacja skrzynki teletechnicznej (internet, TV)',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 10,
      unitIds: [unitId],
    ));

    // T19: Montaż osprzętu
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T19',
      title: 'Montaż osprzętu:',
      description: 'Montaż gniazdek, włączników, puszek i listew',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 9,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T15', 'RU-$unitId-T17'],
    ));

    // T20: Montaż unifonu, wideodomofonu
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T20',
      title: 'Montaż unifonu, wideodomofonu:',
      description: 'Instalacja systemu domofonowego w lokalu',
      system: ElectricalSystemType.domofonowa,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 8,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T15'],
    ));

    // T21: Montaż czujnika dymu
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T21',
      title: 'Montaż czujnika dymu:',
      description: 'Instalacja czujek dymu w lokalu',
      system: ElectricalSystemType.dso,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 7,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T15'],
    ));

    // T22: Montaż oprawek oświetleniowych
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T22',
      title: 'Montaż oprawek oświetleniowych:',
      description: 'Montaż opraw oświetleniowych i źródeł światła',
      system: ElectricalSystemType.oswietlenie,
      stage: BuildingStage.osprzet,
      daysBeforeStageEnd: 6,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T15', 'RU-$unitId-T19'],
    ));

    // T23: Uruchomienie instalacji domofonowej
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T23',
      title: 'Uruchomienie instalacji domofonowej:',
      description: 'Testy i uruchomienie systemu domofonowego',
      system: ElectricalSystemType.domofonowa,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 5,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T20'],
    ));

    // T24: Pomiary teletechniczne
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T24',
      title: 'Pomiary teletechniczne:',
      description: 'Pomiary jakości i parametrów instalacji teletechnicznej',
      system: ElectricalSystemType.internet,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 3,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T14', 'RU-$unitId-T18'],
    ));

    // T25: Pomiary elektryczne
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T25',
      title: 'Pomiary elektryczne:',
      description: 'Pomiary instalacji elektrycznej - rezystancja, ciągłość, skuteczność ochrony',
      system: ElectricalSystemType.zasilanie,
      stage: BuildingStage.finalizacja,
      daysBeforeStageEnd: 2,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T19', 'RU-$unitId-T22'],
    ));

    // T26: Odbiory inspektora nadzoru inwestorskiego I termin
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T26',
      title: 'Odbiory inspektora nadzoru inwestorskiego I termin:',
      description: 'Pierwszy odbiór lokalu przez inspektora nadzoru',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.oddawanie,
      daysBeforeStageEnd: 14,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T23', 'RU-$unitId-T24', 'RU-$unitId-T25'],
    ));

    // T27: Odbiory inspektora nadzoru inwestorskiego II termin
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T27',
      title: 'Odbiory inspektora nadzoru inwestorskiego II termin:',
      description: 'Drugi odbiór lokalu - weryfikacja poprawek z I terminu',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.oddawanie,
      daysBeforeStageEnd: 7,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T26'],
    ));

    // T28: Odbiory inspektora nadzoru inwestorskiego końcowe
    tasks.add(ChecklistTask(
      id: 'RU-$unitId-T28',
      title: 'Odbiory inspektora nadzoru inwestorskiego końcowe:',
      description: 'Odbiór końcowy - protokół odebrania lokalu',
      system: ElectricalSystemType.itp,
      stage: BuildingStage.oddawanie,
      daysBeforeStageEnd: 1,
      unitIds: [unitId],
      dependsOnTaskIds: ['RU-$unitId-T27'],
    ));

    return tasks;
  }

  /// Generuj zadania dla wszystkich mieszkań w projekcie
  static List<ChecklistTask> generateTasksForAllUnits(
    BuildingConfiguration config,
  ) {
    final allTasks = <ChecklistTask>[];

    // Dla budynków jednorodzinnych i dupleksów nie generujemy zadań mieszkalnych
    if (config.estimatedUnits <= 1) {
      return allTasks;
    }

    // Generuj jednostki (IDs mieszkań)
    final unitIds = _generateUnitIds(config);

    // Dla każdego mieszkania generuj 28 zadań
    // UWAGA: Na tym etapie nie wiemy które są zamienne, więc:
    // - Zadania 2-28 dodajemy dla wszystkich
    // - Zadanie 1 (Projekt zamienny) dodamy później w checklist_generator
    //   gdy będziemy wiedzieć o statusie isAlternateUnit
    for (final unitId in unitIds) {
      // Na razie generujemy z isAlternateUnit=false
      // Zadanie T01 będzie dodane później w checklist_generator
// Tutaj dodamy tylko zadania 2-28
      final unitTasks = generateTasksForUnit(unitId, false);
      allTasks.addAll(unitTasks);
    }

    return allTasks;
  }

  static List<String> _generateUnitIds(BuildingConfiguration config) {
    final unitIds = <String>[];

    if (config.estimatedUnits <= 1) return unitIds;

    // Użyj rzeczywistej liczby klatek z konfiguracji
    final stairCaseLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    final numStairCases = config.estimatedStairCases.clamp(1, stairCaseLetters.length);

    // Generuj po równo dla klatek (uproszczenie)
    final unitsPerStairCase = (config.estimatedUnits / numStairCases).ceil();
    final floorsPerStairCase = (unitsPerStairCase / config.totalLevels).ceil().clamp(1, 10);

    for (int s = 0; s < numStairCases; s++) {
      final stairCase = stairCaseLetters[s];
      for (int floor = 1; floor <= config.totalLevels; floor++) {
        for (int unit = 1; unit <= floorsPerStairCase; unit++) {
          final unitNumber = (floor * 100) + unit;
          unitIds.add('$stairCase$unitNumber');
        }
      }
    }

    return unitIds.take(config.estimatedUnits).toList();
  }
}
