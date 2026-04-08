import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/checklist_generator.dart';
import 'dart:convert';

void main() {
  group('Project Persistence Tests', () {
    setUp(() {
      // Zresetuj SharedPreferences dla testów
      SharedPreferences.setMockInitialValues({});
    });

    test('BuildingConfiguration should serialize and deserialize correctly',
        () {
      // Arrange
      final config = BuildingConfiguration(
        projectName: 'Test Project',
        buildingType: BuildingType.mieszkalny,
        address: 'ul. Testowa 1',
        projectStartDate: DateTime(2024, 1, 1),
        projectEndDate: DateTime(2024, 12, 31),
        numberOfBuildings: 1,
        hasGarage: true,
        hasParking: true,
        buildings: [
          BuildingDetails(
            buildingName: 'Budynek 1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'A',
                numberOfLevels: 5,
                numberOfElevators: 1,
              ),
            ],
            basementLevels: 1,
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 50.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: [],
        estimatedUnits: 50,
        totalBuildingWeeks: 52,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      // Act
      final json = config.toJson();
      final restored = BuildingConfiguration.fromJson(json);

      // Assert
      expect(restored.projectName, equals(config.projectName));
      expect(restored.address, equals(config.address));
      expect(restored.numberOfBuildings, equals(1));
      expect(
          restored.selectedSystems.contains(ElectricalSystemType.oswietlenie),
          true);
      print('✅ BuildingConfiguration serialization passed');
    });

    test('BuildingConfiguration should persist unit numbering settings', () {
      final config = BuildingConfiguration(
        projectName: 'Numeracja Test',
        buildingType: BuildingType.mieszkalny,
        address: 'ul. Lokalowa 7',
        projectStartDate: DateTime(2024, 1, 1),
        projectEndDate: DateTime(2024, 12, 31),
        numberOfBuildings: 1,
        hasGarage: false,
        hasParking: true,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'A',
                numberOfLevels: 1,
                unitsPerFloor: const {1: 3},
                floorNames: const {1: 'Piętro 1'},
                floorUnitNumbering: const {
                  1: FloorUnitNumberingConfig(
                    constructionStartLabel: 'A.007',
                    targetStartLabel: 'M.201',
                  ),
                },
              ),
            ],
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 25.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: [],
        defaultUnitNamingScheme: UnitNamingScheme.target,
        estimatedUnits: 3,
        totalBuildingWeeks: 20,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final restored = BuildingConfiguration.fromJson(config.toJson());

      expect(restored.defaultUnitNamingScheme, UnitNamingScheme.target);
      expect(
        restored.buildings.first.stairCases.first
            .getFloorUnitNumbering(1)
            .constructionStartLabel,
        'A.007',
      );
      expect(
        restored.buildings.first.stairCases.first
            .getFloorUnitNumbering(1)
            .targetStartLabel,
        'M.201',
      );
    });

    test('BuildingConfiguration should persist subcontractors by areas', () {
      final config = BuildingConfiguration(
        projectName: 'Podwykonawcy Test',
        buildingType: BuildingType.mieszkalny,
        address: 'ul. Branżowa 11',
        projectStartDate: DateTime(2024, 1, 1),
        projectEndDate: DateTime(2024, 12, 31),
        numberOfBuildings: 1,
        hasGarage: true,
        hasParking: true,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'A',
                numberOfLevels: 2,
                unitsPerFloor: const {1: 2, 2: 2},
                numberOfElevators: 1,
              ),
            ],
            basementLevels: 1,
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 40.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: const [],
        subcontractors: [
          SubcontractorAssignment(
            id: 'sub-1',
            companyName: 'Elektro-Instal',
            areas: {
              SubcontractorArea.stairCases,
              SubcontractorArea.residentialUnits,
            },
            responsibilities: 'Elektryka i osprzęt mieszkaniowy',
            details: 'Brygada A i B, zakończenie do etapu osprzętu.',
          ),
          SubcontractorAssignment(
            id: 'sub-2',
            companyName: 'TechNet',
            areas: {
              SubcontractorArea.elevators,
              SubcontractorArea.garage,
              SubcontractorArea.externalArea,
            },
            responsibilities: 'Teletechnika i CCTV',
            details: 'Koordynacja tras kablowych z generalnym wykonawcą.',
          ),
        ],
        subcontractorLinks: const [
          SubcontractorLink(
            subcontractorId: 'sub-1',
            targetType: SubcontractorTargetType.building,
            targetId: 'building:0',
          ),
          SubcontractorLink(
            subcontractorId: 'sub-1',
            targetType: SubcontractorTargetType.stairCase,
            targetId: 'staircase:0:A',
          ),
          SubcontractorLink(
            subcontractorId: 'sub-1',
            targetType: SubcontractorTargetType.floor,
            targetId: 'floor:0:A:1',
          ),
          SubcontractorLink(
            subcontractorId: 'sub-1',
            targetType: SubcontractorTargetType.unit,
            targetId: 'unit:0:A:1:0',
          ),
          SubcontractorLink(
            subcontractorId: 'sub-1',
            targetType: SubcontractorTargetType.system,
            targetId: 'system:internet',
          ),
          SubcontractorLink(
            subcontractorId: 'sub-2',
            targetType: SubcontractorTargetType.renewable,
            targetId: 'renewable:pv',
          ),
        ],
        estimatedUnits: 4,
        totalBuildingWeeks: 24,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final restored = BuildingConfiguration.fromJson(config.toJson());

      expect(restored.subcontractors, hasLength(2));
      expect(restored.subcontractors.first.companyName, 'Elektro-Instal');
      expect(
        restored.subcontractors.first.areas
            .contains(SubcontractorArea.stairCases),
        isTrue,
      );
      expect(
        restored.subcontractors[1].areas.contains(SubcontractorArea.elevators),
        isTrue,
      );
      expect(
          restored.subcontractors[1].responsibilities, 'Teletechnika i CCTV');
      expect(restored.subcontractorLinks, hasLength(6));
      expect(restored.subcontractorLinks.first.targetType,
          SubcontractorTargetType.building);
      expect(restored.subcontractorLinks[1].targetType,
          SubcontractorTargetType.stairCase);
      expect(restored.subcontractorLinks[2].targetType,
          SubcontractorTargetType.floor);
      expect(restored.subcontractorLinks[3].targetType,
          SubcontractorTargetType.unit);
      expect(restored.subcontractorLinks[4].targetId, 'system:internet');
    });

    test('BuildingConfiguration should persist inheritance-block links', () {
      final config = BuildingConfiguration(
        projectName: 'Blokada dziedziczenia',
        buildingType: BuildingType.mieszkalny,
        address: 'ul. Testowa 16',
        projectStartDate: DateTime(2024, 1, 1),
        projectEndDate: DateTime(2024, 12, 31),
        numberOfBuildings: 1,
        hasGarage: false,
        hasParking: false,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'A',
                numberOfLevels: 1,
                unitsPerFloor: const {1: 2},
              ),
            ],
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 20.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: const [],
        subcontractors: [
          SubcontractorAssignment(
            id: 'sub-1',
            companyName: 'Elektro-Instal',
          ),
        ],
        subcontractorLinks: const [
          SubcontractorLink(
            subcontractorId: '',
            targetType: SubcontractorTargetType.unit,
            targetId: 'unit:0:A:1:0',
            blockInheritance: true,
          ),
        ],
        estimatedUnits: 2,
        totalBuildingWeeks: 16,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final restored = BuildingConfiguration.fromJson(config.toJson());

      expect(restored.subcontractorLinks, hasLength(1));
      expect(restored.subcontractorLinks.first.blockInheritance, isTrue);
      expect(restored.subcontractorLinks.first.targetType,
          SubcontractorTargetType.unit);
      expect(restored.subcontractorLinks.first.targetId, 'unit:0:A:1:0');
    });

    test('Project generator should create construction and target unit labels',
        () {
      final config = BuildingConfiguration(
        projectName: 'Generator Numeracji',
        buildingType: BuildingType.mieszkalny,
        address: 'ul. Testowa 9',
        projectStartDate: DateTime(2024, 1, 1),
        projectEndDate: DateTime(2024, 12, 31),
        numberOfBuildings: 1,
        hasGarage: false,
        hasParking: false,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'A',
                numberOfLevels: 1,
                unitsPerFloor: const {1: 3},
                floorUnitNumbering: const {
                  1: FloorUnitNumberingConfig(
                    constructionStartLabel: 'A.007',
                    targetStartLabel: 'D.201',
                  ),
                },
              ),
            ],
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 30.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: [],
        defaultUnitNamingScheme: UnitNamingScheme.target,
        estimatedUnits: 3,
        totalBuildingWeeks: 20,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final project = ProjectChecklistGenerator.generateProject(config);

      expect(project.units, hasLength(3));
      expect(project.units.first.unitId, 'B1-A101');
      expect(project.units.first.constructionUnitId, 'A.007');
      expect(project.units.first.targetUnitId, 'D.201');
      expect(project.units[1].constructionUnitId, 'A.008');
      expect(project.units[2].targetUnitId, 'D.203');
      expect(project.displayUnitId(project.units.first), 'D.201');
    });

    test(
        'Project generator should handle update from zero units with multi-char staircase',
        () {
      final initialConfig = BuildingConfiguration(
        projectName: 'Bez Lokali Start',
        buildingType: BuildingType.mieszkalny,
        address: 'ul. Testowa 12',
        projectStartDate: DateTime(2024, 1, 1),
        projectEndDate: DateTime(2024, 12, 31),
        numberOfBuildings: 1,
        hasGarage: false,
        hasParking: false,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'K1',
                numberOfLevels: 1,
                unitsPerFloor: const {1: 0},
              ),
            ],
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 20.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: [],
        estimatedUnits: 0,
        totalBuildingWeeks: 20,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final initialProject =
          ProjectChecklistGenerator.generateProject(initialConfig);
      expect(initialProject.units, isEmpty);

      final updatedConfig = BuildingConfiguration(
        projectName: initialConfig.projectName,
        buildingType: initialConfig.buildingType,
        address: initialConfig.address,
        projectStartDate: initialConfig.projectStartDate,
        projectEndDate: initialConfig.projectEndDate,
        numberOfBuildings: initialConfig.numberOfBuildings,
        hasGarage: initialConfig.hasGarage,
        hasParking: initialConfig.hasParking,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'K1',
                numberOfLevels: 1,
                unitsPerFloor: const {1: 2},
              ),
            ],
          ),
        ],
        powerSupplyType: initialConfig.powerSupplyType,
        connectionType: initialConfig.connectionType,
        energySupplier: initialConfig.energySupplier,
        estimatedPowerDemand: initialConfig.estimatedPowerDemand,
        selectedSystems: initialConfig.selectedSystems,
        additionalRooms: initialConfig.additionalRooms,
        estimatedUnits: 2,
        totalBuildingWeeks: initialConfig.totalBuildingWeeks,
        currentBuildingStage: initialConfig.currentBuildingStage,
      );

      final updatedProject =
          ProjectChecklistGenerator.generateProject(updatedConfig);
      expect(updatedProject.units, hasLength(2));
      expect(updatedProject.units.first.stairCase, 'K1');
      expect(updatedProject.units.first.floor, 1);
    });

    test(
        'Project generator should handle staircase names with dash after zero-units update',
        () {
      final initialConfig = BuildingConfiguration(
        projectName: 'Bez Lokali Klatka Dash',
        buildingType: BuildingType.mieszkalny,
        address: 'ul. Testowa 15',
        projectStartDate: DateTime(2024, 1, 1),
        projectEndDate: DateTime(2024, 12, 31),
        numberOfBuildings: 1,
        hasGarage: false,
        hasParking: false,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'K-1',
                numberOfLevels: 1,
                unitsPerFloor: const {1: 0},
              ),
            ],
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 20.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: [],
        estimatedUnits: 0,
        totalBuildingWeeks: 20,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final initialProject =
          ProjectChecklistGenerator.generateProject(initialConfig);
      expect(initialProject.units, isEmpty);

      final updatedConfig = BuildingConfiguration(
        projectName: initialConfig.projectName,
        buildingType: initialConfig.buildingType,
        address: initialConfig.address,
        projectStartDate: initialConfig.projectStartDate,
        projectEndDate: initialConfig.projectEndDate,
        numberOfBuildings: initialConfig.numberOfBuildings,
        hasGarage: initialConfig.hasGarage,
        hasParking: initialConfig.hasParking,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'K-1',
                numberOfLevels: 1,
                unitsPerFloor: const {1: 2},
              ),
            ],
          ),
        ],
        powerSupplyType: initialConfig.powerSupplyType,
        connectionType: initialConfig.connectionType,
        energySupplier: initialConfig.energySupplier,
        estimatedPowerDemand: initialConfig.estimatedPowerDemand,
        selectedSystems: initialConfig.selectedSystems,
        additionalRooms: initialConfig.additionalRooms,
        estimatedUnits: 2,
        totalBuildingWeeks: initialConfig.totalBuildingWeeks,
        currentBuildingStage: initialConfig.currentBuildingStage,
      );

      final updatedProject =
          ProjectChecklistGenerator.generateProject(updatedConfig);
      expect(updatedProject.units, hasLength(2));
      expect(updatedProject.units.first.stairCase, 'K-1');
      expect(updatedProject.units.first.floor, 1);
    });

    test('ConstructionProject should serialize and deserialize correctly', () {
      // Arrange - najpierw stworzymy minimalny projekt
      final config = BuildingConfiguration(
        projectName: 'Minimal Test Project',
        buildingType: BuildingType.mieszkalny,
        address: 'Test 1',
        projectStartDate: DateTime.now(),
        projectEndDate: DateTime.now().add(Duration(days: 365)),
        numberOfBuildings: 1,
        hasGarage: false,
        hasParking: false,
        buildings: [
          BuildingDetails(
            buildingName: 'A',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'A',
                numberOfLevels: 2,
              ),
            ],
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Test',
        estimatedPowerDemand: 10.0,
        selectedSystems: {ElectricalSystemType.oswietlenie},
        additionalRooms: [],
        estimatedUnits: 10,
        totalBuildingWeeks: 26,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final project = ConstructionProject(
        projectId: 'test-001',
        config: config,
        phases: [],
        allTasks: [],
        alerts: [],
        units: [],
        createdAt: DateTime.now(),
      );

      // Act
      final json = project.toJson();
      print('🔍 Serialized JSON keys: ${json.keys.toList()}');

      final jsonString = jsonEncode(json);
      print('📝 JSON string length: ${jsonString.length}');

      final restored = ConstructionProject.fromJson(json);

      // Assert
      expect(restored.projectId, equals(project.projectId));
      expect(restored.name, equals('Minimal Test Project'));
      expect(restored.address, equals('Test 1'));
      print('✅ ConstructionProject serialization passed');
    });

    test('SharedPreferences save and load simulation', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final config = BuildingConfiguration(
        projectName: 'Prefs Test',
        buildingType: BuildingType.mieszkalny,
        address: 'Prefs St',
        projectStartDate: DateTime.now(),
        projectEndDate: DateTime.now().add(Duration(days: 100)),
        numberOfBuildings: 1,
        hasGarage: false,
        hasParking: false,
        buildings: [
          BuildingDetails(
            buildingName: 'A',
            stairCases: [
              StairCaseDetails(stairCaseName: 'A', numberOfLevels: 1)
            ],
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Test',
        estimatedPowerDemand: 5.0,
        selectedSystems: {},
        additionalRooms: [],
        estimatedUnits: 5,
        totalBuildingWeeks: 10,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final project = ConstructionProject(
        projectId: 'prefs-001',
        config: config,
        phases: [],
        allTasks: [],
      );

      // Act - Save
      final projectsList = [project];
      final projectsJson =
          jsonEncode(projectsList.map((p) => p.toJson()).toList());
      await prefs.setString('construction_projects', projectsJson);

      print('💾 Saved to SharedPreferences: ${projectsJson.length} chars');

      // Act - Load
      final loaded = prefs.getString('construction_projects');
      expect(loaded, isNotNull);

      final decoded = jsonDecode(loaded!) as List;
      final restoredProject =
          ConstructionProject.fromJson(decoded[0] as Map<String, dynamic>);

      // Assert
      expect(restoredProject.projectId, equals('prefs-001'));
      expect(restoredProject.name, equals('Prefs Test'));
      print('✅ SharedPreferences save/load passed');
    });
  });
}
