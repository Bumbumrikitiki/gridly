/// Przykłady użycia: System dynamicznego harmonogramu budowy
/// 
/// Demonstracja jak system automatycznie dostosowuje harmonogram
/// na podstawie parametrów budynku
library;

import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/models/schedule_data_integration.dart';

class ConstructionScheduleExamples {
  
  /// PRZYKŁAD 1: Budynek mieszkalny 6 kondygnacji bez garaży
  /// Oczekiwany czas: ~16-18 miesięcy
  static BuildingConfiguration example1_SimpleResidential() {
    return BuildingConfiguration(
      projectName: 'Osiedle Słoneczne - Budynek A',
      buildingType: BuildingType.mieszkalny,
      address: 'ul. Słoneczna 10, Warszawa',
      projectStartDate: DateTime(2026, 3, 1),
      projectEndDate: DateTime(2027, 11, 1), // ~20 miesięcy (bufor)
      numberOfBuildings: 1,
      hasGarage: false,
      hasParking: true,
      buildings: [
        BuildingDetails(
          buildingName: 'Budynek A',
          stairCases: [
            StairCaseDetails(
              stairCaseName: 'A',
              numberOfLevels: 6,
              numberOfElevators: 1,
              unitsPerFloor: {
                0: 2, // Parter: 2 lokale
                1: 3, // I piętro: 3 lokale
                2: 3,
                3: 3,
                4: 3,
                5: 3,
              },
            ),
          ],
          basementLevels: 0,
        ),
      ],
      powerSupplyType: PowerSupplyType.przylaczeNN,
      connectionType: ConnectionType.rozdzielnicaNN,
      energySupplier: 'PGE',
      estimatedPowerDemand: 200.0,
      selectedSystems: {
        ElectricalSystemType.zasilanie,
        ElectricalSystemType.oswietlenie,
        ElectricalSystemType.domofonowa,
        ElectricalSystemType.internet,
        ElectricalSystemType.cctv,
        ElectricalSystemType.ppoz,
      },
      additionalRooms: [],
      estimatedUnits: 17,
      totalBuildingWeeks: 78, // ~18 miesięcy
      currentBuildingStage: BuildingStage.przygotowanie,
      notes: 'Budynek mieszkalny bez garaży podziemnych',
    );
  }

  /// PRZYKŁAD 2: Budynek mieszkalny 8 kondygnacji + garaż 1-poziomowy
  /// Oczekiwany czas: ~20-22 miesiące
  static BuildingConfiguration example2_ResidentialWithGarage() {
    return BuildingConfiguration(
      projectName: 'Osiedle Park - Budynek B',
      buildingType: BuildingType.mieszkalny,
      address: 'ul. Park 5, Kraków',
      projectStartDate: DateTime(2026, 4, 1),
      projectEndDate: DateTime(2028, 2, 1), // ~22 miesiące
      numberOfBuildings: 1,
      hasGarage: true,
      hasParking: false,
      buildings: [
        BuildingDetails(
          buildingName: 'Budynek B',
          stairCases: [
            StairCaseDetails(
              stairCaseName: 'B',
              numberOfLevels: 8,
              numberOfElevators: 2,
              unitsPerFloor: {
                0: 4, // Parter
                1: 4,
                2: 4,
                3: 4,
                4: 4,
                5: 4,
                6: 4,
                7: 4,
              },
            ),
          ],
          basementLevels: 1, // Garaż 1-poziomowy
        ),
      ],
      powerSupplyType: PowerSupplyType.przylaczeSNZTrafo,
      connectionType: ConnectionType.rozdzielnicaSN,
      energySupplier: 'TAURON',
      estimatedPowerDemand: 350.0,
      selectedSystems: {
        ElectricalSystemType.zasilanie,
        ElectricalSystemType.oswietlenie,
        ElectricalSystemType.windaAscensor,
        ElectricalSystemType.domofonowa,
        ElectricalSystemType.telewizja,
        ElectricalSystemType.internet,
        ElectricalSystemType.cctv,
        ElectricalSystemType.ppoz,
        ElectricalSystemType.smartHome,
      },
      additionalRooms: [],
      estimatedUnits: 32,
      totalBuildingWeeks: 96, // ~22 miesiące (78 bazowe + wpływ garażu)
      currentBuildingStage: BuildingStage.przygotowanie,
      notes: 'Budynek mieszkalny z garażem 1-poziomowym',
    );
  }

  /// PRZYKŁAD 3: Budynek mieszkalny 10 kondygnacji + garaż 2-poziomowy
  /// Oczekiwany czas: ~28-30 miesięcy
  /// UWAGA: To scenariusz wymagający rozszerzonych prac przygotowawczych
  static BuildingConfiguration example3_LargeResidentialTwoLevelGarage() {
    return BuildingConfiguration(
      projectName: 'Wieżowiec Downtown - Budynek C',
      buildingType: BuildingType.mieszkalny,
      address: 'ul. Centralna 100, Warszawa',
      projectStartDate: DateTime(2026, 5, 1),
      projectEndDate: DateTime(2029, 11, 1), // ~30 miesięcy
      numberOfBuildings: 1,
      hasGarage: true,
      hasParking: false,
      buildings: [
        BuildingDetails(
          buildingName: 'Budynek C - Wieżowiec',
          stairCases: [
            StairCaseDetails(
              stairCaseName: 'A',
              numberOfLevels: 10,
              numberOfElevators: 3,
              unitsPerFloor: {
                1: 6,
                2: 6,
                3: 6,
                4: 6,
                5: 6,
                6: 6,
                7: 6,
                8: 6,
                9: 6,
                10: 4, // Penthouse
              },
            ),
          ],
          basementLevels: 2, // Garaż 2-poziomowy !!!
        ),
      ],
      powerSupplyType: PowerSupplyType.przylaczeSNZTrafo,
      connectionType: ConnectionType.rozdzielnicaSN,
      energySupplier: 'ENEA',
      estimatedPowerDemand: 600.0,
      selectedSystems: {
        ElectricalSystemType.zasilanie,
        ElectricalSystemType.oswietlenie,
        ElectricalSystemType.windaAscensor,
        ElectricalSystemType.domofonowa,
        ElectricalSystemType.telewizja,
        ElectricalSystemType.internet,
        ElectricalSystemType.cctv,
        ElectricalSystemType.ppoz,
        ElectricalSystemType.smartHome,
        ElectricalSystemType.bms,
        ElectricalSystemType.oddymianieKlatek,
      },
      additionalRooms: [],
      estimatedUnits: 58,
      totalBuildingWeeks: 130, // ~30 miesięcy
      currentBuildingStage: BuildingStage.przygotowanie,
      notes: 'Wieżowiec z garazem 2-poziomowym - wymagane specjalistyczne prace',
    );
  }

  /// PRZYKŁAD 4: Budynek biurowy 6 kondygnacji
  /// Oczekiwany czas: ~20-22 miesiące
  static BuildingConfiguration example4_CommercialBuilding() {
    return BuildingConfiguration(
      projectName: 'Business Park - Tower A',
      buildingType: BuildingType.biurowy,
      address: 'ul. Biznesu 1, Poznań',
      projectStartDate: DateTime(2026, 6, 1),
      projectEndDate: DateTime(2028, 4, 1), // ~22 miesiące
      numberOfBuildings: 1,
      hasGarage: true,
      hasParking: true,
      buildings: [
        BuildingDetails(
          buildingName: 'Tower A',
          stairCases: [
            StairCaseDetails(
              stairCaseName: 'A',
              numberOfLevels: 6,
              numberOfElevators: 3,
            ),
          ],
          basementLevels: 1, // Biuro ma mała parkingi podziemne
        ),
      ],
      powerSupplyType: PowerSupplyType.przylaczeSNZTrafo,
      connectionType: ConnectionType.rozdzielnicaSN,
      energySupplier: 'ORLEN',
      estimatedPowerDemand: 800.0,
      selectedSystems: {
        ElectricalSystemType.zasilanie,
        ElectricalSystemType.oswietlenie,
        ElectricalSystemType.windaAscensor,
        ElectricalSystemType.klimatyzacja,
        ElectricalSystemType.internet,
        ElectricalSystemType.cctv,
        ElectricalSystemType.ppoz,
        ElectricalSystemType.bms,
        ElectricalSystemType.panelePV,
      },
      additionalRooms: [],
      estimatedUnits: 24, // 24 biura
      totalBuildingWeeks: 104, // ~24 miesiące
      currentBuildingStage: BuildingStage.przygotowanie,
      notes: 'Budynek biurowy nowoczesny z certyfikacją zielonego budownictwa',
    );
  }

  /// FUNKCJA TESTOWA: Pokaż harmonogram dla konfiguracji
  static void printScheduleAnalysis(BuildingConfiguration config) {
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║         ANALIZA HARMONOGRAMU BUDOWY                       ║');
    print('╚═══════════════════════════════════════════════════════════╝\n');

    print('📋 PROJEKT: ${config.projectName}');
    print('📍 ADRES: ${config.address}');
    print('🏢 TYP: ${config.buildingType == BuildingType.mieszkalny ? 'Mieszkalny' : 'Biurowy'}');
    print('');

    // Oblicz harmonogram
    final totalWeeks = ScheduleDataIntegration.calculateProjectDurationWeeks(config);
    final months = (totalWeeks / 4.33).toStringAsFixed(1);
    
    print('⏱️  CAŁKOWITY CZAS BUDOWY:');
    print('   • Tygodnie: $totalWeeks');
    print('   • Miesiące: $months');
    print('   • Okres: ${config.projectStartDate.toIso8601String().split('T')[0]} do ${config.projectEndDate.toIso8601String().split('T')[0]}');
    print('');

    print('🏗️  PARAMETRY BUDYNKU:');
    print('   • Pięter nadziemnych: ${config.totalLevels}');
    print('   • Pięter podziemnych: ${config.basementLevels}');
    print('   • Liczba klatek: ${config.estimatedStairCases}');
    print('   • Liczba wind: ${config.numberOfElevators}');
    print('');

    print('⚡ SYSTEMY ELEKTRYCZNE (${config.selectedSystems.length}):');
    for (final system in config.selectedSystems) {
      final systemName = system.toString().split('.').last;
      print('   • $systemName');
    }
    print('');

    // Generuj fazy
    final phases = ScheduleDataIntegration.generateSchedulePhases(config);
    
    print('📅 ETAPY BUDOWY:');
    print('┌────────────────────────────────────┬──────────┬──────────┐');
    print('│ ETAP                               │ POCZĄTEK │ KONIEC   │');
    print('├────────────────────────────────────┼──────────┼──────────┤');
    
    for (final phase in phases) {
      final stageName = phase.stage.name.padRight(34);
      final start = phase.startDate.toIso8601String().split('T')[0];
      final end = phase.endDate.toIso8601String().split('T')[0];
      print('│ $stageName │ $start │ $end │');
    }
    print('└────────────────────────────────────┴──────────┴──────────┘');
    print('');

    // Pokaż wpływ garaży
    if (config.basementLevels > 0) {
      print('⚠️  WPŁYW GARAŻY PODZIEMNYCH:');
      print('   • Garaż ${config.basementLevels}-poziomowy dodaje dodatkowe ~${config.basementLevels * 2} miesiące');
      print('   • Krytyczne: faza fundamentów będzie dłuższa niż standardowo');
      print('');
    }

    // Pokaż wpływ na liczbę pięter
    if (config.totalLevels > 8) {
      final extraFloors = config.totalLevels - 8;
      final extraWeeks = extraFloors * 3;
      print('📈 WPŁYW DODATKOWYCH PIĘTER:');
      print('   • ${config.totalLevels} pięter (vs. 8 standardowych)');
      print('   • Dodatkowe ~$extraWeeks tygodni = ${(extraWeeks / 4.33).toStringAsFixed(1)} miesięcy');
      print('');
    }

    print('═══════════════════════════════════════════════════════════\n');
  }

  /// FUNKCJA TESTOWA: Porównaj harmonogramy dla różnych scenariuszy
  static void compareScenarios() {
    print('\n╔═══════════════════════════════════════════════════════════╗');
    print('║     PORÓWNANIE SCENARIUSZY HARMONOGRAMU                    ║');
    print('╚═══════════════════════════════════════════════════════════╝\n');

    final scenarios = [
      ('Scenariusz 1: 6 pięter bez garażu', example1_SimpleResidential()),
      ('Scenariusz 2: 8 pięter + garaż 1-poz.', example2_ResidentialWithGarage()),
      ('Scenariusz 3: 10 pięter + garaż 2-poz.', example3_LargeResidentialTwoLevelGarage()),
      ('Scenariusz 4: Biurowiec 6 pięter', example4_CommercialBuilding()),
    ];

    print('┌──────────────────────────────┬──────────┬──────────┬──────────────┐');
    print('│ SCENARIUSZ                   │ TYGODNIE │ MIESIĄCE │ GARAŻ        │');
    print('├──────────────────────────────┼──────────┼──────────┼──────────────┤');

    for (final (name, config) in scenarios) {
      final weeks = ScheduleDataIntegration.calculateProjectDurationWeeks(config);
      final months = (weeks / 4.33).toStringAsFixed(1);
      final garage = config.basementLevels == 0 ? 'brak' : '${config.basementLevels}-poz.';
      
      print('│ ${name.padRight(28)} │ ${weeks.toString().padRight(8)} │ ${months.padRight(8)} │ ${garage.padRight(12)} │');
    }

    print('└──────────────────────────────┴──────────┴──────────┴──────────────┘\n');
  }
}

/// TEST: Uruchom przykłady
void main() {
  print('🧪 TESTING: System harmonogramu budowy\n');

  // Test 1: Budynek prosty
  ConstructionScheduleExamples.printScheduleAnalysis(
    ConstructionScheduleExamples.example1_SimpleResidential(),
  );

  // Test 2: Budynek z garażem
  ConstructionScheduleExamples.printScheduleAnalysis(
    ConstructionScheduleExamples.example2_ResidentialWithGarage(),
  );

  // Test 3: Porównanie scenariuszy
  ConstructionScheduleExamples.compareScenarios();

  print('✅ Testy ukończone!\n');
}
