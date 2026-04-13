import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/views/project_manager_screen.dart';
import 'package:gridly/multitool/project_manager/views/unit_detail_screen.dart';

BuildingConfiguration _testConfig() {
  return BuildingConfiguration(
    projectName: 'Osiedle Testowe',
    buildingType: BuildingType.mieszkalny,
    address: 'ul. Testowa 12, Warszawa',
    projectStartDate: DateTime(2026, 1, 1),
    projectEndDate: DateTime(2026, 12, 31),
    numberOfBuildings: 1,
    hasGarage: true,
    hasParking: true,
    buildings: [
      BuildingDetails(
        buildingName: 'Budynek 1',
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
    estimatedPowerDemand: 120,
    selectedSystems: {
      ElectricalSystemType.oswietlenie,
      ElectricalSystemType.zasilanie,
      ElectricalSystemType.lan,
      ElectricalSystemType.ppoz,
    },
    additionalRooms: const [],
    estimatedUnits: 4,
    totalBuildingWeeks: 52,
    currentBuildingStage: BuildingStage.przygotowanie,
  );
}

Future<ProjectManagerProvider> _seedProvider() async {
  SharedPreferences.setMockInitialValues({});
  final provider = ProjectManagerProvider();
  await provider.createNewProject(_testConfig());
  return provider;
}

Future<void> _pumpProjectManager(
  WidgetTester tester,
  ProjectManagerProvider provider, {
  required Size surfaceSize,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider<ProjectManagerProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: ProjectManagerScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpUnitDetail(
  WidgetTester tester,
  ProjectManagerProvider provider,
  ProjectUnit unit, {
  required Size surfaceSize,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider<ProjectManagerProvider>.value(
      value: provider,
      child: MaterialApp(
        home: UnitDetailScreen(unit: unit),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('Project manager mobile smoke tests', () {
    testWidgets('renders seeded project tabs in portrait viewport', (
      WidgetTester tester,
    ) async {
      final provider = await _seedProvider();

      await _pumpProjectManager(
        tester,
        provider,
        surfaceSize: const Size(412, 915),
      );

      expect(find.text('Asystent Budowy - Projekt'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Mieszkania'), findsOneWidget);
      expect(find.text('Klatki'), findsOneWidget);
      expect(find.text('Alerty'), findsOneWidget);
      expect(find.text('Harmonogram budowy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders seeded project area tabs', (
      WidgetTester tester,
    ) async {
      final provider = await _seedProvider();

      await _pumpProjectManager(
        tester,
        provider,
        surfaceSize: const Size(412, 915),
      );

      Future<void> openTab(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.pump();
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await openTab('Klatki');
      expect(find.text('Klatki schodowe: 1'), findsOneWidget);
      expect(find.textContaining('Budynek 1 · Klatka A'), findsWidgets);

      await openTab('Windy');
      expect(find.text('Windy: 1'), findsOneWidget);
      expect(find.textContaining('Winda 1'), findsOneWidget);

      await openTab('Garaż');
      expect(find.text('Garaż: 1'), findsOneWidget);
      expect(find.textContaining('Budynek 1 · Garaż'), findsOneWidget);

      await openTab('Dach');
      expect(find.text('Dach: 1'), findsOneWidget);
      expect(find.textContaining('Budynek 1 · Dach'), findsOneWidget);

      await openTab('Teren zewn.');
      expect(find.text('Teren zewnętrzny: 1'), findsOneWidget);
      expect(find.textContaining('Budynek 1 · Teren zewnętrzny'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders seeded unit detail screen', (
      WidgetTester tester,
    ) async {
      final provider = await _seedProvider();
      final unit = provider.currentProject!.units.first;
      final firstUnitLabel = provider.currentProject!.displayUnitId(unit);

      await _pumpUnitDetail(
        tester,
        provider,
        unit,
        surfaceSize: const Size(412, 915),
      );

      expect(find.text('Lokal $firstUnitLabel'), findsOneWidget);
      expect(find.text('Lokal zamienny'), findsOneWidget);
      expect(find.text('Zdjęcia'), findsOneWidget);
      expect(find.text('Notatki'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adds defect note for seeded unit', (
      WidgetTester tester,
    ) async {
      final provider = await _seedProvider();
      final unit = provider.currentProject!.units.first;
      final firstUnitLabel = provider.currentProject!.displayUnitId(unit);

      await _pumpUnitDetail(
        tester,
        provider,
        unit,
        surfaceSize: const Size(412, 915),
      );

      await tester.tap(find.text('Notatki'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      provider.addUnitDefectNote(
        unit.unitId,
        'Testowy defekt w lokalu $firstUnitLabel',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Defekty i notatki'), findsOneWidget);
      expect(find.text('Testowy defekt w lokalu $firstUnitLabel'), findsOneWidget);
      expect(
        provider.currentProject!.units
            .firstWhere((current) => current.unitId == unit.unitId)
            .defectsNotes,
        contains('Testowy defekt w lokalu $firstUnitLabel'),
      );
      expect(tester.takeException(), isNull);
    });
  });
}