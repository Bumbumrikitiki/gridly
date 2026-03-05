/// Hierarchiczna struktura budynków dla zaawansowanego Project Managera
/// 
/// Struktura:
/// Project
///  ├── Building (1..N)
///  │    ├── StairCase (A, B, C...) 
///  │    │    ├── Floor (0..N)
///  │    │    │    └── Units (1..N mieszkań)
///  │    │    └── numberOfElevators (0..N)
///  │    ├── basementLevels (0..N)

import 'renewable_energy_config.dart';
///  │    ├── hasGarage (bool)
///  │    └── hasParking (bool)

// ═══════════════════════════════════════════════════════════════════════════
// KLASY HIERARCHII
// ═══════════════════════════════════════════════════════════════════════════

/// Pojedyncza klatka schodowa
class StairCase {
  final String name; // A, B, C...
  final int numberOfFloors;
  final int numberOfElevators; // 0 = bez windy, 1+ = liczba wind
  final Map<int, int> unitsPerFloor; // floor -> number of units
  
  StairCase({
    required this.name,
    required this.numberOfFloors,
    required this.numberOfElevators,
    required this.unitsPerFloor,
  });
  
  /// Całkowita liczba mieszkań w tej klatce
  int get totalUnits => unitsPerFloor.values.fold(0, (sum, units) => sum + units);
  
  /// Czy ma windę?
  bool get hasElevator => numberOfElevators > 0;
}

/// Pojedynczy budynek
class Building {
  final String name; // Budynek 1, Budynek A...
  final int numberOfFloors; // Piętra nadziemne
  final int basementLevels; // Piętra podziemne
  final bool hasGarage;
  final bool hasParking;
  final List<StairCase> stairCases;
  
  Building({
    required this.name,
    required this.numberOfFloors,
    required this.basementLevels,
    required this.hasGarage,
    required this.hasParking,
    required this.stairCases,
  });
  
  /// Całkowita liczba mieszkań w budynku
  int get totalUnits => stairCases.fold(0, (sum, sc) => sum + sc.totalUnits);
  
  /// Całkowita liczba wind w budynku
  int get totalElevators => stairCases.fold(0, (sum, sc) => sum + sc.numberOfElevators);
  
  /// Czy budynek ma garaż z piętrami podziemnymi?
  bool get hasUndergroundLevels => basementLevels > 0;
}

/// Projekt z hierarchią budynków
class AdvancedProjectConfiguration {
  final String projectName;
  final String address;
  final DateTime projectStartDate;
  final DateTime projectEndDate;
  final List<Building> buildings;
  final Set<dynamic> selectedSystems; // ElectricalSystemType
  final RenewableEnergyConfig? renewableEnergyConfig;
  
  /// Twórcy mogą przechowywać dodatkowe dane
  final String notes;
  final DateTime createdAt;
  
  AdvancedProjectConfiguration({
    required this.projectName,
    required this.address,
    required this.projectStartDate,
    required this.projectEndDate,
    required this.buildings,
    required this.selectedSystems,
    this.renewableEnergyConfig,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Całkowita liczba mieszkań we wszystkich budynkach
  int get totalUnits => buildings.fold(0, (sum, b) => sum + b.totalUnits);
  
  /// Całkowita liczba pięter (wszytkie budynki)
  int get totalFloors => buildings.fold(0, (sum, b) => sum + b.numberOfFloors);
  
  /// Całkowita liczba klatek schodowych
  int get totalStairCases => buildings.fold(0, (sum, b) => sum + b.stairCases.length);
  
  /// Całkowita liczba wind
  int get totalElevators => buildings.fold(0, (sum, b) => sum + b.totalElevators);
  
  /// Czy jakikolwiek budynek ma garaż?
  bool get hasAnyGarage => buildings.any((b) => b.hasGarage);
  
  /// Czy jakikolwiek budynek ma parking?
  bool get hasAnyParking => buildings.any((b) => b.hasParking);
  
  /// Całkowita liczba pięter podziemnych (dla garagów)
  int get totalBasementLevels => buildings.fold(0, (sum, b) => sum + b.basementLevels);
  
  /// Całkowity czas projektu w tygodniach
  int get totalWeeks {
    final duration = projectEndDate.difference(projectStartDate);
    return (duration.inDays / 7).ceil();
  }
  
  /// Całkowity czas projektu w dniach
  int get totalDays => projectEndDate.difference(projectStartDate).inDays;
}
