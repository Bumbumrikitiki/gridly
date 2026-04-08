import 'package:flutter_test/flutter_test.dart';
import 'package:gridly/multitool/project_manager/logic/checklist_generator.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';

void main() {
  group('ProjectManager new systems schedule', () {
    test('selected systems generate dedicated tasks with due dates', () {
      final config = BuildingConfiguration(
        projectName: 'Systemy v2',
        buildingType: BuildingType.biurowy,
        address: 'ul. Testowa 10',
        projectStartDate: DateTime(2026, 1, 6),
        projectEndDate: DateTime(2026, 12, 18),
        numberOfBuildings: 1,
        hasGarage: true,
        hasParking: true,
        buildings: [
          BuildingDetails(
            buildingName: 'B1',
            stairCases: [
              StairCaseDetails(
                stairCaseName: 'A',
                numberOfLevels: 6,
                unitsPerFloor: const {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2},
                numberOfElevators: 2,
              ),
            ],
            basementLevels: 1,
          ),
        ],
        powerSupplyType: PowerSupplyType.przylaczeNN,
        connectionType: ConnectionType.rozdzielnicaNN,
        energySupplier: 'Enea',
        estimatedPowerDemand: 420,
        selectedSystems: {
          ElectricalSystemType.wlz,
          ElectricalSystemType.kd,
          ElectricalSystemType.ems,
          ElectricalSystemType.lan,
          ElectricalSystemType.wentylacja,
          ElectricalSystemType.floorboxy,
          ElectricalSystemType.smartHome,
          ElectricalSystemType.panelePV,
          ElectricalSystemType.ladownarki,
        },
        additionalRooms: const [],
        estimatedUnits: 24,
        totalBuildingWeeks: 52,
        currentBuildingStage: BuildingStage.przygotowanie,
      );

      final project = ProjectChecklistGenerator.generateProject(config);

      final dedicatedTasks = project.allTasks
          .where((task) => task.id.startsWith('sys-'))
          .toList();

      expect(dedicatedTasks, isNotEmpty);
      expect(
        dedicatedTasks.every((task) => task.dueDate != null),
        isTrue,
      );

      for (final system in config.selectedSystems) {
        final projectTask = project.allTasks.where(
          (task) => task.id == 'sys-${system.name}-01-projekt',
        );
        final installTask = project.allTasks.where(
          (task) => task.id == 'sys-${system.name}-02-montaz',
        );
        final acceptanceTask = project.allTasks.where(
          (task) => task.id == 'sys-${system.name}-03-odbior',
        );

        expect(projectTask.length, 1,
            reason: 'Brak zadania projektowego dla ${system.name}');
        expect(installTask.length, 1,
            reason: 'Brak zadania montażowego dla ${system.name}');
        expect(acceptanceTask.length, 1,
            reason: 'Brak zadania odbiorowego dla ${system.name}');
      }

      final pvAcceptance = project.allTasks.firstWhere(
        (task) => task.id == 'sys-panelePV-03-odbior',
      );
      expect(pvAcceptance.stage, BuildingStage.ozeInstalacje);

      final evAcceptance = project.allTasks.firstWhere(
        (task) => task.id == 'sys-ladownarki-03-odbior',
      );
      expect(evAcceptance.stage, BuildingStage.evInfrastruktura);
    });
  });
}
