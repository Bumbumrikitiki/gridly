/// Modele projektu budowlanego z chronologią prac elektrycznych
/// 
/// System automatycznie generuje harmonogram prac elektrycznych
/// na podstawie typu budowy, zeitów budowy i wybranych systemów.

// ═══════════════════════════════════════════════════════════════════════════
// TYPY I ENUMY PODSTAWOWE
// ═══════════════════════════════════════════════════════════════════════════

enum BuildingType {
  domek, // Domek jednorodzinny (1-2 piętra)
  dupleks, // Dupleks (2 jednostki)
  wielorodzinny, // Wielorodzinny 3-5 pięter
  wielorodzinnyWysoki, // Wysokościowiec 6+ pięter
  biurowiec, // Budynek biurowy
  handlowy, // Centrum handlowe
  przemyslowy, // Hal przemysłowa
  mieszany, // Mieszany mieszkalno-usługowy
}

enum FoundationType {
  naPalach, // Pale wbijane/wiercone
  naPaskach, // Pasy fundamentowe
  naBetonie, // Bezpośrednio na terenie
}

enum PowerSupplyType {
  siecWysokiegoNapieciaTrafo, // Sieć WN + trafo
  siecNiskiegoNapieciaBezposrednio, // Sieć NN bezpośrednio
  wlasnaGeneracja, // Własna generacja + agregat
}

enum ConnectionType {
  zlaczeDynamiczne, // Złącze dynamiczne
  rozdzielnicaSN, // Rozdzielnica SN
  rozdzielnicaNN, // Rozdzielnica NN
}

enum ElectricalSystemType {
  oswietlenie, // Oświetlenie (LED/żarówki)
  zasilanie, // Zasilanie gniazdek
  klimatyzacja, // Klimatyzacja/ogrzewanie
  windaAscensor, // Winda/ascensor
  domofonowa, // Domofon (analogowy/cyfrowy)
  telewizja, // Antena telewizyjna/kablówka
  internet, // Internet/lan
  odgromowa, // Ochrona odgromowa
  panelePV, // Panele słoneczne
  ladownarki, // Ładowarki samochodowe
  agregat, // Agregat prądotwórczy
  ppoz, // Systemy ppoż (fire alarm)
  dso, // DSO (detektory dymu)
  czujnikiRuchu, // Czujniki ruchu/alarm
  podgrzewanePodjazdy, // Grzejniki podjazdów
  ogrzewanieRur, // Grzejniki rur
  cctv, // Monitoring (CCTV)
  sswim, // SSWIM (system sygnalizacji)
  gaszeniGazem, // Gaszenie gazem (FM200, CO2)
  ewakuacyjne, // Oprawy ewakuacyjne
  smartHome, // Automatyka (smart home)
  oddymianieKlatek, // Oddymianie klatek
  bms, // BMS (zarządzanie budynkiem)
  wykrywaniWyciekow, // Detektory wycieków
  itp, // Inne
}

/// Extension for ElectricalSystemType
extension ElectricalSystemTypeExtension on ElectricalSystemType {
  String get displayName {
    switch (this) {
      case ElectricalSystemType.oswietlenie:
        return '💡 Oświetlenie';
      case ElectricalSystemType.zasilanie:
        return '🔌 Zasilanie (gniazda)';
      case ElectricalSystemType.klimatyzacja:
        return '❄️ Klimatyzacja';
      case ElectricalSystemType.windaAscensor:
        return '🛗 Winda';
      case ElectricalSystemType.domofonowa:
        return '📞 Domofon';
      case ElectricalSystemType.telewizja:
        return '📺 Telewizja';
      case ElectricalSystemType.internet:
        return '🌐 Internet/LAN';
      case ElectricalSystemType.odgromowa:
        return '⚡ Ochrona odgromowa';
      case ElectricalSystemType.panelePV:
        return '☀️ Panele słoneczne';
      case ElectricalSystemType.ladownarki:
        return '🔋 Ładowarki samochodowe';
      case ElectricalSystemType.agregat:
        return '⚙️ Agregat prądotwórczy';
      case ElectricalSystemType.ppoz:
        return '🚨 System ppoż';
      case ElectricalSystemType.dso:
        return '🔥 Detektory dymu';
      case ElectricalSystemType.czujnikiRuchu:
        return '👁️ Czujniki ruchu/alarm';
      case ElectricalSystemType.podgrzewanePodjazdy:
        return '🔥 Grzejniki podjazdów';
      case ElectricalSystemType.ogrzewanieRur:
        return '🔥 Grzejniki rur';
      case ElectricalSystemType.cctv:
        return '📹 CCTV/Monitoring';
      case ElectricalSystemType.sswim:
        return '📡 SSWIM';
      case ElectricalSystemType.gaszeniGazem:
        return '💨 Gaszenie gazem';
      case ElectricalSystemType.ewakuacyjne:
        return '🚪 Oprawy ewakuacyjne';
      case ElectricalSystemType.smartHome:
        return '🏠 Automatyka (smart home)';
      case ElectricalSystemType.oddymianieKlatek:
        return '💨 Oddymianie klatek';
      case ElectricalSystemType.bms:
        return '🖥️ BMS';
      case ElectricalSystemType.wykrywaniWyciekow:
        return '💧 Detektory wycieków';
      case ElectricalSystemType.itp:
        return '➕ Inne';
    }
  }
}

enum BuildingStage {
  przygotowanie, // Faza 0: Projekty, harmonogram, zamówienia
  fundamenty, // Faza 1: Fundamenty, dreny
  konstrukcja, // Faza 2: Szkielety, stropy, słupy
  przegrody, // Faza 3: Ścianki działowe, przechody
  tynki, // Faza 4: Tynki (zewnętrzne + wewnętrzne)
  posadzki, // Faza 5: Posadzki, wylewki
  osprzet, // Faza 6: Osprzęt elektryczny, oprawy
  malowanie, // Faza 7: Malowanie, lakierowanie
  finalizacja, // Faza 8: Drzwi finalne, meblościany
  oddawanie, // Faza 9: Pomiary, dokumentacja, odbiór
}

enum TaskStatus {
  pending, // Oczekujące
  inProgress, // W trakcie
  blocked, // Zablokowane (czeka na inne zadania)
  completed, // Ukończone
  attention, // Wymaga uwagi
  delayed, // Opóźnione
}

enum AlertSeverity {
  info, // Informacja
  warning, // Ostrzeżenie
  critical, // Krytyczne
  urgent, // Pilne
}

// ═══════════════════════════════════════════════════════════════════════════
// GŁÓWNE MODELE DANYCH
// ═══════════════════════════════════════════════════════════════════════════

/// Konfiguracja podstawowa budynku
class BuildingConfiguration {
  final String projectName;
  final BuildingType buildingType;
  final String address;
  final DateTime projectStartDate;
  
  // Parametry budynku
  final int totalLevels; // Piętra nadziemne
  final int basementLevels; // Piętra podziemne
  final bool hasParking; // Parking
  final bool hasGarage; // Garaż
  
  // Zasilanie
  final PowerSupplyType powerSupplyType;
  final ConnectionType connectionType;
  final double estimatedPowerDemand; // kW
  
  // Systemy elektryczne
  final Set<ElectricalSystemType> selectedSystems;
  
  // Mieszkańcy/szacunkowa liczba lokali
  final int estimatedUnits; // Liczba mieszkań/biur
  final int estimatedStairCases; // Klatki schodowe
  
  // Czasy budowy (w tygodniach)
  final Map<BuildingStage, int> stageDurations;
  
  // Dodatkowe info
  final String notes;
  final DateTime? createdAt;
  
  BuildingConfiguration({
    required this.projectName,
    required this.buildingType,
    required this.address,
    required this.projectStartDate,
    required this.totalLevels,
    required this.basementLevels,
    required this.hasParking,
    required this.hasGarage,
    required this.powerSupplyType,
    required this.connectionType,
    required this.estimatedPowerDemand,
    required this.selectedSystems,
    required this.estimatedUnits,
    required this.estimatedStairCases,
    required this.stageDurations,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Oblicz przewidywaną datę zakończenia
  DateTime get estimatedEndDate {
    int totalWeeks = stageDurations.values.fold(0, (sum, weeks) => sum + weeks);
    return projectStartDate.add(Duration(days: totalWeeks * 7));
  }
  
  // Oblicz datę startu do prefabrykacji (4 tygodnie wcześniej dla trafów)
  DateTime get prefabrication4WeeksBefore {
    // Rozdzielnice trafo powinny być wysłane 4 tygodnie przed fazą przegród
    int daysBeforePrzegrody = (stageDurations[BuildingStage.przygotowanie] ?? 0) +
        (stageDurations[BuildingStage.fundamenty] ?? 0) +
        (stageDurations[BuildingStage.konstrukcja] ?? 0) - (4 * 7);
    return projectStartDate.add(Duration(days: daysBeforePrzegrody));
  }
}

/// Etap budowy z datami
class ProjectPhase {
  final BuildingStage stage;
  final DateTime startDate;
  final DateTime endDate;
  final Duration duration;
  final String description;
  final List<String> criticalTasks; // Zadania krytyczne dla tej fazy
  
  ProjectPhase({
    required this.stage,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.criticalTasks = const [],
  }) : duration = endDate.difference(startDate);
  
  // Czy jest w trakcie?
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  // Postęp (0.0 - 1.0)
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    final elapsed = now.difference(startDate);
    return elapsed.inHours / duration.inHours;
  }
}

/// Zadanie w checklist'cie
class ChecklistTask {
  final String id;
  final String title;
  final String description;
  final ElectricalSystemType system;
  final BuildingStage stage; // W której fazie to powinno być zrobione?
  final int daysBeforeStageEnd; // Ile dni przed końcem fazy (dla alertów)
  
  // Status i daty
  TaskStatus status;
  DateTime? completedDate;
  DateTime? dueDate;
  
  // Zależności
  final List<String> dependsOnTaskIds; // ID zadań, które muszą być najpierw
  
  // Notatki
  String notes;
  final List<String> attachmentPaths; // Zdjęcia, dokumenty
  
  // Powiązanie z jednostkami (mieszkania A1-A250)
  final List<String>? unitIds; // null = globalne dla budynku
  
  ChecklistTask({
    required this.id,
    required this.title,
    required this.description,
    required this.system,
    required this.stage,
    required this.daysBeforeStageEnd,
    this.status = TaskStatus.pending,
    this.completedDate,
    this.dueDate,
    this.dependsOnTaskIds = const [],
    this.notes = '',
    this.attachmentPaths = const [],
    this.unitIds,
  });
  
  // Czy zadanie jest dostępne do wykonania?
  bool get isAvailable {
    // Dostępne gdy wszystkie zależności są ukończone
    return dependsOnTaskIds.isEmpty;
  }
  
  // Czy jest opóźnione?
  bool get isDelayed {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.completed;
  }
}

/// Alert/sugestia dla użytkownika
class ProjectAlert {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? relatedTaskId;
  final String actionSuggestion; // Co powinien zrobić użytkownik?
  
  bool isRead;
  DateTime? readAt;
  
  ProjectAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.actionSuggestion,
    this.relatedTaskId,
    DateTime? createdAt,
    this.isRead = false,
    this.readAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Jednostka (mieszkanie, biuro, itp.)
class ProjectUnit {
  final String unitId; // A1, A2, ... B301
  final String unitName; // "Mieszkanie A1", "Biuro 2.5"
  final int floor;
  final String stairCase; // Klatka schodowa
  
  // Instalacje specyficzne dla jednostki
  final Set<ElectricalSystemType> specificSystems;
  
  // Typ lokalu
  final bool isAlternateUnit; // Lokal zamienny
  
  // Status prac
  final Map<String, TaskStatus> taskStatuses; // taskId -> status
  final Map<String, DateTime?> taskCompletionDates;
  
  // Dokumentacja
  final List<String> photoPaths;
  final String defectsNotes;
  
  ProjectUnit({
    required this.unitId,
    required this.unitName,
    required this.floor,
    required this.stairCase,
    this.specificSystems = const {},
    this.isAlternateUnit = false,
    this.taskStatuses = const {},
    this.taskCompletionDates = const {},
    this.photoPaths = const [],
    this.defectsNotes = '',
  });
  
  // Procent ukończenia dla tej jednostki
  double get completionPercentage {
    if (taskStatuses.isEmpty) return 0.0;
    final completed = taskStatuses.values
        .where((status) => status == TaskStatus.completed)
        .length;
    return (completed / taskStatuses.length) * 100;
  }
  
  ProjectUnit copyWith({
    String? unitId,
    String? unitName,
    int? floor,
    String? stairCase,
    Set<ElectricalSystemType>? specificSystems,
    bool? isAlternateUnit,
    Map<String, TaskStatus>? taskStatuses,
    Map<String, DateTime?>? taskCompletionDates,
    List<String>? photoPaths,
    String? defectsNotes,
  }) {
    return ProjectUnit(
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      floor: floor ?? this.floor,
      stairCase: stairCase ?? this.stairCase,
      specificSystems: specificSystems ?? this.specificSystems,
      isAlternateUnit: isAlternateUnit ?? this.isAlternateUnit,
      taskStatuses: taskStatuses ?? this.taskStatuses,
      taskCompletionDates: taskCompletionDates ?? this.taskCompletionDates,
      photoPaths: photoPaths ?? this.photoPaths,
      defectsNotes: defectsNotes ?? this.defectsNotes,
    );
  }
}

/// Pełny projekt budowy
class ConstructionProject {
  final String projectId;
  final BuildingConfiguration config;
  final List<ProjectPhase> phases;
  final List<ChecklistTask> allTasks;
  final List<ProjectAlert> alerts;
  final List<ProjectUnit> units; // Dla projektów wielolokalowych
  
  // Metadata
  final DateTime createdAt;
  DateTime? lastModifiedAt;
  
  ConstructionProject({
    required this.projectId,
    required this.config,
    required this.phases,
    required this.allTasks,
    this.alerts = const [],
    this.units = const [],
    DateTime? createdAt,
    this.lastModifiedAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Oblicz ogólny postęp projektu
  double get overallProgress {
    if (allTasks.isEmpty) return 0.0;
    final completed = allTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    return (completed / allTasks.length) * 100;
  }
  
  // Aktywna faza
  ProjectPhase? get activePhase {
    try {
      return phases.firstWhere((phase) => phase.isActive);
    } catch (e) {
      return null;
    }
  }
  
  // Liczba alertów do uwagi
  int get unreadAlertCount {
    return alerts.where((a) => !a.isRead).length;
  }
  
  // Liczba zadań opóźnionych
  int get delayedTaskCount {
    return allTasks.where((t) => t.isDelayed).length;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CZASOWE SZABLONY BUDOWY
// ═══════════════════════════════════════════════════════════════════════════

/// Domyślne czasy etapów dla różnych typów budynków
class BuildingTimingTemplates {
  static Map<BuildingStage, int> domekJednorodzinny() => {
    BuildingStage.przygotowanie: 1,
    BuildingStage.fundamenty: 2,
    BuildingStage.konstrukcja: 4,
    BuildingStage.przegrody: 2,
    BuildingStage.tynki: 3,
    BuildingStage.posadzki: 1,
    BuildingStage.osprzet: 2,
    BuildingStage.malowanie: 2,
    BuildingStage.finalizacja: 1,
    BuildingStage.oddawanie: 1,
  };

  static Map<BuildingStage, int> wielorodzinny34pietra() => {
    BuildingStage.przygotowanie: 2,
    BuildingStage.fundamenty: 3,
    BuildingStage.konstrukcja: 7,
    BuildingStage.przegrody: 4,
    BuildingStage.tynki: 5,
    BuildingStage.posadzki: 2,
    BuildingStage.osprzet: 3,
    BuildingStage.malowanie: 4,
    BuildingStage.finalizacja: 2,
    BuildingStage.oddawanie: 1,
  };

  static Map<BuildingStage, int> wielorodzinnyWysoki() => {
    BuildingStage.przygotowanie: 3,
    BuildingStage.fundamenty: 4,
    BuildingStage.konstrukcja: 12,
    BuildingStage.przegrody: 6,
    BuildingStage.tynki: 8,
    BuildingStage.posadzki: 3,
    BuildingStage.osprzet: 5,
    BuildingStage.malowanie: 6,
    BuildingStage.finalizacja: 3,
    BuildingStage.oddawanie: 2,
  };

  static Map<BuildingStage, int> biurowiec() => {
    BuildingStage.przygotowanie: 2,
    BuildingStage.fundamenty: 3,
    BuildingStage.konstrukcja: 8,
    BuildingStage.przegrody: 5,
    BuildingStage.tynki: 6,
    BuildingStage.posadzki: 2,
    BuildingStage.osprzet: 4,
    BuildingStage.malowanie: 5,
    BuildingStage.finalizacja: 2,
    BuildingStage.oddawanie: 2,
  };
}
