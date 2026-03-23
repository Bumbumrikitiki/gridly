/// Modele projektu budowlanego z chronologią prac elektrycznych
/// 
/// System automatycznie generuje harmonogram prac elektrycznych
/// na podstawie typu budowy, zeitów budowy i wybranych systemów.
library;

import 'package:gridly/multitool/project_manager/models/schedule_data_integration.dart';
import 'package:gridly/multitool/project_manager/models/renewable_energy_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TYPY I ENUMY PODSTAWOWE
// ═══════════════════════════════════════════════════════════════════════════

enum BuildingType {
  mieszkalny, // Budynek mieszkalny (dom, dupleks, apartamentowiec)
  biurowy, // Budynek biurowy / handlowo-usługowy
}

BuildingType _parseBuildingType(String? value) {
  switch (value) {
    case 'mieszkalny':
      return BuildingType.mieszkalny;
    case 'biurowy':
      return BuildingType.biurowy;
    case 'domek':
    case 'dupleks':
    case 'wielorodzinny':
    case 'wielorodzinnyWysoki':
      return BuildingType.mieszkalny;
    case 'biurowiec':
    case 'handlowy':
    case 'przemyslowy':
    case 'mieszany':
      return BuildingType.biurowy;
    default:
      return BuildingType.mieszkalny;
  }
}

enum FoundationType {
  naPalach, // Pale wbijane/wiercone
  naPaskach, // Pasy fundamentowe
  naBetonie, // Bezpośrednio na terenie
}

enum PowerSupplyType {
  przylaczeNN, // Przyłącze NN (230/400V) bezpośrednio
  przylaczeSNZTrafo, // Przyłącze SN (6-30kV) z transformatorem własnym
  wlasnaGeneracja, // Własna generacja (OZE/agregat)
}

PowerSupplyType _parsePowerSupplyType(String? value) {
  switch (value) {
    case 'przylaczeNN':
      return PowerSupplyType.przylaczeNN;
    case 'przylaczeSNZTrafo':
      return PowerSupplyType.przylaczeSNZTrafo;
    case 'wlasnaGeneracja':
      return PowerSupplyType.wlasnaGeneracja;
    case 'siecWysokiegoNapieciaTrafo':
      return PowerSupplyType.przylaczeSNZTrafo;
    case 'siecNiskiegoNapieciaBezposrednio':
      return PowerSupplyType.przylaczeNN;
    default:
      return PowerSupplyType.przylaczeNN;
  }
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
  ozeInstalacje, // Faza 10: Instalacje OZE (PV, BESS, magazyny energii)
  evInfrastruktura, // Faza 11: Infrastruktura elektromobilności (ładowarki EV)
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

enum AdditionalRoomLevelType {
  nadziemna, // Kondygnacja nadziemna
  podziemna, // Kondygnacja podziemna
}

enum AdditionalRoomInstallation {
  zasilanie,
  oswietlenie,
  teletechnika,
  cctv,
  ppoz,
  ssp,
  wentylacja,
  klimatyzacja,
  oddymianie,
}

enum AdditionalRoomTask {
  projekt,
  okablowanie,
  montazOsprzetu,
  pomiary,
  uruchomienie,
  odbior,
}

const String kAlternateProjectTaskId = 'unit-01-alt-project';

// ═══════════════════════════════════════════════════════════════════════════
// GŁÓWNE MODELE DANYCH
// ═══════════════════════════════════════════════════════════════════════════

/// Szczegóły klatki schodowej z informacją o piętrach i mieszkaniach
class StairCaseDetails {
  final String stairCaseName; // A, B, C, D
  final int numberOfLevels; // Ile pięter ma ta konkretna klatka
  final Map<int, int> unitsPerFloor; // Piętro -> ilość mieszkań na piętrze
  final int numberOfElevators; // Liczba dźwigów w tej klatce
  final Map<int, String> floorNames; // Piętro -> customowa nazwa (np. "Parter", "I piętro")
  
  StairCaseDetails({
    required this.stairCaseName,
    required this.numberOfLevels,
    Map<int, int>? unitsPerFloor,
    this.numberOfElevators = 0,
    Map<int, String>? floorNames,
  }) : unitsPerFloor = unitsPerFloor ?? {},
       floorNames = floorNames ?? {};
  
  // Całkowita liczba jednostek w tej klatce
  int get totalUnits {
    return unitsPerFloor.values.fold(0, (sum, count) => sum + count);
  }
  
  // Pobierz nazwę piętra (customowa lub domyślna "P. X")
  String getFloorName(int floor) {
    return floorNames[floor] ?? 'P. $floor';
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'stairCaseName': stairCaseName,
      'numberOfLevels': numberOfLevels,
      'unitsPerFloor': unitsPerFloor.map((k, v) => MapEntry(k.toString(), v)),
      'numberOfElevators': numberOfElevators,
      'floorNames': floorNames.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
  
  factory StairCaseDetails.fromJson(Map<String, dynamic> json) {
    return StairCaseDetails(
      stairCaseName: json['stairCaseName'] as String,
      numberOfLevels: json['numberOfLevels'] as int,
      unitsPerFloor: (json['unitsPerFloor'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ) ?? {},
      numberOfElevators: json['numberOfElevators'] as int? ?? 0,
      floorNames: (json['floorNames'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(int.parse(k), v as String),
      ) ?? {},
    );
  }
}

/// Budynek z informacją o klatkach, piętrach podziemnych itp.
class BuildingDetails {
  final String buildingName; // "Budynek 1", "A", "B"
  final List<StairCaseDetails> stairCases; // Klatki schodowe
  final int basementLevels; // Piętra podziemne (jeśli ma garaż)
  
  BuildingDetails({
    required this.buildingName,
    required this.stairCases,
    this.basementLevels = 0,
  });
  
  // Całkowita liczba pięter nadziemnych (max ze wszystkich klatek)
  int get totalLevels {
    if (stairCases.isEmpty) return 0;
    return stairCases.map((sc) => sc.numberOfLevels).reduce((a, b) => a > b ? a : b);
  }
  
  // Całkowita liczba mieszkań w budynku
  int get totalUnits {
    return stairCases.fold<int>(0, (sum, sc) => sum + sc.totalUnits);
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'buildingName': buildingName,
      'stairCases': stairCases.map((sc) => sc.toJson()).toList(),
      'basementLevels': basementLevels,
    };
  }
  
  factory BuildingDetails.fromJson(Map<String, dynamic> json) {
    return BuildingDetails(
      buildingName: json['buildingName'] as String,
      stairCases: (json['stairCases'] as List)
          .map((sc) => StairCaseDetails.fromJson(sc as Map<String, dynamic>))
          .toList(),
      basementLevels: json['basementLevels'] as int? ?? 0,
    );
  }
}

/// Szczegóły klatki schodowej z informacją o piętrach i mieszkaniach
class BuildingConfiguration {
  final String projectName;
  final BuildingType buildingType;
  final String address;
  final DateTime projectStartDate;
  final DateTime projectEndDate;
  
  // Parametry budynku
  final int numberOfBuildings; // Ile budynków w projekcie
  final bool hasGarage; // Czy jest garaż (dotyczy wszystkich budynków)
  final bool hasParking; // Czy jest parking
  
  // Szczegóły budynków z klatkami
  final List<BuildingDetails> buildings; // Informacja o każdym budynku
  
  // Zasilanie
  final PowerSupplyType powerSupplyType;
  final ConnectionType connectionType;
  final String energySupplier;
  final double estimatedPowerDemand; // kW
  
  // Systemy elektryczne
  final Set<ElectricalSystemType> selectedSystems;

  // Konfiguracja odnawialnych źródeł energii (OZE) i elektromobilności (EV)
  final RenewableEnergyConfiguration? renewableEnergyConfig;

  // Pomieszczenia dodatkowe
  final List<AdditionalRoom> additionalRooms;
  
  // Mieszkańcy/szacunkowa liczba lokali
  final int estimatedUnits; // Liczba mieszkań/biur
  
  // Całkowity czas budowy (w tygodniach) - użytkownik podaje całkowity czas
  final int totalBuildingWeeks;
  
  // Aktualny etap budowy - dla celów śledzenia które prace już wykonano
  final BuildingStage currentBuildingStage;
  
  // Dodatkowe info
  final String notes;
  final DateTime? createdAt;
  
  BuildingConfiguration({
    required this.projectName,
    required this.buildingType,
    required this.address,
    required this.projectStartDate,
    required this.projectEndDate,
    required this.numberOfBuildings,
    required this.hasGarage,
    required this.hasParking,
    required this.buildings,
    required this.powerSupplyType,
    required this.connectionType,
    required this.energySupplier,
    required this.estimatedPowerDemand,
    required this.selectedSystems,
    required this.additionalRooms,
    required this.estimatedUnits,
    required this.totalBuildingWeeks,
    required this.currentBuildingStage,
    this.renewableEnergyConfig,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Oblicz całkowity czas budowy (z danych użytkownika)
  Duration get buildingDuration {
    return projectEndDate.difference(projectStartDate);
  }
  
  // Całkowita liczba pięter nadziemnych (max ze wszystkich budynków)
  int get totalLevels {
    if (buildings.isEmpty) return 0;
    return buildings.map((b) => b.totalLevels).reduce((a, b) => a > b ? a : b);
  }
  
  // Całkowita liczba pięter podziemnych
  int get basementLevels {
    if (!hasGarage) return 0;
    if (buildings.isEmpty) return 0;
    return buildings.first.basementLevels;
  }
  
  // Liczba klatek schodowych (ze wszystkich budynków)
  int get estimatedStairCases {
    return buildings.fold<int>(0, (sum, b) => sum + b.stairCases.length);
  }
  
  // Całkowita liczba dźwigów (ze wszystkich klatek)
  int get numberOfElevators {
    int total = 0;
    for (final building in buildings) {
      for (final stairCase in building.stairCases) {
        total += stairCase.numberOfElevators;
      }
    }
    return total;
  }
  
  // Oblicz przewidywaną datę zakończenia
  DateTime get estimatedEndDate {
    return projectEndDate;
  }
  
  // Oblicz datę startu do prefabrykacji (4 tygodnie przed połową budowy)
  DateTime get prefabrication4WeeksBefore {
    int halfWeeks = totalBuildingWeeks ~/ 2;
    return projectStartDate.add(Duration(days: (halfWeeks - 4) * 7));
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'buildingType': buildingType.name,
      'address': address,
      'projectStartDate': projectStartDate.toIso8601String(),
      'projectEndDate': projectEndDate.toIso8601String(),
      'numberOfBuildings': numberOfBuildings,
      'hasGarage': hasGarage,
      'hasParking': hasParking,
      'buildings': buildings.map((b) => b.toJson()).toList(),
      'powerSupplyType': powerSupplyType.name,
      'connectionType': connectionType.name,
      'energySupplier': energySupplier,
      'estimatedPowerDemand': estimatedPowerDemand,
      'selectedSystems': selectedSystems.map((s) => s.name).toList(),
      'renewableEnergyConfig': renewableEnergyConfig?.toJson(),
      'additionalRooms': additionalRooms.map((r) => r.toJson()).toList(),
      'estimatedUnits': estimatedUnits,
      'totalBuildingWeeks': totalBuildingWeeks,
      'currentBuildingStage': currentBuildingStage.name,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  factory BuildingConfiguration.fromJson(Map<String, dynamic> json) {
    return BuildingConfiguration(
      projectName: json['projectName'] as String,
      buildingType: _parseBuildingType(json['buildingType'] as String?),
      address: json['address'] as String,
      projectStartDate: DateTime.parse(json['projectStartDate'] as String),
      projectEndDate: DateTime.parse(json['projectEndDate'] as String),
      numberOfBuildings: json['numberOfBuildings'] as int,
      hasGarage: json['hasGarage'] as bool,
      hasParking: json['hasParking'] as bool,
      buildings: (json['buildings'] as List)
          .map((b) => BuildingDetails.fromJson(b as Map<String, dynamic>))
          .toList(),
      powerSupplyType: _parsePowerSupplyType(
        json['powerSupplyType'] as String?,
      ),
      connectionType: ConnectionType.values.firstWhere(
        (e) => e.name == json['connectionType'],
      ),
      energySupplier: json['energySupplier'] as String? ?? 'Nie wybrano',
      estimatedPowerDemand: (json['estimatedPowerDemand'] as num).toDouble(),
      selectedSystems: (json['selectedSystems'] as List)
          .map((s) => ElectricalSystemType.values.firstWhere(
                (e) => e.name == s,
              ))
          .toSet(),
        additionalRooms: (json['additionalRooms'] as List?)
            ?.map((r) => AdditionalRoom.fromJson(r as Map<String, dynamic>))
            .toList() ??
          [],
      estimatedUnits: json['estimatedUnits'] as int,
      totalBuildingWeeks: json['totalBuildingWeeks'] as int,
      currentBuildingStage: BuildingStage.values.firstWhere(
        (e) => e.name == json['currentBuildingStage'],
      ),
      renewableEnergyConfig: json['renewableEnergyConfig'] != null
          ? RenewableEnergyConfiguration.fromJson(json['renewableEnergyConfig'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Pomieszczenie dodatkowe (techniczne, pomocnicze)
class AdditionalRoom {
  final String id;
  final String name;
  final int buildingIndex;
  final String? stairCaseName;
  final AdditionalRoomLevelType levelType;
  final int floorNumber;
  final Set<AdditionalRoomInstallation> installations;
  final Set<AdditionalRoomTask> tasks;
  final Set<AdditionalRoomTask> completedTasks;

  AdditionalRoom({
    required this.id,
    required this.name,
    required this.buildingIndex,
    required this.levelType,
    required this.floorNumber,
    this.stairCaseName,
    this.installations = const {},
    this.tasks = const {},
    this.completedTasks = const {},
  });

  AdditionalRoom copyWith({
    String? id,
    String? name,
    int? buildingIndex,
    String? stairCaseName,
    AdditionalRoomLevelType? levelType,
    int? floorNumber,
    Set<AdditionalRoomInstallation>? installations,
    Set<AdditionalRoomTask>? tasks,
    Set<AdditionalRoomTask>? completedTasks,
  }) {
    return AdditionalRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      buildingIndex: buildingIndex ?? this.buildingIndex,
      stairCaseName: stairCaseName ?? this.stairCaseName,
      levelType: levelType ?? this.levelType,
      floorNumber: floorNumber ?? this.floorNumber,
      installations: installations ?? this.installations,
      tasks: tasks ?? this.tasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'buildingIndex': buildingIndex,
      'stairCaseName': stairCaseName,
      'levelType': levelType.name,
      'floorNumber': floorNumber,
      'installations': installations.map((i) => i.name).toList(),
      'tasks': tasks.map((t) => t.name).toList(),
      'completedTasks': completedTasks.map((t) => t.name).toList(),
    };
  }

  factory AdditionalRoom.fromJson(Map<String, dynamic> json) {
    return AdditionalRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      buildingIndex: json['buildingIndex'] as int,
      stairCaseName: json['stairCaseName'] as String?,
      levelType: AdditionalRoomLevelType.values.firstWhere(
        (e) => e.name == json['levelType'],
      ),
      floorNumber: json['floorNumber'] as int,
      installations: (json['installations'] as List?)
              ?.map((i) => AdditionalRoomInstallation.values
                  .firstWhere((e) => e.name == i))
              .toSet() ??
          {},
      tasks: (json['tasks'] as List?)
              ?.map((t) =>
                  AdditionalRoomTask.values.firstWhere((e) => e.name == t))
              .toSet() ??
          {},
      completedTasks: (json['completedTasks'] as List?)
              ?.map((t) =>
                  AdditionalRoomTask.values.firstWhere((e) => e.name == t))
              .toSet() ??
          {},
    );
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
  
  // Nazwa fazy
  String get name => description;
  
  // Numer tygodnia (obliczany na podstawie dat)
  int get weekNumber => (duration.inDays / 7).ceil();
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'stage': stage.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'description': description,
      'criticalTasks': criticalTasks,
    };
  }
  
  factory ProjectPhase.fromJson(Map<String, dynamic> json) {
    return ProjectPhase(
      stage: BuildingStage.values.firstWhere(
        (e) => e.name == json['stage'],
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      description: json['description'] as String,
      criticalTasks: (json['criticalTasks'] as List?)?.cast<String>() ?? [],
    );
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
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'system': system.name,
      'stage': stage.name,
      'daysBeforeStageEnd': daysBeforeStageEnd,
      'status': status.name,
      'completedDate': completedDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'dependsOnTaskIds': dependsOnTaskIds,
      'notes': notes,
      'attachmentPaths': attachmentPaths,
      'unitIds': unitIds,
    };
  }
  
  factory ChecklistTask.fromJson(Map<String, dynamic> json) {
    return ChecklistTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      system: ElectricalSystemType.values.firstWhere(
        (e) => e.name == json['system'],
      ),
      stage: BuildingStage.values.firstWhere(
        (e) => e.name == json['stage'],
      ),
      daysBeforeStageEnd: json['daysBeforeStageEnd'] as int,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
      ),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dependsOnTaskIds: (json['dependsOnTaskIds'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String? ?? '',
      attachmentPaths: (json['attachmentPaths'] as List?)?.cast<String>() ?? [],
      unitIds: (json['unitIds'] as List?)?.cast<String>(),
    );
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
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'relatedTaskId': relatedTaskId,
      'actionSuggestion': actionSuggestion,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }
  
  factory ProjectAlert.fromJson(Map<String, dynamic> json) {
    return ProjectAlert(
      id: json['id'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      actionSuggestion: json['actionSuggestion'] as String,
      relatedTaskId: json['relatedTaskId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }
}

/// Jednostka (mieszkanie, biuro, itp.)
class ProjectUnit {
  final String unitId; // A1, A2, ... B301
  final String unitName; // "Mieszkanie A1", "Biuro 2.5"
  final int floor;
  final String stairCase; // Klatka schodowa
  final bool isAlternateUnit; // Lokal zamienny
  
  // Instalacje specyficzne dla jednostki
  final Set<ElectricalSystemType> specificSystems;
  
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
    this.isAlternateUnit = false,
    this.specificSystems = const {},
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
    bool? isAlternateUnit,
    Set<ElectricalSystemType>? specificSystems,
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
      isAlternateUnit: isAlternateUnit ?? this.isAlternateUnit,
      specificSystems: specificSystems ?? this.specificSystems,
      taskStatuses: taskStatuses ?? this.taskStatuses,
      taskCompletionDates: taskCompletionDates ?? this.taskCompletionDates,
      photoPaths: photoPaths ?? this.photoPaths,
      defectsNotes: defectsNotes ?? this.defectsNotes,
    );
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'unitId': unitId,
      'unitName': unitName,
      'floor': floor,
      'stairCase': stairCase,
      'isAlternateUnit': isAlternateUnit,
      'specificSystems': specificSystems.map((s) => s.name).toList(),
      'taskStatuses': taskStatuses.map((k, v) => MapEntry(k, v.name)),
      'taskCompletionDates': taskCompletionDates.map(
        (k, v) => MapEntry(k, v?.toIso8601String()),
      ),
      'photoPaths': photoPaths,
      'defectsNotes': defectsNotes,
    };
  }
  
  factory ProjectUnit.fromJson(Map<String, dynamic> json) {
    return ProjectUnit(
      unitId: json['unitId'] as String,
      unitName: json['unitName'] as String,
      floor: json['floor'] as int,
      stairCase: json['stairCase'] as String,
      isAlternateUnit: json['isAlternateUnit'] as bool? ?? false,
      specificSystems: (json['specificSystems'] as List?)?.map(
            (s) => ElectricalSystemType.values.firstWhere(
              (e) => e.name == s,
            ),
          ).toSet() ?? {},
      taskStatuses: (json['taskStatuses'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              TaskStatus.values.firstWhere((e) => e.name == v),
            ),
          ) ?? {},
      taskCompletionDates: (json['taskCompletionDates'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              v != null ? DateTime.parse(v as String) : null,
            ),
          ) ?? {},
      photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? [],
      defectsNotes: json['defectsNotes'] as String? ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POSTĘP PRAC DLA OBSZARÓW BUDYNKU
// ═══════════════════════════════════════════════════════════════════════════

enum BuildingAreaType { pomieszczenie, klatka, winda, garaz, dach }

/// Postęp prac, zdjęcia i notatki dla obszaru budynku (klatka, winda, garaż, dach, pomieszczenie)
class BuildingAreaProgress {
  final String areaId;
  final BuildingAreaType areaType;
  List<String> photoPaths;
  String notes;
  Map<String, bool> taskStatuses;

  BuildingAreaProgress({
    required this.areaId,
    required this.areaType,
    List<String>? photoPaths,
    this.notes = '',
    Map<String, bool>? taskStatuses,
  })  : photoPaths = photoPaths ?? [],
        taskStatuses = taskStatuses ?? {};

  static List<String> defaultTasksFor(BuildingAreaType type) {
    switch (type) {
      case BuildingAreaType.pomieszczenie:
        return [
          'Projekt',
          'Okablowanie',
          'Montaż osprzętu',
          'Pomiary',
          'Uruchomienie',
          'Odbiór',
        ];
      case BuildingAreaType.klatka:
        return [
          'Projekt',
          'Okablowanie klatki',
          'Oprawy klatki',
          'Domofonowa / SSP',
          'CCTV',
          'Pomiary',
          'Odbiór',
        ];
      case BuildingAreaType.winda:
        return [
          'Projekt',
          'Okablowanie maszynowni',
          'Instalacja elektryczna kabiny',
          'Podłączenie sterownika',
          'Uruchomienie',
          'Pomiary',
          'Odbiór techniczny',
        ];
      case BuildingAreaType.garaz:
        return [
          'Projekt',
          'Okablowanie',
          'Oświetlenie',
          'Bramy i napędy',
          'CCTV',
          'Ładowarki EV',
          'Pomiary',
          'Odbiór',
        ];
      case BuildingAreaType.dach:
        return [
          'Projekt',
          'Instalacja odgromowa',
          'Panele PV',
          'Okablowanie DC/AC',
          'Podłączenie falownika',
          'Pomiary i certyfikacja',
          'Odbiór',
        ];
    }
  }

  double get completionPercent {
    final tasks = defaultTasksFor(areaType);
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => taskStatuses[t] == true).length;
    return (done / tasks.length) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'areaId': areaId,
      'areaType': areaType.name,
      'photoPaths': photoPaths,
      'notes': notes,
      'taskStatuses': taskStatuses,
    };
  }

  factory BuildingAreaProgress.fromJson(Map<String, dynamic> json) {
    return BuildingAreaProgress(
      areaId: json['areaId'] as String,
      areaType: BuildingAreaType.values.firstWhere(
        (e) => e.name == json['areaType'],
        orElse: () => BuildingAreaType.pomieszczenie,
      ),
      photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String? ?? '',
      taskStatuses: (json['taskStatuses'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          {},
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
  final List<BuildingAreaProgress> buildingAreas; // Postęp obszarów budynku
  
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
    List<BuildingAreaProgress>? buildingAreas,
    DateTime? createdAt,
    this.lastModifiedAt,
  })  : buildingAreas = buildingAreas ?? [],
        createdAt = createdAt ?? DateTime.now();
  
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
  
  // Postęp projektu (0.0 - 1.0)
  double getProgress() {
    if (allTasks.isEmpty) return 0.0;
    final completed = allTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    return completed / allTasks.length;
  }
  
  // Szybki dostęp do nazwy projektu
  String get name => config.projectName;
  
  // Szybki dostęp do adresu projektu
  String get address => config.address;
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'config': config.toJson(),
      'phases': phases.map((p) => p.toJson()).toList(),
      'allTasks': allTasks.map((t) => t.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'units': units.map((u) => u.toJson()).toList(),
      'buildingAreas': buildingAreas.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }
  
  factory ConstructionProject.fromJson(Map<String, dynamic> json) {
    return ConstructionProject(
      projectId: json['projectId'] as String,
      config: BuildingConfiguration.fromJson(json['config'] as Map<String, dynamic>),
      phases: (json['phases'] as List)
          .map((p) => ProjectPhase.fromJson(p as Map<String, dynamic>))
          .toList(),
      allTasks: (json['allTasks'] as List)
          .map((t) => ChecklistTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      alerts: (json['alerts'] as List?)?.map(
            (a) => ProjectAlert.fromJson(a as Map<String, dynamic>),
          ).toList() ?? [],
      units: (json['units'] as List?)?.map(
            (u) => ProjectUnit.fromJson(u as Map<String, dynamic>),
          ).toList() ?? [],
      buildingAreas: (json['buildingAreas'] as List?)
              ?.map((a) => BuildingAreaProgress.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KALKULATOR HARMONOGRAMU I WARUNKI KLIMATYCZNE
// ═══════════════════════════════════════════════════════════════════════════

/// Warunki klimatyczne dla Polski - wpływają na prace na zewnątrz
class PolishClimateAnalyzer {
  /// Czy dany miesiąc jest sprzyjający dla prac na zewnątrz?
  /// - maj-wrzesień: idealne (100% wydajności)
  /// - kwiecień, październik: dobre (80% wydajności)
  /// - marzec, listopad: trudne (50% wydajności)
  /// - grudzień-luty: bardzo trudne do niemożliwe (0-20% wydajności)
  static double getOutdoorWorkEfficiency(DateTime date) {
    final month = date.month;
    
    switch (month) {
      case 5: case 6: case 7: case 8: case 9: // maj-wrzesień
        return 1.0; // 100% wydajności
      case 4: case 10: // kwiecień, październik
        return 0.8; // 80% wydajności
      case 3: case 11: // marzec, listopad
        return 0.5; // 50% wydajności
      default: // grudzień, styczeń, luty
        return 0.1; // 10% wydajności - prace możliwe tylko w warunkach osłoniętych
    }
  }
  
  /// Oblicz rzeczywisty czas na prace na zewnątrz uwzględniając warunki
  static int calculateOutdoorWorkDays(
    DateTime startDate,
    int estimatedDays,
  ) {
    int actualDays = 0;
    DateTime currentDate = startDate;
    int targetWorkDays = estimatedDays;
    
    while (actualDays < targetWorkDays) {
      double efficiency = getOutdoorWorkEfficiency(currentDate);
      if (efficiency > 0.3) { // Jeśli możliwe prace na zewnątrz
        actualDays += (efficiency * 1.0).toInt(); // Każdy dzień to mniej pracy
      }
      currentDate = currentDate.add(const Duration(days: 1));
      if (actualDays > estimatedDays * 3) break; // Prevent infinite loop
    }
    
    return (currentDate.difference(startDate).inDays).toInt();
  }
}

/// Ocena złożoności instalacji na podstawie wybranych systemów
class ComplexityCalculator {
  static const Map<ElectricalSystemType, double> systemComplexityWeights = {
    ElectricalSystemType.oswietlenie: 0.5,
    ElectricalSystemType.zasilanie: 0.5,
    ElectricalSystemType.klimatyzacja: 1.5,
    ElectricalSystemType.windaAscensor: 2.0,
    ElectricalSystemType.domofonowa: 1.0,
    ElectricalSystemType.telewizja: 0.8,
    ElectricalSystemType.internet: 0.7,
    ElectricalSystemType.odgromowa: 1.2,
    ElectricalSystemType.panelePV: 2.0,
    ElectricalSystemType.ladownarki: 1.5,
    ElectricalSystemType.agregat: 1.5,
    ElectricalSystemType.ppoz: 1.5,
    ElectricalSystemType.dso: 1.0,
    ElectricalSystemType.czujnikiRuchu: 0.8,
    ElectricalSystemType.podgrzewanePodjazdy: 1.0,
    ElectricalSystemType.ogrzewanieRur: 0.8,
    ElectricalSystemType.cctv: 1.0,
    ElectricalSystemType.sswim: 1.2,
    ElectricalSystemType.gaszeniGazem: 2.0,
    ElectricalSystemType.ewakuacyjne: 0.8,
    ElectricalSystemType.smartHome: 2.0,
    ElectricalSystemType.oddymianieKlatek: 1.5,
    ElectricalSystemType.bms: 2.5,
    ElectricalSystemType.wykrywaniWyciekow: 0.8,
    ElectricalSystemType.itp: 1.0,
  };
  
  /// Oblicz wskaźnik złożoności (0.5 - 3.0)
  /// Gdzie 1.0 to średnia złożoność
  static double calculateComplexityFactor(Set<ElectricalSystemType> systems) {
    if (systems.isEmpty) return 0.5; // Bardzo proste - tylko podstawowe
    
    double totalWeight = 0;
    for (final system in systems) {
      totalWeight += systemComplexityWeights[system] ?? 1.0;
    }
    
    double averageWeight = totalWeight / systems.length;
    // Normalizuj do zakresu 0.5 - 3.0
    return (0.5 + (averageWeight * 0.5)).clamp(0.5, 3.0);
  }
}

/// Główny kalkulator harmonogramu budowy
class ScheduleCalculator {
  /// Oblicz harmonogram etapów na podstawie całkowitego czasu budowy
  /// i parametrów budynku
  static Map<BuildingStage, int> calculateSchedule(
    BuildingConfiguration config,
  ) {
    // NOWE: Użyj bazy danych harmonogramu opartą na dokumencie
    // o etapach budowy budynków mieszkalnych i biurowych
    final baseProportions = config.buildingType == BuildingType.mieszkalny
        ? _getResidentialProportions()
        : _getCommercialProportions();
    
    // Mnożnik na podstawie złożoności systemów
    final complexityFactor = ComplexityCalculator.calculateComplexityFactor(
      config.selectedSystems,
    );
    
    // Mnożnik na podstawie liczby pięter
    final floorFactor = 1.0 + (config.totalLevels - 3) * 0.1;
    
    // Mnożnik na podstawie liczby klatek schodowych
    final stairCaseFactor = 1.0 + (config.estimatedStairCases - 1) * 0.05;
    
    // Całkowity mnożnik
    double totalMultiplier = complexityFactor * floorFactor * stairCaseFactor;
    
    // Normalizuj mnożnik aby harmonogram ukończył się w totalBuildingWeeks
    final baseTotal = baseProportions.values.fold<int>(0, (sum, v) => sum + v);
    final calculatedTotal = (baseTotal * totalMultiplier).toInt();
    final normalizedMultiplier = config.totalBuildingWeeks / calculatedTotal;
    
    // Zastosuj mnożnik do każdego etapu
    final schedule = <BuildingStage, int>{};
    for (final entry in baseProportions.entries) {
      int weeks = ((entry.value * normalizedMultiplier).round()).clamp(1, 52);
      schedule[entry.key] = weeks;
    }
    
    return schedule;
  }
  
  /// Bazowe proporcje dla budynków mieszkalnych
  /// Oparte na elemencie z dokumentu: "Budynek 5–8 kondygnacyjny"
  /// Czas: 18–24 miesiące (78-104 tygodnie)
  static Map<BuildingStage, int> _getResidentialProportions() {
    return {
      BuildingStage.przygotowanie: 2,  // 10-15% (2-4 miesiące)
      BuildingStage.fundamenty: 3,     // 15-20% (3-5 miesięcy)
      BuildingStage.konstrukcja: 7,    // 25-35% (5-8 miesięcy) - RDZEŃ HARMONOGRAMU
      BuildingStage.przegrody: 4,      // 15-20% (3-5 miesięcy)
      BuildingStage.tynki: 5,          // 15-20% (3-4 miesiące)
      BuildingStage.posadzki: 2,       // Część nakładana z innymi etapami
      BuildingStage.osprzet: 3,        // 25-30% nakładane na inne etapy
      BuildingStage.malowanie: 4,      // 15-20%
      BuildingStage.finalizacja: 2,    // Ostatnia faza
      BuildingStage.oddawanie: 1,      // 5-8% (1-2 miesiące)
    };
  }
  
  /// Bazowe proporcje dla budynków biurowych
  /// Zmodyfikowane ze względu na większe powierzchnie i większe obciążenia
  static Map<BuildingStage, int> _getCommercialProportions() {
    return {
      BuildingStage.przygotowanie: 2,  // 5%
      BuildingStage.fundamenty: 3,     // 7%
      BuildingStage.konstrukcja: 8,    // 19%
      BuildingStage.przegrody: 5,      // 12%
      BuildingStage.tynki: 6,          // 14%
      BuildingStage.posadzki: 2,       // 5%
      BuildingStage.osprzet: 4,        // 9%
      BuildingStage.malowanie: 5,      // 12%
      BuildingStage.finalizacja: 2,    // 5%
      BuildingStage.oddawanie: 2,      // 5%
    };
  }
  
  /// Wygeneruj fazy projektu z datami - NOWE: użyj ScheduleDataIntegration
  static List<ProjectPhase> generatePhases(
    BuildingConfiguration config,
    Map<BuildingStage, int> schedule,
  ) {
    // NOWE: Użyj integracji, która dynamicznie oblicza fazy na podstawie
    // liczby pięter, garaży i typu budynku
    return ScheduleDataIntegration.generateSchedulePhases(config);
  }
}

