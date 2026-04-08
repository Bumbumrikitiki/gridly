import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/models/construction_schedule_data.dart';
import 'package:gridly/multitool/project_manager/models/schedule_data_integration.dart';
import 'package:gridly/multitool/project_manager/models/renewable_energy_config.dart';

class ConfigurationWizardScreen extends StatefulWidget {
  final bool editMode;
  final BuildingConfiguration? existingConfig;
  final int initialStep;

  const ConfigurationWizardScreen({
    super.key,
    required this.editMode,
    this.existingConfig,
    this.initialStep = 0,
  });

  @override
  State<ConfigurationWizardScreen> createState() =>
      _ConfigurationWizardScreenState();
}

class _ConfigurationWizardScreenState extends State<ConfigurationWizardScreen> {
  int _currentStep = 0;

  // Step 1: Dane podstawowe
  late String _projectName;
  late BuildingType _buildingType;
  late String _address;
  late DateTime _projectStartDate;
  late DateTime _projectEndDate;
  late TextEditingController _projectNameController;
  late TextEditingController _addressController;

  // Step 6: Parametry budynków
  late int _numberOfBuildings;
  late bool _hasGarage;
  late bool _hasParking;
  late List<BuildingDetails> _buildings;
  late UnitNamingScheme _defaultUnitNamingScheme;

  // Step 4: Zasilanie
  late PowerSupplyType _powerSupply;
  late ConnectionType _connectionType;
  late PowerSupplyArchitectureType _powerSupplyArchitecture;
  bool _offGridMode = false;
  bool _backupUps = false;
  bool _backupGenerator = false;
  bool _backupCombo = false;
  late String _energySupplier;
  late String _customEnergySupplier;

  // Step 5: Systemy
  late Set<ElectricalSystemType> _selectedSystems;

  // Step 7: Pomieszczenia dodatkowe
  late List<AdditionalRoom> _additionalRooms;
  late List<SubcontractorAssignment> _subcontractors;
  late List<SubcontractorLink> _subcontractorLinks;

  // Step 2: Harmonogram i etap
  late int _totalBuildingWeeks;
  late BuildingStage _currentBuildingStage;

  // Step 8: OZE i Elektromobilność
  bool _hasPV = false;
  double _pvPowerKwp = 0.0;
  bool _hasBESS = false;
  double _bessCapacityKwh = 0.0;
  bool _hasEVCharging = false;
  int _evChargingStationsCount = 0;
  DlmSystemType _dlmSystemType = DlmSystemType.none;

  static const List<String> _energySuppliers = [
    'PGE',
    'Tauron',
    'Enea',
    'Energa',
    'E.ON',
    'Inny',
  ];

  static const List<String> _additionalRoomTypes = [
    'Rozdzielnia główna',
    'Rozdzielnia teletechniczna',
    'Rozdzielnia SN',
    'Pomieszczenie trafo',
    'Pomieszczenie hydroforu',
    'Węzeł ciepła',
    'Wózkownia',
    'Komórki lokatorskie',
    'Pomieszczenie ochrony',
    'Pomieszczenie techniczne',
    'Magazyn',
    'Pomieszczenie sprzątania',
    'Inne',
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, 7);

    // Check if we're in edit mode and have existing config
    if (widget.editMode && widget.existingConfig != null) {
      final config = widget.existingConfig!;

      // Pre-populate all fields from existing config
      _projectName = config.projectName;
      _buildingType = config.buildingType;
      _address = config.address;
      _projectStartDate = config.projectStartDate;
      _projectEndDate = config.projectEndDate;

      _numberOfBuildings = config.numberOfBuildings;
      _hasGarage = config.hasGarage;
      _hasParking = config.hasParking;
      _buildings = List<BuildingDetails>.from(config.buildings);
      _defaultUnitNamingScheme = config.defaultUnitNamingScheme;

      _powerSupply = config.powerSupplyType;
      _connectionType = config.connectionType;
      _powerSupplyArchitecture = config.powerSupplyArchitecture;
      _offGridMode = config.offGridMode;
      _backupUps =
          config.backupSystems.any((s) => s.type == BackupSystemType.ups);
      _backupGenerator =
          config.backupSystems.any((s) => s.type == BackupSystemType.generator);
      _backupCombo = config.backupSystems
          .any((s) => s.type == BackupSystemType.upsGeneratorCombo);
      if (_energySuppliers.contains(config.energySupplier)) {
        _energySupplier = config.energySupplier;
        _customEnergySupplier = '';
      } else {
        _energySupplier = 'Inny';
        _customEnergySupplier = config.energySupplier;
      }
      _selectedSystems = Set<ElectricalSystemType>.from(config.selectedSystems);
      _additionalRooms = List<AdditionalRoom>.from(config.additionalRooms);
      _subcontractors =
          List<SubcontractorAssignment>.from(config.subcontractors);
      _subcontractorLinks =
          List<SubcontractorLink>.from(config.subcontractorLinks);

      _totalBuildingWeeks = config.totalBuildingWeeks;
      _currentBuildingStage = config.currentBuildingStage;

      // Load OZE/EV configuration if exists
      if (config.renewableEnergyConfig != null) {
        final ozeConfig = config.renewableEnergyConfig!;
        _hasPV = ozeConfig.photovoltaic.isEnabled;
        _pvPowerKwp = ozeConfig.photovoltaic.installedPowerKwp;
        _hasBESS = ozeConfig.batteryStorage.isEnabled;
        _bessCapacityKwh = ozeConfig.batteryStorage.storageSizeKwh;
        _hasEVCharging = ozeConfig.electricMobility.isEnabled;
        _evChargingStationsCount =
            ozeConfig.electricMobility.chargingStations.length;
        _dlmSystemType = ozeConfig.electricMobility.dlmSystem;
      }
    } else {
      // Default initialization for new project
      _projectName = '';
      _buildingType = BuildingType.mieszkalny;
      _address = '';
      _projectStartDate = DateTime.now();
      _projectEndDate =
          DateTime.now().add(const Duration(days: 224)); // ~32 tygodnie

      _numberOfBuildings = 1;
      _hasGarage = false;
      _hasParking = false;
      _defaultUnitNamingScheme = UnitNamingScheme.construction;

      // Inicjalizuj budynki z domyślną konfiguracją
      _buildings = [
        BuildingDetails(
          buildingName: 'Budynek 1',
          stairCases: [
            StairCaseDetails(stairCaseName: 'A', numberOfLevels: 3),
            StairCaseDetails(stairCaseName: 'B', numberOfLevels: 3),
          ],
        ),
      ];

      _powerSupply = PowerSupplyType.przylaczeNN;
      _connectionType = ConnectionType.zlaczeDynamiczne;
      _powerSupplyArchitecture = PowerSupplyArchitectureType.lvDirect;
      _offGridMode = false;
      _backupUps = false;
      _backupGenerator = false;
      _backupCombo = false;
      _energySupplier = _energySuppliers.first;
      _customEnergySupplier = '';
      _selectedSystems = {};
      _additionalRooms = [];
      _subcontractors = [];
      _subcontractorLinks = [];

      _totalBuildingWeeks = 32;
      _currentBuildingStage = BuildingStage.przygotowanie;
    }

    _projectNameController = TextEditingController(text: _projectName);
    _addressController = TextEditingController(text: _address);
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMode ? 'Edytuj projekt' : 'Nowy projekt budowy'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // PROGRESS STEPPER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                8,
                (index) => Expanded(
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _jumpToStep(index),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: index <= _currentStep
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index <= _currentStep
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          'Dane',
                          'Harm.',
                          'Podwyk',
                          'Zasil.',
                          'Syst.',
                          'Bud.',
                          'Pom.',
                          'OZE/EV'
                        ][index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // CONTENT
          Expanded(
            child: _buildStepContent(),
          ),
          // BUTTONS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _currentStep--);
                    },
                    child: const Text('Wróć'),
                  ),
                const Spacer(),
                if (_currentStep < 7)
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _currentStep++);
                    },
                    child: const Text('Dalej'),
                  )
                else
                  ElevatedButton(
                    onPressed:
                        widget.editMode ? _confirmEditSave : _createProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                        widget.editMode ? 'Zapisz zmiany' : 'Stwórz projekt'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep5();
      case 2:
        return _buildStepSubcontractors();
      case 3:
        return _buildStep3(); // Zasilanie
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep2(); // Budynki
      case 6:
        return _buildStepAdditionalRooms();
      case 7:
        return _buildStepOZEAndEV();
      default:
        return const SizedBox();
    }
  }

  void _jumpToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex > 7) return;
    setState(() => _currentStep = stepIndex);
  }

  Future<void> _confirmEditSave() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uwaga'),
        content: const Text(
          'W przypadku zapisania zmian niektore dane moga zostac utracone. '
          'Czy chcesz kontynuowac?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      _createProject();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NARZĘDZIA
  // ═══════════════════════════════════════════════════════════════════════════

  String _generateProjectName(BuildContext context) {
    final provider =
        Provider.of<ProjectManagerProvider>(context, listen: false);
    final nextNumber = provider.allProjects.length + 1;
    return 'Projekt #$nextNumber';
  }

  String _getPowerSupplyLabel(PowerSupplyType type) {
    switch (type) {
      case PowerSupplyType.przylaczeNN:
        return 'Przyłącze NN (230/400 V)';
      case PowerSupplyType.przylaczeSNZTrafo:
        return 'Przyłącze SN z trafostacją';
      case PowerSupplyType.wlasnaGeneracja:
        return 'Własna generacja (OZE/agregat)';
    }
  }

  String _getPowerSupplyArchitectureLabel(PowerSupplyArchitectureType type) {
    switch (type) {
      case PowerSupplyArchitectureType.lvDirect:
        return 'Zasilanie nN bezpośrednie - sieć nN -> ZK/ZKP -> WLZ -> RG';
      case PowerSupplyArchitectureType.lvWithMainBoard:
        return 'Zasilanie nN z rozbudowaną rozdzielnią główną - sieć nN -> RGnN -> piony/odpływy';
      case PowerSupplyArchitectureType.mvTransformerSingle:
        return 'Zasilanie SN z jednym transformatorem - SN -> RSn -> transformator -> RGnN';
      case PowerSupplyArchitectureType.mvTransformerMulti:
        return 'Zasilanie SN z wieloma transformatorami - SN -> RSn -> T1 + T2 -> RG sekcjonowana';
      case PowerSupplyArchitectureType.mvWithSwitchgear:
        return 'Zasilanie SN z pełną rozdzielnicą SN - układ wielopolowy';
      case PowerSupplyArchitectureType.mvDualFeed:
        return 'Zasilanie SN dwustronne - dwa niezależne źródła SN + SZR';
    }
  }

  int _totalEstimatedUnits() {
    var totalUnits = 0;
    for (final building in _buildings) {
      for (final stairCase in building.stairCases) {
        totalUnits += stairCase.totalUnits;
      }
    }
    return totalUnits;
  }

  int _totalEstimatedLevels() {
    if (_buildings.isEmpty) {
      return 0;
    }
    return _buildings
        .map((building) => building.totalLevels)
        .reduce((a, b) => a > b ? a : b);
  }

  PowerSupplyType _legacySupplyForArchitecture(
      PowerSupplyArchitectureType type) {
    switch (type) {
      case PowerSupplyArchitectureType.lvDirect:
      case PowerSupplyArchitectureType.lvWithMainBoard:
        return PowerSupplyType.przylaczeNN;
      case PowerSupplyArchitectureType.mvTransformerSingle:
      case PowerSupplyArchitectureType.mvTransformerMulti:
      case PowerSupplyArchitectureType.mvWithSwitchgear:
      case PowerSupplyArchitectureType.mvDualFeed:
        return PowerSupplyType.przylaczeSNZTrafo;
    }
  }

  ConnectionType _legacyConnectionForArchitecture(
      PowerSupplyArchitectureType type) {
    switch (type) {
      case PowerSupplyArchitectureType.lvDirect:
        return ConnectionType.zlaczeDynamiczne;
      case PowerSupplyArchitectureType.lvWithMainBoard:
        return ConnectionType.rozdzielnicaNN;
      case PowerSupplyArchitectureType.mvTransformerSingle:
      case PowerSupplyArchitectureType.mvTransformerMulti:
      case PowerSupplyArchitectureType.mvWithSwitchgear:
      case PowerSupplyArchitectureType.mvDualFeed:
        return ConnectionType.rozdzielnicaSN;
    }
  }

  List<BackupSystemConfig> _buildBackupSystems() {
    final systems = <BackupSystemConfig>[];
    if (_backupCombo) {
      systems.add(
        const BackupSystemConfig(
          type: BackupSystemType.upsGeneratorCombo,
          priority: 1,
          covers: BackupCoverage.full,
          autonomyMinutes: 600,
        ),
      );
    }
    if (_backupUps) {
      systems.add(
        BackupSystemConfig(
          type: BackupSystemType.ups,
          priority: systems.length + 1,
          covers: BackupCoverage.critical,
          autonomyMinutes: 30,
        ),
      );
    }
    if (_backupGenerator) {
      systems.add(
        BackupSystemConfig(
          type: BackupSystemType.generator,
          priority: systems.length + 1,
          covers: BackupCoverage.full,
          autonomyMinutes: 480,
        ),
      );
    }
    return systems;
  }

  List<RenewableSystemConfig> _buildRenewableSystems() {
    if (!_hasPV) {
      return const [];
    }

    return [
      RenewableSystemConfig(
        type: _hasBESS
            ? RenewableSystemType.pvWithStorage
            : RenewableSystemType.pvOnGrid,
        powerKW: _pvPowerKwp,
        integratedWithBackup: _backupUps || _backupGenerator || _backupCombo,
      ),
    ];
  }

  String _getConnectionLabel(ConnectionType type) {
    switch (type) {
      case ConnectionType.zlaczeDynamiczne:
        return 'Złącze kablowo-pomiarowe';
      case ConnectionType.rozdzielnicaSN:
        return 'Rozdzielnica SN';
      case ConnectionType.rozdzielnicaNN:
        return 'Rozdzielnica NN';
    }
  }

  String _getAdditionalRoomInstallationLabel(AdditionalRoomInstallation type) {
    switch (type) {
      case AdditionalRoomInstallation.zasilanie:
        return 'Zasilanie';
      case AdditionalRoomInstallation.oswietlenie:
        return 'Oświetlenie';
      case AdditionalRoomInstallation.teletechnika:
        return 'Teletechnika';
      case AdditionalRoomInstallation.cctv:
        return 'CCTV/Monitoring';
      case AdditionalRoomInstallation.ppoz:
        return 'System ppoż';
      case AdditionalRoomInstallation.ssp:
        return 'SSP/DSO';
      case AdditionalRoomInstallation.wentylacja:
        return 'Wentylacja';
      case AdditionalRoomInstallation.klimatyzacja:
        return 'Klimatyzacja';
      case AdditionalRoomInstallation.oddymianie:
        return 'Oddymianie';
    }
  }

  String _getAdditionalRoomTaskLabel(AdditionalRoomTask task) {
    switch (task) {
      case AdditionalRoomTask.projekt:
        return 'Projekt';
      case AdditionalRoomTask.okablowanie:
        return 'Okablowanie';
      case AdditionalRoomTask.montazOsprzetu:
        return 'Montaż osprzętu';
      case AdditionalRoomTask.pomiary:
        return 'Pomiary';
      case AdditionalRoomTask.uruchomienie:
        return 'Uruchomienie';
      case AdditionalRoomTask.odbior:
        return 'Odbiór';
    }
  }

  String _formatAdditionalRoomLocation(AdditionalRoom room) {
    final buildingName =
        (room.buildingIndex >= 0 && room.buildingIndex < _buildings.length)
            ? _buildings[room.buildingIndex].buildingName
            : 'Budynek ${room.buildingIndex + 1}';
    final levelLabel = room.levelType == AdditionalRoomLevelType.nadziemna
        ? 'Nadziemna'
        : 'Podziemna';
    final stair =
        room.stairCaseName == null ? '' : ' · Klatka ${room.stairCaseName}';
    final number = room.roomNumber.trim().isEmpty
      ? ''
      : ' · Pom. ${room.roomNumber.trim()}';
    return '$buildingName$stair · $levelLabel ${room.floorNumber}$number';
  }

  String _getSubcontractorAreaLabel(SubcontractorArea area) {
    switch (area) {
      case SubcontractorArea.elevators:
        return 'Dźwigi osobowe';
      case SubcontractorArea.garage:
        return 'Garaż';
      case SubcontractorArea.externalArea:
        return 'Teren zewnętrzny';
      case SubcontractorArea.stairCases:
        return 'Klatki schodowe';
      case SubcontractorArea.residentialUnits:
        return 'Lokale mieszkalne';
      case SubcontractorArea.additionalRooms:
        return 'Pomieszczenia dodatkowe';
      case SubcontractorArea.parking:
        return 'Parking';
    }
  }

  String _formatSubcontractorAreas(Set<SubcontractorArea> areas) {
    if (areas.isEmpty) {
      return 'Brak przypisanych obszarów';
    }
    final labels = areas.map(_getSubcontractorAreaLabel).toList()..sort();
    return labels.join(' • ');
  }

  String _buildingTargetId(int buildingIndex) => 'building:$buildingIndex';

  String _stairCaseTargetId({
    required int buildingIndex,
    required String stairCaseName,
  }) =>
      'staircase:$buildingIndex:$stairCaseName';

  String _floorTargetId({
    required int buildingIndex,
    required String stairCaseName,
    required int floor,
  }) =>
      'floor:$buildingIndex:$stairCaseName:$floor';

  String _unitTargetId({
    required int buildingIndex,
    required String stairCaseName,
    required int floor,
    required int unitPosition,
  }) =>
      'unit:$buildingIndex:$stairCaseName:$floor:$unitPosition';

  String _roomTargetId(AdditionalRoom room) => 'room:${room.id}';

  String _systemTargetId(ElectricalSystemType system) =>
      'system:${system.name}';

  String _powerSupplyTargetId() => 'system:powerSupply';

  String _upsTargetId() => 'system:ups';

  String _generatorTargetId() => 'system:generator';

  String _renewableTargetId(String key) => 'renewable:$key';

  String _evTargetId() => 'ev:charging';

  List<
      ({
        String targetId,
        String displayLabel,
        String constructionLabel,
        String targetLabel,
      })> _unitsForFloor({
    required int buildingIndex,
    required StairCaseDetails stairCase,
    required int floor,
  }) {
    final count = stairCase.unitsPerFloor[floor] ?? 2;
    if (count <= 0) {
      return const [];
    }

    final constructionLabels =
        stairCase.getFloorUnitLabels(floor, UnitNamingScheme.construction);
    final targetLabels =
        stairCase.getFloorUnitLabels(floor, UnitNamingScheme.target);

    return List.generate(count, (index) {
      final constructionLabel = index < constructionLabels.length
          ? constructionLabels[index]
          : '${stairCase.stairCaseName}${floor * 100 + index + 1}';
      final targetLabel =
          index < targetLabels.length ? targetLabels[index] : constructionLabel;
      final displayLabel = _defaultUnitNamingScheme == UnitNamingScheme.target
          ? targetLabel
          : constructionLabel;

      return (
        targetId: _unitTargetId(
          buildingIndex: buildingIndex,
          stairCaseName: stairCase.stairCaseName,
          floor: floor,
          unitPosition: index,
        ),
        displayLabel: displayLabel,
        constructionLabel: constructionLabel,
        targetLabel: targetLabel,
      );
    });
  }

  List<SubcontractorAssignment> _assignedSubcontractorsForTarget({
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    final assignedIds = _subcontractorLinks
        .where(
          (link) =>
              !link.blockInheritance &&
              link.targetType == targetType &&
              link.targetId == targetId &&
              link.subcontractorId.isNotEmpty,
        )
        .map((link) => link.subcontractorId)
        .toSet();
    return _subcontractors
        .where((item) => assignedIds.contains(item.id))
        .toList()
      ..sort((a, b) => a.companyName.compareTo(b.companyName));
  }

  bool _isInheritanceBlockedForTarget({
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    return _subcontractorLinks.any(
      (link) =>
          link.blockInheritance &&
          link.targetType == targetType &&
          link.targetId == targetId,
    );
  }

  List<({SubcontractorTargetType targetType, String targetId})>
      _subcontractorTargetFallbackChain({
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    switch (targetType) {
      case SubcontractorTargetType.building:
      case SubcontractorTargetType.additionalRoom:
      case SubcontractorTargetType.system:
      case SubcontractorTargetType.renewable:
      case SubcontractorTargetType.ev:
        return [(targetType: targetType, targetId: targetId)];
      case SubcontractorTargetType.stairCase:
        final parts = targetId.split(':');
        if (parts.length < 3) {
          return [(targetType: targetType, targetId: targetId)];
        }
        final buildingIndex = int.tryParse(parts[1]);
        final stairCaseName = parts[2];
        if (buildingIndex == null) {
          return [(targetType: targetType, targetId: targetId)];
        }
        return [
          (targetType: SubcontractorTargetType.stairCase, targetId: targetId),
          (
            targetType: SubcontractorTargetType.building,
            targetId: _buildingTargetId(buildingIndex),
          ),
        ];
      case SubcontractorTargetType.floor:
        final parts = targetId.split(':');
        if (parts.length < 4) {
          return [(targetType: targetType, targetId: targetId)];
        }
        final buildingIndex = int.tryParse(parts[1]);
        final stairCaseName = parts[2];
        if (buildingIndex == null) {
          return [(targetType: targetType, targetId: targetId)];
        }
        return [
          (targetType: SubcontractorTargetType.floor, targetId: targetId),
          (
            targetType: SubcontractorTargetType.stairCase,
            targetId: _stairCaseTargetId(
              buildingIndex: buildingIndex,
              stairCaseName: stairCaseName,
            ),
          ),
          (
            targetType: SubcontractorTargetType.building,
            targetId: _buildingTargetId(buildingIndex),
          ),
        ];
      case SubcontractorTargetType.unit:
        final parts = targetId.split(':');
        if (parts.length < 5) {
          return [(targetType: targetType, targetId: targetId)];
        }
        final buildingIndex = int.tryParse(parts[1]);
        final stairCaseName = parts[2];
        final floor = int.tryParse(parts[3]);
        if (buildingIndex == null || floor == null) {
          return [(targetType: targetType, targetId: targetId)];
        }
        return [
          (targetType: SubcontractorTargetType.unit, targetId: targetId),
          (
            targetType: SubcontractorTargetType.floor,
            targetId: _floorTargetId(
              buildingIndex: buildingIndex,
              stairCaseName: stairCaseName,
              floor: floor,
            ),
          ),
          (
            targetType: SubcontractorTargetType.stairCase,
            targetId: _stairCaseTargetId(
              buildingIndex: buildingIndex,
              stairCaseName: stairCaseName,
            ),
          ),
          (
            targetType: SubcontractorTargetType.building,
            targetId: _buildingTargetId(buildingIndex),
          ),
        ];
    }
  }

  ({
    List<SubcontractorAssignment> subcontractors,
    bool hasDirectAssignments,
    bool inheritanceBlocked,
    String? inheritedFromLabel,
  }) _resolvedSubcontractorsForTarget({
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    if (_isInheritanceBlockedForTarget(
      targetType: targetType,
      targetId: targetId,
    )) {
      return (
        subcontractors: const <SubcontractorAssignment>[],
        hasDirectAssignments: true,
        inheritanceBlocked: true,
        inheritedFromLabel: null,
      );
    }

    final chain = _subcontractorTargetFallbackChain(
      targetType: targetType,
      targetId: targetId,
    );

    for (final candidate in chain) {
      final assigned = _assignedSubcontractorsForTarget(
        targetType: candidate.targetType,
        targetId: candidate.targetId,
      );
      if (assigned.isEmpty) {
        continue;
      }

      final hasDirectAssignments =
          candidate.targetType == targetType && candidate.targetId == targetId;
      return (
        subcontractors: assigned,
        hasDirectAssignments: hasDirectAssignments,
        inheritanceBlocked: false,
        inheritedFromLabel: hasDirectAssignments
            ? null
            : _resolveSubcontractorTargetLabel(
                SubcontractorLink(
                  subcontractorId: '',
                  targetType: candidate.targetType,
                  targetId: candidate.targetId,
                ),
              ),
      );
    }

    return (
      subcontractors: const <SubcontractorAssignment>[],
      hasDirectAssignments: false,
      inheritanceBlocked: false,
      inheritedFromLabel: null,
    );
  }

  String _resolveSubcontractorTargetLabel(SubcontractorLink link) {
    switch (link.targetType) {
      case SubcontractorTargetType.building:
        final index = int.tryParse(link.targetId.split(':').last);
        if (index == null || index < 0 || index >= _buildings.length) {
          return 'Budynek';
        }
        return _buildings[index].buildingName;
      case SubcontractorTargetType.stairCase:
        final parts = link.targetId.split(':');
        if (parts.length < 3) {
          return 'Klatka';
        }
        final buildingIndex = int.tryParse(parts[1]);
        final stairCaseName = parts[2];
        if (buildingIndex == null ||
            buildingIndex < 0 ||
            buildingIndex >= _buildings.length) {
          return 'Klatka $stairCaseName';
        }
        return '${_buildings[buildingIndex].buildingName} • Klatka $stairCaseName';
      case SubcontractorTargetType.floor:
        final parts = link.targetId.split(':');
        if (parts.length < 4) {
          return 'Piętro';
        }
        final buildingIndex = int.tryParse(parts[1]);
        final stairCaseName = parts[2];
        final floor = int.tryParse(parts[3]);
        if (buildingIndex == null ||
            floor == null ||
            buildingIndex < 0 ||
            buildingIndex >= _buildings.length) {
          return 'Piętro';
        }
        final stairCase = _buildings[buildingIndex].stairCases.where(
              (item) => item.stairCaseName == stairCaseName,
            );
        final floorLabel = stairCase.isEmpty
            ? 'Piętro $floor'
            : stairCase.first.getFloorName(floor);
        return '${_buildings[buildingIndex].buildingName} • Klatka $stairCaseName • $floorLabel';
      case SubcontractorTargetType.unit:
        final parts = link.targetId.split(':');
        if (parts.length < 5) {
          return 'Lokal';
        }

        final buildingIndex = int.tryParse(parts[1]);
        final stairCaseName = parts[2];
        final floor = int.tryParse(parts[3]);
        final unitPosition = int.tryParse(parts[4]);
        if (buildingIndex == null ||
            floor == null ||
            unitPosition == null ||
            buildingIndex < 0 ||
            buildingIndex >= _buildings.length) {
          return 'Lokal';
        }

        final stairCase = _buildings[buildingIndex].stairCases.where(
              (item) => item.stairCaseName == stairCaseName,
            );
        if (stairCase.isEmpty) {
          return 'Lokal';
        }

        final units = _unitsForFloor(
          buildingIndex: buildingIndex,
          stairCase: stairCase.first,
          floor: floor,
        );
        if (unitPosition < 0 || unitPosition >= units.length) {
          return 'Lokal';
        }

        return 'Lokal ${units[unitPosition].displayLabel}';
      case SubcontractorTargetType.additionalRoom:
        final roomId = link.targetId.split(':').last;
        final room = _additionalRooms.where((item) => item.id == roomId);
        return room.isEmpty ? 'Pomieszczenie' : room.first.name;
      case SubcontractorTargetType.system:
        final systemName = link.targetId.split(':').last;
        if (systemName == 'powerSupply') {
          return 'Zasilanie podstawowe';
        }
        if (systemName == 'ups') {
          return 'UPS';
        }
        if (systemName == 'generator') {
          return 'Agregat prądotwórczy';
        }
        final system = ElectricalSystemType.values.where(
          (item) => item.name == systemName,
        );
        return system.isEmpty ? 'System' : _getSystemLabel(system.first);
      case SubcontractorTargetType.renewable:
        final renewableKey = link.targetId.split(':').last;
        switch (renewableKey) {
          case 'pv':
            return 'Fotowoltaika (PV)';
          case 'bess':
            return 'Magazyn energii (BESS)';
          default:
            return 'OZE';
        }
      case SubcontractorTargetType.ev:
        return 'Ładowarki EV';
    }
  }

  List<String> _subcontractorLinkLabels(String subcontractorId) {
    final labels = _subcontractorLinks
        .where(
          (link) =>
              !link.blockInheritance && link.subcontractorId == subcontractorId,
        )
        .map(_resolveSubcontractorTargetLabel)
        .where((label) => label.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return labels;
  }

  List<SubcontractorLink> _sanitizeSubcontractorLinks() {
    final validSubcontractorIds =
        _subcontractors.map((item) => item.id).toSet();
    final validRoomIds = _additionalRooms.map((room) => room.id).toSet();
    final validSystemIds =
        _selectedSystems.map((system) => system.name).toSet();
    validSystemIds.addAll({'powerSupply', 'ups', 'generator'});
    final validBuildingIndexes = List<int>.generate(
      _buildings.length,
      (index) => index,
    ).toSet();
    final validStairCaseIds = <String>{
      for (final buildingEntry in _buildings.asMap().entries)
        for (final stairCase in buildingEntry.value.stairCases)
          _stairCaseTargetId(
            buildingIndex: buildingEntry.key,
            stairCaseName: stairCase.stairCaseName,
          ),
    };
    final validFloorIds = <String>{
      for (final buildingEntry in _buildings.asMap().entries)
        for (final stairCase in buildingEntry.value.stairCases)
          for (var floor = 1; floor <= stairCase.numberOfLevels; floor++)
            _floorTargetId(
              buildingIndex: buildingEntry.key,
              stairCaseName: stairCase.stairCaseName,
              floor: floor,
            ),
    };
    final validUnitIds = <String>{
      for (final buildingEntry in _buildings.asMap().entries)
        for (final stairCase in buildingEntry.value.stairCases)
          for (var floor = 1; floor <= stairCase.numberOfLevels; floor++)
            for (final unit in _unitsForFloor(
              buildingIndex: buildingEntry.key,
              stairCase: stairCase,
              floor: floor,
            ))
              unit.targetId,
    };

    return _subcontractorLinks.where((link) {
      bool isValidTarget;
      switch (link.targetType) {
        case SubcontractorTargetType.building:
          final index = int.tryParse(link.targetId.split(':').last);
          isValidTarget = index != null && validBuildingIndexes.contains(index);
          break;
        case SubcontractorTargetType.stairCase:
          isValidTarget = validStairCaseIds.contains(link.targetId);
          break;
        case SubcontractorTargetType.floor:
          isValidTarget = validFloorIds.contains(link.targetId);
          break;
        case SubcontractorTargetType.unit:
          isValidTarget = validUnitIds.contains(link.targetId);
          break;
        case SubcontractorTargetType.additionalRoom:
          isValidTarget = validRoomIds.contains(link.targetId.split(':').last);
          break;
        case SubcontractorTargetType.system:
          isValidTarget =
              validSystemIds.contains(link.targetId.split(':').last);
          break;
        case SubcontractorTargetType.renewable:
          final key = link.targetId.split(':').last;
          isValidTarget =
              (_hasPV && key == 'pv') || (_hasBESS && key == 'bess');
          break;
        case SubcontractorTargetType.ev:
          isValidTarget = _hasEVCharging;
          break;
      }

      if (!isValidTarget) {
        return false;
      }

      // Blokowanie dziedziczenia: zachowaj link z pustym ID
      if (link.blockInheritance) {
        return link.subcontractorId.isEmpty;
      }

      // Zwykłe przypisanie: sprawdź czy podwykonawca istnieje
      return validSubcontractorIds.contains(link.subcontractorId);
    }).toList();
  }

  Future<void> _openTargetAssignmentDialog({
    required String title,
    required SubcontractorTargetType targetType,
    required String targetId,
  }) async {
    final directAssignments = _assignedSubcontractorsForTarget(
      targetType: targetType,
      targetId: targetId,
    );
    final resolvedAssignments = _resolvedSubcontractorsForTarget(
      targetType: targetType,
      targetId: targetId,
    );
    if (_subcontractors.isEmpty &&
        resolvedAssignments.subcontractors.isEmpty &&
        !resolvedAssignments.inheritanceBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Najpierw dodaj podwykonawcę w zakładce Podwykonawcy.'),
        ),
      );
      return;
    }

    final inheritedIds = resolvedAssignments.hasDirectAssignments
        ? <String>{}
        : resolvedAssignments.subcontractors.map((item) => item.id).toSet();
    var inheritanceBlocked = resolvedAssignments.inheritanceBlocked;
    final selectedIds = (directAssignments.isNotEmpty
            ? directAssignments
            : resolvedAssignments.subcontractors)
        .map((item) => item.id)
        .toSet();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!resolvedAssignments.hasDirectAssignments &&
                          resolvedAssignments.inheritedFromLabel != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            resolvedAssignments.subcontractors.isEmpty
                                ? 'Brak nadrzędnego przypisania.'
                                : 'Aktualnie dziedziczy z: ${resolvedAssignments.inheritedFromLabel}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: inheritanceBlocked,
                        title: const Text('Brak podwykonawcy na tym poziomie'),
                        subtitle: const Text(
                          'Wyłącza dziedziczenie przypisań z poziomu nadrzędnego.',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            inheritanceBlocked = value ?? false;
                            if (inheritanceBlocked) {
                              selectedIds.clear();
                            }
                          });
                        },
                      ),
                      ..._subcontractors.map((subcontractor) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(subcontractor.companyName),
                          subtitle:
                              subcontractor.responsibilities.trim().isEmpty
                                  ? null
                                  : Text(subcontractor.responsibilities),
                          value: selectedIds.contains(subcontractor.id),
                          onChanged: inheritanceBlocked
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedIds.add(subcontractor.id);
                                    } else {
                                      selectedIds.remove(subcontractor.id);
                                    }
                                  });
                                },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) return;

    setState(() {
      _subcontractorLinks.removeWhere(
        (link) => link.targetType == targetType && link.targetId == targetId,
      );

      if (inheritanceBlocked) {
        _subcontractorLinks.add(
          SubcontractorLink(
            subcontractorId: '',
            targetType: targetType,
            targetId: targetId,
            blockInheritance: true,
          ),
        );
        return;
      }

      final shouldPersistDirectLinks = selectedIds.isNotEmpty &&
          !(selectedIds.length == inheritedIds.length &&
              selectedIds.containsAll(inheritedIds) &&
              inheritedIds.containsAll(selectedIds));
      if (shouldPersistDirectLinks) {
        _subcontractorLinks.addAll(
          selectedIds.map(
            (subcontractorId) => SubcontractorLink(
              subcontractorId: subcontractorId,
              targetType: targetType,
              targetId: targetId,
            ),
          ),
        );
      }
    });
  }

  Widget _buildSubcontractorAssignmentField({
    required String label,
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    final resolved = _resolvedSubcontractorsForTarget(
      targetType: targetType,
      targetId: targetId,
    );
    final assigned = resolved.subcontractors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openTargetAssignmentDialog(
                  title: label,
                  targetType: targetType,
                  targetId: targetId,
                ),
                icon: const Icon(Icons.link, size: 16),
                label: Text(assigned.isEmpty ? 'Przypisz' : 'Edytuj'),
              ),
            ],
          ),
          if (resolved.inheritanceBlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Nadpisano: brak podwykonawcy (dziedziczenie wyłączone)',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
              ),
            )
          else if (!resolved.hasDirectAssignments &&
              resolved.inheritedFromLabel != null &&
              assigned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Dziedziczone z: ${resolved.inheritedFromLabel}',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
              ),
            ),
          if (assigned.isEmpty)
            Text(
              resolved.inheritanceBlocked
                  ? 'Brak przypisania (nadpisano dziedziczenie)'
                  : 'Brak przypisanych podwykonawców',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: assigned
                  .map(
                    (item) => Chip(
                      label: Text(item.companyName),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactSubcontractorAssignmentField({
    required String title,
    required String subtitle,
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    final resolved = _resolvedSubcontractorsForTarget(
      targetType: targetType,
      targetId: targetId,
    );
    final assigned = resolved.subcontractors;

    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openTargetAssignmentDialog(
          title: 'Podwykonawcy: $title',
          targetType: targetType,
          targetId: targetId,
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                ),
              ),
              if (resolved.inheritanceBlocked) ...[
                const SizedBox(height: 4),
                Text(
                  'Nadpisano: brak podwykonawcy',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (!resolved.hasDirectAssignments &&
                  resolved.inheritedFromLabel != null &&
                  assigned.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Dziedziczone z: ${resolved.inheritedFromLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (assigned.isEmpty)
                Text(
                  resolved.inheritanceBlocked
                      ? 'Brak przypisania (nadpisano)'
                      : 'Brak przypisania',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                )
              else
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: assigned
                      .map(
                        (item) => Chip(
                          label: Text(item.companyName),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  assigned.isEmpty ? 'Przypisz' : 'Edytuj',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSubcontractors() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Podwykonawcy i zakres prac',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openSubcontractorDialog(),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Dodaj podwykonawcę'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ogólne dane firmy dodajesz tutaj. Przypisania do budynków, pomieszczeń, systemów i OZE/EV ustawisz w kolejnych zakładkach.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          if (_subcontractors.isEmpty)
            Text(
              'Brak dodanych podwykonawców',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ..._subcontractors.map((subcontractor) {
              final hasResponsibilities =
                  subcontractor.responsibilities.trim().isNotEmpty;
              final hasDetails = subcontractor.details.trim().isNotEmpty;
              final linkLabels = _subcontractorLinkLabels(subcontractor.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subcontractor.companyName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openSubcontractorDialog(
                                  existing: subcontractor,
                                );
                              } else if (value == 'delete') {
                                setState(() {
                                  _subcontractors.removeWhere(
                                    (item) => item.id == subcontractor.id,
                                  );
                                  _subcontractorLinks.removeWhere(
                                    (link) =>
                                        link.subcontractorId ==
                                        subcontractor.id,
                                  );
                                });
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edytuj'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Usuń'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSubcontractorAreas(subcontractor.areas),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (hasResponsibilities) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Zakres: ${subcontractor.responsibilities}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      if (hasDetails) ...[
                        const SizedBox(height: 6),
                        Text(
                          subcontractor.details,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        linkLabels.isEmpty
                            ? 'Brak przypisań szczegółowych'
                            : 'Przypisania: ${linkLabels.join(' • ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nazwa projektu (opcjonalnie)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _projectNameController,
            onChanged: (v) => _projectName = v,
            decoration: InputDecoration(
              hintText:
                  'Np. Osiedle Słoneczne — zostanie nadany numer jeśli puste',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Adres budowy (opcjonalnie)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            onChanged: (v) => _address = v,
            decoration: InputDecoration(
              hintText:
                  'Np. ul. Przykładowa 1, Warszawa — można uzupełnić później',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Typ budynku',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButton<BuildingType>(
            value: _buildingType,
            isExpanded: true,
            onChanged: (value) {
              setState(() => _buildingType = value ?? BuildingType.mieszkalny);
            },
            items: BuildingType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text('Data rozpoczęcia budowy',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _projectStartDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2050),
              );
              if (picked != null) {
                setState(() {
                  _projectStartDate = picked;
                  // Jeśli data startu jest późniejsza niż koniec — przesuń koniec
                  if (!_projectEndDate.isAfter(_projectStartDate)) {
                    _projectEndDate =
                        _projectStartDate.add(const Duration(days: 1));
                  }
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_projectStartDate.day}.${_projectStartDate.month}.${_projectStartDate.year}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Data zakończenia budowy',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _projectEndDate,
                firstDate: _projectStartDate,
                lastDate: DateTime(2050),
              );
              if (picked != null) {
                setState(() => _projectEndDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_projectEndDate.day}.${_projectEndDate.month}.${_projectEndDate.year}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            color: Colors.orange.shade400,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 28, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CZAS BUDOWY',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_projectStartDate.day}.${_projectStartDate.month}.${_projectStartDate.year} - ${_projectEndDate.day}.${_projectEndDate.month}.${_projectEndDate.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_projectEndDate.difference(_projectStartDate).inDays}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Text(
                          'DNI BUDOWY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.orange.shade200,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '≈ ${(_projectEndDate.difference(_projectStartDate).inDays / 7).toStringAsFixed(1)} TYGODNI',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ════════════════════════════════════════════════════════════════
          // 1. LICZBA BUDYNKÓW
          // ════════════════════════════════════════════════════════════════
          const Text('1. Liczba budynków',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Slider(
            value: _numberOfBuildings.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: _numberOfBuildings.toString(),
            onChanged: (v) {
              final newCount = v.toInt();
              if (newCount > _buildings.length) {
                // Dodaj nowe budynki
                for (int i = _buildings.length; i < newCount; i++) {
                  _buildings.add(BuildingDetails(
                    buildingName: '${i + 1}',
                    stairCases: [
                      StairCaseDetails(stairCaseName: 'A', numberOfLevels: 3),
                    ],
                  ));
                }
              } else if (newCount < _buildings.length) {
                _buildings.removeRange(newCount, _buildings.length);
              }
              setState(() => _numberOfBuildings = newCount);
            },
          ),
          Text(
              '$_numberOfBuildings ${_numberOfBuildings == 1 ? "budynek" : "budynki"}'),
          const SizedBox(height: 32),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Domyślnie używaj numeracji docelowej'),
            subtitle: const Text(
              'Ta numeracja będzie używana na kartach lokalowych, wykazach i protokołach.',
            ),
            value: _defaultUnitNamingScheme == UnitNamingScheme.target,
            onChanged: (value) {
              setState(() {
                _defaultUnitNamingScheme = value
                    ? UnitNamingScheme.target
                    : UnitNamingScheme.construction;
              });
            },
          ),
          const SizedBox(height: 24),

          // ════════════════════════════════════════════════════════════════
          // 2. KLATKI NA KAŻDYM BUDYNKU
          // ════════════════════════════════════════════════════════════════
          const Text('2. Klatki schodowe na każdym budynku',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._buildings.asMap().entries.map((entry) {
            final buildingIndex = entry.key;
            final building = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            building.buildingName.isEmpty
                                ? 'Budynek ${buildingIndex + 1}'
                                : building.buildingName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final newName = await _showEditNameDialog(
                                context,
                                building.buildingName.isEmpty
                                    ? 'Budynek ${buildingIndex + 1}'
                                    : building.buildingName,
                                'Edytuj nazwę budynku',
                              );
                              if (newName != null && newName.isNotEmpty) {
                                setState(() {
                                  _buildings[buildingIndex] = BuildingDetails(
                                    buildingName: newName,
                                    stairCases: building.stairCases,
                                    basementLevels: building.basementLevels,
                                  );
                                });
                              }
                            },
                            child: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSubcontractorAssignmentField(
                      label: 'Podwykonawcy przypisani do budynku',
                      targetType: SubcontractorTargetType.building,
                      targetId: _buildingTargetId(buildingIndex),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: building.stairCases.length.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: building.stairCases.length.toString(),
                      onChanged: (v) {
                        final newCount = v.toInt();
                        final updatedStairCases =
                            List<StairCaseDetails>.from(building.stairCases);

                        if (newCount > updatedStairCases.length) {
                          for (int i = updatedStairCases.length;
                              i < newCount;
                              i++) {
                            final letter = String.fromCharCode(65 + i);
                            updatedStairCases.add(StairCaseDetails(
                              stairCaseName: letter,
                              numberOfLevels: 3,
                            ));
                          }
                        } else if (newCount < updatedStairCases.length) {
                          updatedStairCases.removeRange(
                              newCount, updatedStairCases.length);
                        }

                        setState(() {
                          _buildings[buildingIndex] = BuildingDetails(
                            buildingName: building.buildingName,
                            stairCases: updatedStairCases,
                            basementLevels: building.basementLevels,
                          );
                        });
                      },
                    ),
                    Text(
                        '${building.stairCases.length} ${building.stairCases.length == 1 ? "klatka" : "klatki"}'),
                    const SizedBox(height: 20),
                    const Divider(thickness: 2, color: Colors.orange),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.stairs, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Piętra i mieszkania w klatkach',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Karty dla każdej klatki
                    ...building.stairCases.asMap().entries.map((stairEntry) {
                      final stairIndex = stairEntry.key;
                      final stairCase = stairEntry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Klatka ${stairCase.stairCaseName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () async {
                                        final newName =
                                            await _showEditNameDialog(
                                          context,
                                          stairCase.stairCaseName,
                                          'Edytuj nazwę klatki',
                                        );
                                        if (newName != null &&
                                            newName.isNotEmpty) {
                                          setState(() {
                                            final updatedStairCases =
                                                List<StairCaseDetails>.from(
                                                    building.stairCases);
                                            updatedStairCases[stairIndex] =
                                                _copyStairCase(
                                              stairCase,
                                              stairCaseName: newName,
                                            );
                                            _buildings[buildingIndex] =
                                                BuildingDetails(
                                              buildingName:
                                                  building.buildingName,
                                              stairCases: updatedStairCases,
                                              basementLevels:
                                                  building.basementLevels,
                                            );
                                          });
                                        }
                                      },
                                      child: const Icon(
                                        Icons.more_vert,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSubcontractorAssignmentField(
                                label:
                                    'Podwykonawcy przypisani do klatki ${stairCase.stairCaseName}',
                                targetType: SubcontractorTargetType.stairCase,
                                targetId: _stairCaseTargetId(
                                  buildingIndex: buildingIndex,
                                  stairCaseName: stairCase.stairCaseName,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '📏 Liczba pięter:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Slider(
                                value: stairCase.numberOfLevels.toDouble(),
                                min: 1,
                                max: 30,
                                divisions: 29,
                                label: stairCase.numberOfLevels.toString(),
                                activeColor: Colors.blue.shade700,
                                onChanged: (v) {
                                  setState(() {
                                    final updatedStairCases =
                                        List<StairCaseDetails>.from(
                                            building.stairCases);
                                    updatedStairCases[stairIndex] =
                                        _copyStairCase(
                                      stairCase,
                                      numberOfLevels: v.toInt(),
                                    );
                                    _buildings[buildingIndex] = BuildingDetails(
                                      buildingName: building.buildingName,
                                      stairCases: updatedStairCases,
                                      basementLevels: building.basementLevels,
                                    );
                                  });
                                },
                              ),
                              Text(
                                '${stairCase.numberOfLevels} pięter',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 16),
                              const Text(
                                '🏠 Mieszkania na każdym piętrze:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Lista pięter z sliderami mieszkań
                              ...List.generate(stairCase.numberOfLevels,
                                  (floorIndex) {
                                final floor = floorIndex + 1;
                                final currentCount =
                                    stairCase.unitsPerFloor[floor] ?? 2;
                                final constructionRange =
                                    stairCase.getFloorUnitRangeLabel(
                                  floor,
                                  UnitNamingScheme.construction,
                                );
                                final targetRange =
                                    stairCase.getFloorUnitRangeLabel(
                                  floor,
                                  UnitNamingScheme.target,
                                );
                                final units = _unitsForFloor(
                                  buildingIndex: buildingIndex,
                                  stairCase: stairCase,
                                  floor: floor,
                                );

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 92,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${stairCase.getFloorName(floor)}:',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () async {
                                                    final details =
                                                        await _showEditFloorDetailsDialog(
                                                      context,
                                                      stairCase: stairCase,
                                                      floor: floor,
                                                      unitCount: currentCount,
                                                    );
                                                    if (details == null) {
                                                      return;
                                                    }

                                                    setState(() {
                                                      final updatedStairCases =
                                                          List<StairCaseDetails>.from(
                                                              building
                                                                  .stairCases);
                                                      final updatedFloorNames =
                                                          Map<int, String>.from(
                                                              stairCase
                                                                  .floorNames);
                                                      final updatedFloorNumbering =
                                                          Map<int,
                                                              FloorUnitNumberingConfig>.from(
                                                        stairCase
                                                            .floorUnitNumbering,
                                                      );
                                                      updatedFloorNames[floor] =
                                                          details.floorName;
                                                      updatedFloorNumbering[
                                                              floor] =
                                                          FloorUnitNumberingConfig(
                                                        constructionStartLabel:
                                                            details
                                                                .constructionStartLabel,
                                                        targetStartLabel: details
                                                            .targetStartLabel,
                                                      );
                                                      updatedStairCases[
                                                              stairIndex] =
                                                          _copyStairCase(
                                                        stairCase,
                                                        floorNames:
                                                            updatedFloorNames,
                                                        floorUnitNumbering:
                                                            updatedFloorNumbering,
                                                      );
                                                      _buildings[
                                                              buildingIndex] =
                                                          BuildingDetails(
                                                        buildingName: building
                                                            .buildingName,
                                                        stairCases:
                                                            updatedStairCases,
                                                        basementLevels: building
                                                            .basementLevels,
                                                      );
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.more_vert,
                                                    size: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Slider(
                                              value: currentCount.toDouble(),
                                              min: 1,
                                              max: 25,
                                              divisions: 24,
                                              label: currentCount.toString(),
                                              activeColor:
                                                  Colors.green.shade600,
                                              onChanged: (v) {
                                                setState(() {
                                                  final updatedStairCases =
                                                      List<StairCaseDetails>.from(
                                                          building.stairCases);
                                                  final updatedUnits =
                                                      Map<int, int>.from(
                                                          stairCase
                                                              .unitsPerFloor);
                                                  updatedUnits[floor] =
                                                      v.toInt();
                                                  updatedStairCases[
                                                          stairIndex] =
                                                      _copyStairCase(
                                                    stairCase,
                                                    unitsPerFloor: updatedUnits,
                                                  );
                                                  _buildings[buildingIndex] =
                                                      BuildingDetails(
                                                    buildingName:
                                                        building.buildingName,
                                                    stairCases:
                                                        updatedStairCases,
                                                    basementLevels:
                                                        building.basementLevels,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            width: 35,
                                            child: Text(
                                              '$currentCount',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, top: 2),
                                        child: Text(
                                          'Budowlana: $constructionRange',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade700),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, top: 1),
                                        child: Text(
                                          'Docelowa: $targetRange',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade700),
                                        ),
                                      ),
                                      _buildSubcontractorAssignmentField(
                                        label:
                                            'Podwykonawcy przypisani do ${stairCase.getFloorName(floor)}',
                                        targetType:
                                            SubcontractorTargetType.floor,
                                        targetId: _floorTargetId(
                                          buildingIndex: buildingIndex,
                                          stairCaseName:
                                              stairCase.stairCaseName,
                                          floor: floor,
                                        ),
                                      ),
                                      if (units.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Card(
                                            margin: EdgeInsets.zero,
                                            color: Colors.white,
                                            child: ExpansionTile(
                                              tilePadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              childrenPadding:
                                                  const EdgeInsets.fromLTRB(
                                                12,
                                                0,
                                                12,
                                                12,
                                              ),
                                              title: Text(
                                                'Przypisania lokali (${units.length})',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              subtitle: const Text(
                                                'Różni podwykonawcy mogą obsługiwać różne mieszkania na tym samym piętrze.',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              children: [
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: units
                                                      .map(
                                                        (unit) =>
                                                            _buildCompactSubcontractorAssignmentField(
                                                          title:
                                                              'Lokal ${unit.displayLabel}',
                                                          subtitle:
                                                              'Budowlana: ${unit.constructionLabel}\nDocelowa: ${unit.targetLabel}',
                                                          targetType:
                                                              SubcontractorTargetType
                                                                  .unit,
                                                          targetId:
                                                              unit.targetId,
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.apartment,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Razem: ${stairCase.totalUnits} mieszkań',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 32),

          // ════════════════════════════════════════════════════════════════
          // 3. GARAŻ I PARKING
          // ════════════════════════════════════════════════════════════════
          const Text('3. Infrastruktura dodatkowa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Parking'),
            value: _hasParking,
            onChanged: (v) {
              setState(() => _hasParking = v ?? false);
            },
          ),
          CheckboxListTile(
            title: const Text('Garaż'),
            value: _hasGarage,
            onChanged: (v) {
              setState(() => _hasGarage = v ?? false);
            },
          ),
          const SizedBox(height: 32),

          // ════════════════════════════════════════════════════════════════
          // 4. PIĘTRA PODZIEMNE (jeśli garaż)
          // ════════════════════════════════════════════════════════════════
          if (_hasGarage) ...[
            const Text('4. Piętra podziemne (do garażu)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._buildings.asMap().entries.map((entry) {
              final buildingIndex = entry.key;
              final building = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                color: Colors.deepOrange.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              building.buildingName.isEmpty
                                  ? 'Budynek ${buildingIndex + 1}'
                                  : building.buildingName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                final newName = await _showEditNameDialog(
                                  context,
                                  building.buildingName.isEmpty
                                      ? 'Budynek ${buildingIndex + 1}'
                                      : building.buildingName,
                                  'Edytuj nazwę budynku',
                                );
                                if (newName != null && newName.isNotEmpty) {
                                  setState(() {
                                    _buildings[buildingIndex] = BuildingDetails(
                                      buildingName: newName,
                                      stairCases: building.stairCases,
                                      basementLevels: building.basementLevels,
                                    );
                                  });
                                }
                              },
                              child: const Icon(
                                Icons.more_vert,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: building.basementLevels.toDouble(),
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: building.basementLevels.toString(),
                        activeColor: Colors.deepOrange,
                        onChanged: (v) {
                          setState(() {
                            _buildings[buildingIndex] = BuildingDetails(
                              buildingName: building.buildingName,
                              stairCases: building.stairCases,
                              basementLevels: v.toInt(),
                            );
                          });
                        },
                      ),
                      Text(
                        '${building.basementLevels} pięter podziemnych',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
          ],

          // ════════════════════════════════════════════════════════════════
          // 5. DŹWIGI W KLATKACH SCHODOWYCH
          // ════════════════════════════════════════════════════════════════
          const Text('5. Dźwigi osobowe w klatkach schodowych',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._buildings.asMap().entries.map((buildingEntry) {
            final buildingIndex = buildingEntry.key;
            final building = buildingEntry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            building.buildingName.isEmpty
                                ? 'Budynek ${buildingIndex + 1}'
                                : building.buildingName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final newName = await _showEditNameDialog(
                                context,
                                building.buildingName.isEmpty
                                    ? 'Budynek ${buildingIndex + 1}'
                                    : building.buildingName,
                                'Edytuj nazwę budynku',
                              );
                              if (newName != null && newName.isNotEmpty) {
                                setState(() {
                                  _buildings[buildingIndex] = BuildingDetails(
                                    buildingName: newName,
                                    stairCases: building.stairCases,
                                    basementLevels: building.basementLevels,
                                  );
                                });
                              }
                            },
                            child: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...building.stairCases.asMap().entries.map((stairEntry) {
                      final stairIndex = stairEntry.key;
                      final stairCase = stairEntry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '🛗 Klatka ${stairCase.stairCaseName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () async {
                                        final newName =
                                            await _showEditNameDialog(
                                          context,
                                          stairCase.stairCaseName,
                                          'Edytuj nazwę klatki',
                                        );
                                        if (newName != null &&
                                            newName.isNotEmpty) {
                                          setState(() {
                                            final updatedStairCases =
                                                List<StairCaseDetails>.from(
                                                    building.stairCases);
                                            updatedStairCases[stairIndex] =
                                                _copyStairCase(
                                              stairCase,
                                              stairCaseName: newName,
                                            );
                                            _buildings[buildingIndex] =
                                                BuildingDetails(
                                              buildingName:
                                                  building.buildingName,
                                              stairCases: updatedStairCases,
                                              basementLevels:
                                                  building.basementLevels,
                                            );
                                          });
                                        }
                                      },
                                      child: const Icon(
                                        Icons.more_vert,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                value: stairCase.numberOfElevators.toDouble(),
                                min: 0,
                                max: 5,
                                divisions: 5,
                                label: stairCase.numberOfElevators.toString(),
                                activeColor: Colors.blue.shade700,
                                onChanged: (v) {
                                  setState(() {
                                    final updatedStairCases =
                                        List<StairCaseDetails>.from(
                                            building.stairCases);
                                    updatedStairCases[stairIndex] =
                                        _copyStairCase(
                                      stairCase,
                                      numberOfElevators: v.toInt(),
                                    );
                                    _buildings[buildingIndex] = BuildingDetails(
                                      buildingName: building.buildingName,
                                      stairCases: updatedStairCases,
                                      basementLevels: building.basementLevels,
                                    );
                                  });
                                },
                              ),
                              Text(
                                '${stairCase.numberOfElevators} ${stairCase.numberOfElevators == 1 ? "dźwig" : "dźwigów"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final needsCustomSupplier = _energySupplier == 'Inny';
    final customSupplierError =
        needsCustomSupplier && _customEnergySupplier.trim().isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zasilanie podstawowe',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Wybierz architekture toru zasilania budynku (model inżynierski).',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ...PowerSupplyArchitectureType.values.map((type) => RadioListTile(
                value: type,
                groupValue: _powerSupplyArchitecture,
                onChanged: (v) {
                  final selected = v ?? _powerSupplyArchitecture;
                  setState(() {
                    _powerSupplyArchitecture = selected;
                    _powerSupply = _legacySupplyForArchitecture(selected);
                    _connectionType =
                        _legacyConnectionForArchitecture(selected);
                  });
                },
                title: Text(_getPowerSupplyArchitectureLabel(type)),
              )),
          const SizedBox(height: 24),
          const Text(
            'Systemy zasilania awaryjnego',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _backupUps,
            onChanged: (value) => setState(() => _backupUps = value ?? false),
            title: const Text('UPS'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _backupGenerator,
            onChanged: (value) =>
                setState(() => _backupGenerator = value ?? false),
            title: const Text('Agregat prądotwórczy'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _backupCombo,
            onChanged: (value) => setState(() => _backupCombo = value ?? false),
            title: const Text('UPS + Agregat prądotwórczy'),
          ),
          const SizedBox(height: 10),
          _buildSubcontractorAssignmentField(
            label: 'Podwykonawca zasilania podstawowego',
            targetType: SubcontractorTargetType.system,
            targetId: _powerSupplyTargetId(),
          ),
          if (_backupUps || _backupCombo)
            _buildSubcontractorAssignmentField(
              label: 'Podwykonawca UPS',
              targetType: SubcontractorTargetType.system,
              targetId: _upsTargetId(),
            ),
          if (_backupGenerator || _backupCombo)
            _buildSubcontractorAssignmentField(
              label: 'Podwykonawca agregatu prądotwórczego',
              targetType: SubcontractorTargetType.system,
              targetId: _generatorTargetId(),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _offGridMode,
            onChanged: (value) => setState(() => _offGridMode = value),
            title: const Text('Tryb off-grid'),
            subtitle: const Text(
                'Włącz tylko dla układów bez przyłącza do sieci publicznej.'),
          ),
          const SizedBox(height: 24),
          const Text('Dostawca energii',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _energySupplier,
            items: _energySuppliers
                .map((supplier) => DropdownMenuItem(
                      value: supplier,
                      child: Text(supplier),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _energySupplier = value;
                if (value != 'Inny') {
                  _customEnergySupplier = '';
                }
              });
            },
            decoration: _inputDecoration(
              helperText: 'Wybierz dostawcę lub opcję "Inny"',
            ),
          ),
          if (needsCustomSupplier) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _customEnergySupplier,
              decoration: _inputDecoration(
                labelText: 'Podaj nazwę dostawcy',
                helperText: 'Wpisz pełną nazwę dostawcy energii',
                errorText:
                    customSupplierError ? 'Uzupełnij nazwę dostawcy' : null,
              ),
              onChanged: (value) {
                setState(() => _customEnergySupplier = value);
              },
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Profil techniczny: ${_getPowerSupplyLabel(_powerSupply)} | ${_getConnectionLabel(_connectionType)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStepAdditionalRooms() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pomieszczenia dodatkowe',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: () => _openAdditionalRoomDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj pomieszczenie'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_additionalRooms.isEmpty)
            Text(
              'Brak dodanych pomieszczeń',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ..._additionalRooms.map((room) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatAdditionalRoomLocation(room),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openAdditionalRoomDialog(existing: room);
                              } else if (value == 'delete') {
                                setState(() {
                                  _additionalRooms
                                      .removeWhere((r) => r.id == room.id);
                                  _subcontractorLinks.removeWhere(
                                    (link) =>
                                        link.targetType ==
                                            SubcontractorTargetType
                                                .additionalRoom &&
                                        link.targetId == _roomTargetId(room),
                                  );
                                });
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edytuj'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Usuń'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSubcontractorAssignmentField(
                        label: 'Podwykonawcy przypisani do pomieszczenia',
                        targetType: SubcontractorTargetType.additionalRoom,
                        targetId: _roomTargetId(room),
                      ),
                      if (room.specificSystems.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: room.specificSystems
                              .map(
                                (system) => Chip(
                                  label: Text(system.displayName),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openAdditionalRoomDialog({AdditionalRoom? existing}) async {
    final room = await _showAdditionalRoomDialog(existing: existing);
    if (room == null) return;

    setState(() {
      final index = _additionalRooms.indexWhere((r) => r.id == room.id);
      if (index == -1) {
        _additionalRooms.add(room);
      } else {
        _additionalRooms[index] = room;
      }
    });
  }

  Future<AdditionalRoom?> _showAdditionalRoomDialog(
      {AdditionalRoom? existing}) async {
    final isEdit = existing != null;
    String selectedType = existing?.name ?? _additionalRoomTypes.first;
    String customName = '';
    if (!_additionalRoomTypes.contains(selectedType)) {
      selectedType = 'Inne';
      customName = existing?.name ?? '';
    }

    int buildingIndex = existing?.buildingIndex ?? 0;
    String? stairCaseName = existing?.stairCaseName;
    String roomNumber = existing?.roomNumber ?? '';
    AdditionalRoomLevelType levelType =
        existing?.levelType ?? AdditionalRoomLevelType.nadziemna;
    int floorNumber = existing?.floorNumber ?? 0;
    Set<ElectricalSystemType> selectedSystems =
      Set<ElectricalSystemType>.from(existing?.specificSystems ?? {});

    return showDialog<AdditionalRoom>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final building = _buildings.isNotEmpty &&
                    buildingIndex >= 0 &&
                    buildingIndex < _buildings.length
                ? _buildings[buildingIndex]
                : null;
            final stairCases = building?.stairCases ?? [];
            final stairCaseOptions = <String?>[
              null,
              ...stairCases.map((s) => s.stairCaseName)
            ];

            if (!stairCaseOptions.contains(stairCaseName)) {
              stairCaseName = null;
            }

            final customNameError =
                selectedType == 'Inne' && customName.trim().isEmpty;

            return AlertDialog(
              title:
                  Text(isEdit ? 'Edytuj pomieszczenie' : 'Dodaj pomieszczenie'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rodzaj pomieszczenia'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        items: _additionalRoomTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedType = value);
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      if (selectedType == 'Inne') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: customName,
                          decoration: _inputDecoration(
                            labelText: 'Nazwa pomieszczenia',
                            helperText: 'Podaj unikalną nazwę',
                            errorText:
                                customNameError ? 'Uzupełnij nazwę' : null,
                          ),
                          onChanged: (value) {
                            setDialogState(() => customName = value);
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text('Lokalizacja'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: buildingIndex,
                        items: List.generate(
                          _buildings.length,
                          (index) => DropdownMenuItem(
                            value: index,
                            child: Text(_buildings[index].buildingName),
                          ),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            buildingIndex = value;
                            stairCaseName = null;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: stairCaseName,
                        items: stairCaseOptions
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value == null
                                      ? 'Brak klatki'
                                      : 'Klatka $value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => stairCaseName = value);
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Nadziemna'),
                            selected:
                                levelType == AdditionalRoomLevelType.nadziemna,
                            onSelected: (_) {
                              setDialogState(() {
                                levelType = AdditionalRoomLevelType.nadziemna;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Podziemna'),
                            selected:
                                levelType == AdditionalRoomLevelType.podziemna,
                            onSelected: (_) {
                              setDialogState(() {
                                levelType = AdditionalRoomLevelType.podziemna;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: floorNumber.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Numer piętra',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value.trim());
                          if (parsed != null) {
                            setDialogState(() => floorNumber = parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: roomNumber,
                        decoration: const InputDecoration(
                          labelText: 'Numer pomieszczenia',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setDialogState(() => roomNumber = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Systemy (z zakładki Systemy)'),
                      const SizedBox(height: 6),
                      if (_selectedSystems.isEmpty)
                        Text(
                          'Brak systemów w projekcie. Najpierw wybierz je w zakładce Systemy.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        ...(_selectedSystems.toList()
                              ..sort((a, b) =>
                                  a.displayName.compareTo(b.displayName)))
                            .map(
                              (system) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: selectedSystems.contains(system),
                                title: Text(system.displayName),
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedSystems.add(system);
                                    } else {
                                      selectedSystems.remove(system);
                                    }
                                  });
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = selectedType == 'Inne'
                        ? customName.trim()
                        : selectedType.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    final id = existing?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString();
                    Navigator.of(dialogContext).pop(
                      AdditionalRoom(
                        id: id,
                        name: name,
                        roomNumber: roomNumber.trim(),
                        buildingIndex: buildingIndex,
                        stairCaseName: stairCaseName,
                        levelType: levelType,
                        floorNumber: floorNumber,
                        installations: existing?.installations ?? const {},
                        specificSystems: selectedSystems,
                        tasks: existing?.tasks ?? const {},
                        completedTasks: existing?.completedTasks ?? const {},
                      ),
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openSubcontractorDialog({
    SubcontractorAssignment? existing,
  }) async {
    final subcontractor = await _showSubcontractorDialog(existing: existing);
    if (subcontractor == null) {
      return;
    }

    setState(() {
      final index =
          _subcontractors.indexWhere((item) => item.id == subcontractor.id);
      if (index == -1) {
        _subcontractors.add(subcontractor);
      } else {
        _subcontractors[index] = subcontractor;
      }
    });
  }

  Future<SubcontractorAssignment?> _showSubcontractorDialog({
    SubcontractorAssignment? existing,
  }) async {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.companyName);
    final responsibilitiesController = TextEditingController(
      text: existing?.responsibilities,
    );
    final detailsController = TextEditingController(text: existing?.details);
    final selectedAreas =
        Set<SubcontractorArea>.from(existing?.areas ?? const {});

    final result = await showDialog<SubcontractorAssignment>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasName = nameController.text.trim().isNotEmpty;

            return AlertDialog(
              title: Text(
                isEdit ? 'Edytuj podwykonawcę' : 'Dodaj podwykonawcę',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Nazwa podwykonawcy',
                          border: const OutlineInputBorder(),
                          errorText: hasName ? null : 'Uzupełnij nazwę firmy',
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: responsibilitiesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Zakres prac',
                          hintText: 'Np. teletechnika, elektryka, CCTV',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Szczegóły / notatki',
                          hintText:
                              'Np. odpowiedzialność, terminy, ustalenia wykonawcze',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Obszary ogólne odpowiedzialności (opcjonalnie)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      ...SubcontractorArea.values.map((area) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_getSubcontractorAreaLabel(area)),
                          value: selectedAreas.contains(area),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedAreas.add(area);
                              } else {
                                selectedAreas.remove(area);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final companyName = nameController.text.trim();
                    if (companyName.isEmpty) {
                      setDialogState(() {});
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      SubcontractorAssignment(
                        id: existing?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        companyName: companyName,
                        areas: selectedAreas,
                        responsibilities:
                            responsibilitiesController.text.trim(),
                        details: detailsController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    responsibilitiesController.dispose();
    detailsController.dispose();
    return result;
  }

  Widget _buildStep4() {
    final isOffice = _buildingType == BuildingType.biurowy;
    final isResidential = _buildingType == BuildingType.mieszkalny;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wybierz systemy elektryczne i teletechniczne',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Systemy są dostosowane do typu budynku: ${_buildingType == BuildingType.mieszkalny ? "Mieszkalny" : "Biurowy"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '🔌 1. Instalacje elektryczne podstawowe',
            common: const [
              _SystemOption(
                  ElectricalSystemType.oswietlenie,
                  'Instalacja oświetlenia podstawowego'),
              _SystemOption(
                  ElectricalSystemType.oswietlenieAwaryjneEwakuacyjne,
                  'Instalacja oświetlenia awaryjnego i ewakuacyjnego'),
              _SystemOption(ElectricalSystemType.zasilanie,
                  'Instalacja zasilania ogólnego (gniazda i odbiory)'),
              _SystemOption(ElectricalSystemType.wlz,
                  'Wewnętrzne linie zasilające (WLZ)'),
              _SystemOption(ElectricalSystemType.rozdzielniceRgRnnRsn,
                  'Rozdzielnice elektryczne (RG, RNN, RSN)'),
              _SystemOption(ElectricalSystemType.uziemieniePolaczeniaWyrownawcze,
                  'System uziemienia i połączeń wyrównawczych'),
              _SystemOption(
                  ElectricalSystemType.odgromowa, 'Instalacja odgromowa (LPS)'),
              _SystemOption(ElectricalSystemType.trasyKablowe,
                  'Trasy kablowe (koryta, drabiny, kanały)'),
            ],
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '⚡ 2. Systemy zasilania i energetyki',
            common: const [
              _SystemOption(ElectricalSystemType.gniazdaDedykowane,
                  'Zasilanie podstawowe (nN / SN / transformator)'),
              _SystemOption(ElectricalSystemType.panelePV,
                  'Instalacja fotowoltaiczna (PV)'),
            ],
            office: const [
              _SystemOption(ElectricalSystemType.ups,
                  'Zasilanie gwarantowane (UPS) ❗'),
              _SystemOption(
                  ElectricalSystemType.agregat, 'Agregat prądotwórczy'),
              _SystemOption(ElectricalSystemType.szr,
                  'Układy SZR (samoczynne załączenie rezerwy)'),
              _SystemOption(ElectricalSystemType.magazynEnergii,
                  'Magazyn energii (BESS)'),
              _SystemOption(ElectricalSystemType.dualFeedSn,
                  'Zasilanie dwustronne (dual feed SN)'),
            ],
            residential: const [
              _SystemOption(ElectricalSystemType.agregat,
                  'Agregat prądotwórczy – części wspólne'),
              _SystemOption(ElectricalSystemType.magazynEnergii, 'Magazyn energii'),
            ],
            showOffice: isOffice,
            showResidential: isResidential,
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '📊 3. Systemy pomiarowe i zarządzania energią',
            common: const [
              _SystemOption(ElectricalSystemType.ukladyPomiarowe,
                  'Układy pomiaru energii (liczniki główne i podliczniki)'),
            ],
            office: const [
              _SystemOption(ElectricalSystemType.ems,
                  'System zarządzania energią (EMS)'),
              _SystemOption(ElectricalSystemType.analizatorySieci,
                  'Analizatory jakości energii'),
            ],
            residential: const [
              _SystemOption(ElectricalSystemType.podlicznikiEnergii,
                  'Indywidualne liczniki mieszkań'),
            ],
            showOffice: isOffice,
            showResidential: isResidential,
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '🚨 4. Systemy bezpieczeństwa i ochrony',
            common: const [
              _SystemOption(ElectricalSystemType.ppoz,
                  'System sygnalizacji pożaru (SSP)'),
              _SystemOption(ElectricalSystemType.dso,
                  'Dźwiękowy system ostrzegawczy (DSO)'),
              _SystemOption(
                  ElectricalSystemType.cctv, 'System telewizji dozorowej (CCTV)'),
              _SystemOption(
                  ElectricalSystemType.kd, 'System kontroli dostępu (KD)'),
              _SystemOption(ElectricalSystemType.sswim,
                  'System sygnalizacji włamania i napadu (SSWiN)'),
              _SystemOption(ElectricalSystemType.gaszeniGazem,
                  'Stałe urządzenia gaśnicze (np. gaszenie gazem – wybrane strefy)'),
              _SystemOption(ElectricalSystemType.wykrywaniWyciekow,
                  'System detekcji wycieków (woda, gaz)'),
            ],
            office: const [
              _SystemOption(ElectricalSystemType.psimSms,
                  'System integracji bezpieczeństwa (PSIM / SMS)'),
              _SystemOption(ElectricalSystemType.integracjaSystemow,
                  'Systemy ewakuacji sterowane (integracja SSP + BMS)'),
            ],
            residential: const [
              _SystemOption(ElectricalSystemType.cctv,
                  'Monitoring części wspólnych'),
              _SystemOption(ElectricalSystemType.czujnikiRuchu,
                'System przyzywowy (np. dla osób niepełnosprawnych)'),
            ],
            showOffice: isOffice,
            showResidential: isResidential,
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '📡 5. Systemy teletechniczne i komunikacyjne',
            common: const [
              _SystemOption(
                  ElectricalSystemType.lan, 'Okablowanie strukturalne LAN'),
              _SystemOption(ElectricalSystemType.swiatlowod,
                'Instalacja światłowodowa'),
            ],
            office: const [
              _SystemOption(
                  ElectricalSystemType.wifi, 'Sieci Wi-Fi (systemowe)'),
              _SystemOption(
                  ElectricalSystemType.voip, 'System telefonii VoIP'),
              _SystemOption(
                  ElectricalSystemType.dataRoom, 'Serwerownie / Data Room'),
              _SystemOption(ElectricalSystemType.av,
                  'Systemy AV'),
              _SystemOption(
                  ElectricalSystemType.digitalSignage, 'Digital Signage'),
            ],
            residential: const [
              _SystemOption(ElectricalSystemType.telewizja,
                  'Instalacja RTV/SAT (MATV/SMATV)'),
              _SystemOption(ElectricalSystemType.domofonowa,
                  'Instalacja domofonowa / wideodomofonowa'),
            ],
            showOffice: isOffice,
            showResidential: isResidential,
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '🌬️ 6. Systemy HVAC i automatyki',
            common: const [
              _SystemOption(ElectricalSystemType.wentylacja, 'System wentylacji'),
              _SystemOption(ElectricalSystemType.oddymianieKlatek,
                  'System oddymiania klatek schodowych'),
            ],
            office: const [
              _SystemOption(
                  ElectricalSystemType.klimatyzacja, 'System klimatyzacji (HVAC)'),
              _SystemOption(ElectricalSystemType.bms,
                  'System zarządzania budynkiem (BMS) ❗'),
              _SystemOption(ElectricalSystemType.automatykaHvac,
                  'Automatyka HVAC (sterowanie centralami, VAV, VRF itd.)'),
            ],
            residential: const [
              _SystemOption(ElectricalSystemType.wentylacja,
                'Wentylacja mechaniczna'),
              _SystemOption(ElectricalSystemType.klimatyzacja,
                'Centralna klimatyzacja'),
            ],
            showOffice: isOffice,
            showResidential: isResidential,
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '🚗 7. Transport i infrastruktura techniczna',
            common: const [
              _SystemOption(
                  ElectricalSystemType.windaAscensor, 'Dźwigi osobowe / windy'),
              _SystemOption(ElectricalSystemType.ladownarki,
                  'Stacje ładowania pojazdów elektrycznych (EV)'),
              _SystemOption(ElectricalSystemType.podgrzewanePodjazdy,
                  'Systemy podgrzewania podjazdów i ramp'),
              _SystemOption(ElectricalSystemType.ogrzewanieRur,
                  'Systemy przeciwzamrożeniowe (ogrzewanie rur)'),
            ],
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '🧠 8. Systemy inteligentne i integracja',
            office: const [
              _SystemOption(ElectricalSystemType.bms,
                  'System zarządzania budynkiem (BMS – nadrzędny)'),
              _SystemOption(ElectricalSystemType.integracjaSystemow,
                  'Integracja systemów (HVAC, SSP, CCTV, KD itd.)'),
            ],
            residential: const [
              _SystemOption(ElectricalSystemType.smartHome,
                  'System Smart Home (automatyka mieszkaniowa)'),
            ],
            showOffice: isOffice,
            showResidential: isResidential,
          ),
          const SizedBox(height: 16),

          _buildSystemCategory(
            '🏢 9. Elementy specyficzne funkcjonalnie',
            office: const [
              _SystemOption(ElectricalSystemType.floorboxy,
                  'Podłogi techniczne (floorboxy, puszki podłogowe)'),
              _SystemOption(ElectricalSystemType.zasilanieStanowiskPracy,
                  'Zasilanie stanowisk pracy (open space)'),
              _SystemOption(
                  ElectricalSystemType.rezerwacjaSal, 'Systemy rezerwacji sal'),
            ],
            residential: const [
              _SystemOption(ElectricalSystemType.rozdzielniceRgRnnRsn,
                  'Rozdzielnice mieszkaniowe'),
              _SystemOption(ElectricalSystemType.gniazdaDedykowane,
                'Instalacje dla lokali usługowych'),
            ],
            showOffice: isOffice,
            showResidential: isResidential,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCategory(
    String title, {
    List<_SystemOption> common = const [],
    List<_SystemOption> office = const [],
    List<_SystemOption> residential = const [],
    bool showOffice = false,
    bool showResidential = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        if (common.isNotEmpty) ...[
          ...common.map(_buildSystemOptionTile),
        ],
        if (showOffice && office.isNotEmpty) ...[
          if (common.isNotEmpty) const SizedBox(height: 8),
          ...office.map(_buildSystemOptionTile),
        ],
        if (showResidential && residential.isNotEmpty) ...[
          if (common.isNotEmpty || (showOffice && office.isNotEmpty))
            const SizedBox(height: 8),
          ...residential.map(_buildSystemOptionTile),
        ],
      ],
    );
  }

  Widget _buildSystemOptionTile(_SystemOption option) {
    final isSelected = _selectedSystems.contains(option.system);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          title: Text(option.label),
          value: isSelected,
          onChanged: (v) {
            setState(() {
              if (v ?? false) {
                _selectedSystems.add(option.system);
              } else {
                _selectedSystems.remove(option.system);
              }
            });
          },
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: _buildSubcontractorAssignmentField(
              label: 'Podwykonawcy przypisani do systemu',
              targetType: SubcontractorTargetType.system,
              targetId: _systemTargetId(option.system),
            ),
          ),
      ],
    );
  }

  Widget _buildStep5() {
    // Oblicz przewidywany czas budowy na podstawie konfiguracji
    final totalLevels = _buildings.fold(
      0,
      (sum, building) =>
          sum +
          building.stairCases.fold(
            0,
            (sumLevels, stairCase) => sumLevels > stairCase.numberOfLevels
                ? sumLevels
                : stairCase.numberOfLevels,
          ),
    );

    final basementLevels = _hasGarage ? 1 : 0;

    final predictedWeeks = ConstructionScheduleDatabase.calculateTotalWeeks(
      totalLevels,
      basementLevels,
      _buildingType,
    );

    // Pobierz szczegółowe dane harmonogramu
    final scheduleData = _buildingType == BuildingType.mieszkalny
        ? ConstructionScheduleDatabase.residentialStages
        : ConstructionScheduleDatabase.commercialStages;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sekcja: przewidywany czas
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⏱️ Przewidywany czas budowy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$predictedWeeks tygodni (${(predictedWeeks / 4.33).toStringAsFixed(1)} miesięcy)',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dla budynku ${_buildingType == BuildingType.mieszkalny ? "mieszkalnego" : "biurowego"} '
                    'o $totalLevels kondygnacjach${basementLevels > 0 ? " + $basementLevels poziom garaży" : ""}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sekcja: szczegółowy harmonogram etapów
          const Text(
            '📋 Szczegółowy harmonogram etapów',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bazując na danych dla budynków 5-8 kondygnacyjnych',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ...scheduleData.entries.map((entry) {
            final stage = entry.key;
            final stageData = entry.value;
            final stageEnum = ScheduleDataIntegration.stageMapping[stage];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _currentBuildingStage == stageEnum
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${BuildingStage.values.indexOf(stageEnum!) + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _currentBuildingStage == stageEnum
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  _getStageTitle(stageEnum),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _currentBuildingStage == stageEnum
                        ? Colors.green.shade700
                        : Colors.black,
                  ),
                ),
                subtitle: Text(
                  '${stageData.weekRange.$1}-${stageData.weekRange.$2} tyg. • ${stageData.tasks.length} zadań',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Radio<BuildingStage>(
                  value: stageEnum,
                  groupValue: _currentBuildingStage,
                  onChanged: (value) {
                    setState(() {
                      _currentBuildingStage =
                          value ?? BuildingStage.przygotowanie;
                    });
                  },
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStageDescription(stageEnum),
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Główne prace:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...stageData.tasks.take(5).map((task) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(fontSize: 12)),
                                  Expanded(
                                    child: Text(
                                      task,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (stageData.tasks.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text(
                              '... i ${stageData.tasks.length - 5} więcej',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Informacja o modyfikatorach
          if (basementLevels > 0)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Garaż podziemny dodaje ${basementLevels == 1 ? "1-2 miesiące" : "3-5 miesięcy"} do czasu budowy',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  StairCaseDetails _copyStairCase(
    StairCaseDetails stairCase, {
    String? stairCaseName,
    int? numberOfLevels,
    Map<int, int>? unitsPerFloor,
    int? numberOfElevators,
    Map<int, String>? floorNames,
    Map<int, FloorUnitNumberingConfig>? floorUnitNumbering,
  }) {
    return StairCaseDetails(
      stairCaseName: stairCaseName ?? stairCase.stairCaseName,
      numberOfLevels: numberOfLevels ?? stairCase.numberOfLevels,
      unitsPerFloor: unitsPerFloor ?? stairCase.unitsPerFloor,
      numberOfElevators: numberOfElevators ?? stairCase.numberOfElevators,
      floorNames: floorNames ?? stairCase.floorNames,
      floorUnitNumbering: floorUnitNumbering ?? stairCase.floorUnitNumbering,
    );
  }

  Future<
      ({
        String floorName,
        String constructionStartLabel,
        String targetStartLabel,
      })?> _showEditFloorDetailsDialog(
    BuildContext context, {
    required StairCaseDetails stairCase,
    required int floor,
    required int unitCount,
  }) async {
    final numbering = stairCase.getFloorUnitNumbering(floor);
    final floorNameController = TextEditingController(
      text: stairCase.getFloorName(floor),
    );
    final constructionController = TextEditingController(
      text: numbering.constructionStartLabel,
    );
    final targetController = TextEditingController(
      text: numbering.targetStartLabel,
    );

    ({
      String floorName,
      String constructionStartLabel,
      String targetStartLabel
    })? result;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewConfig = FloorUnitNumberingConfig(
              constructionStartLabel: constructionController.text.trim(),
              targetStartLabel: targetController.text.trim(),
            );

            return AlertDialog(
              title:
                  Text('Konfiguracja piętra ${stairCase.getFloorName(floor)}'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: floorNameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Nazwa piętra',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: constructionController,
                        decoration: const InputDecoration(
                          labelText: 'Pierwszy numer budowlany',
                          hintText: 'np. A.007',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zakres budowlany dla $unitCount lokali: ${previewConfig.rangeLabel(unitCount, UnitNamingScheme.construction)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: targetController,
                        decoration: const InputDecoration(
                          labelText: 'Pierwszy numer docelowy',
                          hintText: 'np. M.201',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zakres docelowy dla $unitCount lokali: ${previewConfig.rangeLabel(unitCount, UnitNamingScheme.target)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final floorName = floorNameController.text.trim();
                    final constructionStartLabel =
                        constructionController.text.trim();
                    final targetStartLabel = targetController.text.trim();
                    if (floorName.isEmpty ||
                        constructionStartLabel.isEmpty ||
                        targetStartLabel.isEmpty) {
                      return;
                    }

                    result = (
                      floorName: floorName,
                      constructionStartLabel: constructionStartLabel,
                      targetStartLabel: targetStartLabel,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    floorNameController.dispose();
    constructionController.dispose();
    targetController.dispose();
    return result;
  }

  Future<String?> _showEditNameDialog(
      BuildContext context, String currentName, String title) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nowa nazwa',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  String _getSystemLabel(ElectricalSystemType system) {
    return system.displayName;
  }

  String _getStageTitle(BuildingStage stage) {
    switch (stage) {
      case BuildingStage.przygotowanie:
        return '📋 Przygotowanie';
      case BuildingStage.fundamenty:
        return '🏗️ Fundamenty';
      case BuildingStage.konstrukcja:
        return '🏢 Konstrukcja';
      case BuildingStage.przegrody:
        return '🧱 Przegrody';
      case BuildingStage.tynki:
        return '🪨 Tynki';
      case BuildingStage.posadzki:
        return '🔨 Posadzki';
      case BuildingStage.osprzet:
        return '⚡ Osprzęt elektryczny';
      case BuildingStage.malowanie:
        return '🎨 Malowanie';
      case BuildingStage.finalizacja:
        return '✅ Finalizacja';
      case BuildingStage.oddawanie:
        return '📋 Oddawanie do użytku';
      case BuildingStage.ozeInstalacje:
        return '☀️ Instalacje OZE';
      case BuildingStage.evInfrastruktura:
        return '🔌 Infrastruktura EV';
    }
  }

  String _getStageDescription(BuildingStage stage) {
    switch (stage) {
      case BuildingStage.przygotowanie:
        return 'Projekty, harmonogram, zamówienia materiałów i urządzeń';
      case BuildingStage.fundamenty:
        return 'Fundamenty, dreny, przygotowanie gruntu';
      case BuildingStage.konstrukcja:
        return 'Szkielety, stropy, słupy, drogi dojazdowe';
      case BuildingStage.przegrody:
        return 'Ścianki działowe, przechody rur i przewodów';
      case BuildingStage.tynki:
        return 'Tynki zewnętrzne i wewnętrzne';
      case BuildingStage.posadzki:
        return 'Posadzki, wylewki, preparacja';
      case BuildingStage.osprzet:
        return 'Osprzęt elektryczny, oprawy, rozliczenia';
      case BuildingStage.malowanie:
        return 'Malowanie, lakierowanie, prace wykończeniowe';
      case BuildingStage.finalizacja:
        return 'Drzwi, meblościany, ostatnie detale';
      case BuildingStage.oddawanie:
        return 'Pomiary, dokumentacja, odbiór i przygotowanie do użytkowania';
      case BuildingStage.ozeInstalacje:
        return 'Instalacje fotowoltaiczne, magazyny energii i systemy OZE';
      case BuildingStage.evInfrastruktura:
        return 'Ładowarki pojazdów elektrycznych i system zarządzania mocą (DLM)';
    }
  }

  InputDecoration _inputDecoration({
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  void _createProject() async {
    // Walidacja
    final errors = <String>[];
    final tips = <String>[];

    if (_selectedSystems.isEmpty) {
      errors.add('Nie wybrano żadnych systemów');
      tips.add('Wróć do kroku: Systemy');
    }

    if (_energySupplier == 'Inny' && _customEnergySupplier.trim().isEmpty) {
      errors.add('Nie podano nazwy dostawcy energii');
      tips.add('Wróć do kroku: Dostawca energii');
    }

    if (errors.isNotEmpty) {
      print('[Wizard] Błędy walidacji: $errors');
      final guidance = tips.isEmpty ? '' : '\n\nCo dalej:\n${tips.join('\n')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Uzupełnij brakujące pola:\n${errors.join('\n')}$guidance'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final backupSystems = _buildBackupSystems();
    final renewableSystems = _buildRenewableSystems();

    // Generuj nazwę sekwencyjną jeśli pusta
    if (_projectName.isEmpty) {
      _projectName = _generateProjectName(context);
      _projectNameController.text = _projectName;
    }
    // Adres pozostaje pusty jeśli nie podano

    // Oblicz całkowity czas budowy w tygodniach
    final totalDays = _projectEndDate.difference(_projectStartDate).inDays;
    _totalBuildingWeeks = (totalDays / 7).ceil();

    // Oblicz całkowite mieszkania z hierarchicznej struktury
    int totalUnits = 0;
    int totalElevators = 0;
    for (final building in _buildings) {
      for (final stairCase in building.stairCases) {
        totalUnits += stairCase.totalUnits;
        totalElevators += stairCase.numberOfElevators;
      }
    }

    print('[Wizard] Walidacja OK, tworzenie konfiguracji...');
    print('[Wizard] - Nazwa: $_projectName');
    print('[Wizard] - Adres: $_address');
    print('[Wizard] - Systemy: ${_selectedSystems.length}');
    print('[Wizard] - Budynków: $_numberOfBuildings');
    print('[Wizard] - Dźwigów: $totalElevators');
    print('[Wizard] - Całkowicie mieszkań: $totalUnits');
    print('[Wizard] - Czas budowy: $_totalBuildingWeeks tygodni');
    print('[Wizard] - Aktualny etap: ${_getStageTitle(_currentBuildingStage)}');

    final config = BuildingConfiguration(
      projectName: _projectName,
      buildingType: _buildingType,
      address: _address,
      projectStartDate: _projectStartDate,
      projectEndDate: _projectEndDate,
      numberOfBuildings: _numberOfBuildings,
      hasParking: _hasParking,
      hasGarage: _hasGarage,
      buildings: _buildings,
      powerSupplyType: _powerSupply,
      connectionType: _connectionType,
      powerSupplyArchitecture: _powerSupplyArchitecture,
      backupSystems: backupSystems,
      renewableSystems: renewableSystems,
      offGridMode: _offGridMode,
      energySupplier: _energySupplier == 'Inny'
          ? _customEnergySupplier.trim()
          : _energySupplier,
      estimatedPowerDemand: 100.0,
      selectedSystems: _selectedSystems,
      additionalRooms: _additionalRooms,
      subcontractors: _subcontractors,
      subcontractorLinks: _sanitizeSubcontractorLinks(),
      defaultUnitNamingScheme: _defaultUnitNamingScheme,
      estimatedUnits: totalUnits,
      totalBuildingWeeks: _totalBuildingWeeks,
      currentBuildingStage: _currentBuildingStage,
      renewableEnergyConfig: (_hasPV || _hasBESS || _hasEVCharging)
          ? RenewableEnergyConfiguration(
              photovoltaic: PhotovoltaicConfiguration(
                isEnabled: _hasPV,
                installedPowerKwp: _pvPowerKwp,
                systemSize: _pvPowerKwp > 50.0
                    ? PhotovoltaicSystemSize.large
                    : (_pvPowerKwp > 6.5
                        ? PhotovoltaicSystemSize.standard
                        : PhotovoltaicSystemSize.micro),
                estimatedMonthlyProductionKwh: (_pvPowerKwp * 1000).toInt(),
              ),
              batteryStorage: BatteryStorageConfiguration(
                isEnabled: _hasBESS,
                storageSizeKwh: _bessCapacityKwh,
              ),
              electricMobility: ElectricMobilityConfiguration(
                isEnabled: _hasEVCharging,
                chargingStations: _buildDefaultEVStations(),
                dlmSystem: _dlmSystemType,
              ),
            )
          : null,
    );

    final powerValidation = config.validatePowerModel();
    if (powerValidation.hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bledy konfiguracji zasilania:\n${powerValidation.errors.join('\n')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (powerValidation.warnings.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Uwagi do konfiguracji zasilania:\n${powerValidation.warnings.join('\n')}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    try {
      print('[Wizard] Zapisywanie projektu...');
      print(
          '[Wizard] Config: name="${config.projectName}", units=${config.estimatedUnits}, '
          'buildings=${config.buildings.length}, subcontractorLinks=${config.subcontractorLinks.length}');

      // Get the provider and save the project
      final provider =
          Provider.of<ProjectManagerProvider>(context, listen: false);
      if (widget.editMode) {
        await provider.updateProject(config);
      } else {
        await provider.createNewProject(config);
      }

      print('[Wizard] Projekt zapisany pomyślnie!');

      // Return true to indicate success
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('[Wizard] Błąd podczas zapisywania projektu: $e');
      print('[Wizard] Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Błąd zapisu: ${e.toString()}\n${stackTrace.toString().split('\n').take(3).join('\n')}',
              maxLines: 5,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 6: OZE I ELEKTROMOBILNOŚĆ
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStepOZEAndEV() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '☀️ Odnawialne Źródła Energii i Elektromobilność',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Skonfiguruj instalacje fotowoltaiczne (PV), magazyny energii (BESS) i ładowarki pojazdów elektrycznych (EV)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // == SEKCJA 1: FOTOWOLTAIKA (PV) ==
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny,
                          size: 28, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Text(
                        'Instalacja Fotowoltaiczna (PV)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Czy projekt zawiera instalację PV?'),
                    subtitle: const Text(
                        'Panele fotowoltaiczne na dachu lub gruncie'),
                    value: _hasPV,
                    onChanged: (value) {
                      setState(() {
                        _hasPV = value;
                        if (!value) {
                          _pvPowerKwp = 0.0;
                        }
                      });
                    },
                  ),
                  if (_hasPV) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildSubcontractorAssignmentField(
                      label: 'Podwykonawcy przypisani do PV',
                      targetType: SubcontractorTargetType.renewable,
                      targetId: _renewableTargetId('pv'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Moc zainstalowana (kWp)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _pvPowerKwp,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: '${_pvPowerKwp.toStringAsFixed(1)} kWp',
                            onChanged: (value) {
                              setState(() {
                                _pvPowerKwp = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${_pvPowerKwp.toStringAsFixed(1)} kWp',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    if (_pvPowerKwp > 6.5) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '⚠️ PV > 6,5 kWp wymaga zgłoszenia do Straży Pożarnej oraz uzgodnienia z rzeczoznawcą ppoż.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // == SEKCJA 2: MAGAZYN ENERGII (BESS) ==
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.battery_charging_full,
                          size: 28, color: Colors.green),
                      const SizedBox(width: 12),
                      const Text(
                        'Magazyn Energii (BESS)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Czy projekt zawiera magazyn energii?'),
                    subtitle: const Text(
                        'Baterie litowo-jonowe lub inne typy akumulatorów'),
                    value: _hasBESS,
                    onChanged: (value) {
                      setState(() {
                        _hasBESS = value;
                        if (!value) {
                          _bessCapacityKwh = 0.0;
                        }
                      });
                    },
                  ),
                  if (_hasBESS) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildSubcontractorAssignmentField(
                      label: 'Podwykonawcy przypisani do magazynu energii',
                      targetType: SubcontractorTargetType.renewable,
                      targetId: _renewableTargetId('bess'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pojemność magazynu (kWh)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _bessCapacityKwh,
                            min: 0,
                            max: 50,
                            divisions: 50,
                            label: '${_bessCapacityKwh.toStringAsFixed(1)} kWh',
                            onChanged: (value) {
                              setState(() {
                                _bessCapacityKwh = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${_bessCapacityKwh.toStringAsFixed(1)} kWh',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // == SEKCJA 3: ŁADOWARKI EV ==
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.ev_station,
                          size: 28, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'Ładowarki Pojazdów Elektrycznych (EV)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Czy projekt zawiera ładowarki EV?'),
                    subtitle: const Text(
                        'Wallboxy, słupki ładowania lub stacje szybkiego ładowania'),
                    value: _hasEVCharging,
                    onChanged: (value) {
                      setState(() {
                        _hasEVCharging = value;
                        if (!value) {
                          _evChargingStationsCount = 0;
                          _dlmSystemType = DlmSystemType.none;
                        }
                      });
                    },
                  ),
                  if (_hasEVCharging) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildSubcontractorAssignmentField(
                      label: 'Podwykonawcy przypisani do infrastruktury EV',
                      targetType: SubcontractorTargetType.ev,
                      targetId: _evTargetId(),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Liczba stanowisk ładowania',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _evChargingStationsCount.toDouble(),
                            min: 0,
                            max: 20,
                            divisions: 20,
                            label: '$_evChargingStationsCount',
                            onChanged: (value) {
                              setState(() {
                                _evChargingStationsCount = value.toInt();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '$_evChargingStationsCount',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'System zarządzania mocą (DLM)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...DlmSystemType.values.map((dlm) {
                      return RadioListTile<DlmSystemType>(
                        title: Text(_getDlmSystemLabel(dlm)),
                        subtitle: Text(_getDlmSystemDescription(dlm)),
                        value: dlm,
                        groupValue: _dlmSystemType,
                        onChanged: (value) {
                          setState(() {
                            _dlmSystemType = value ?? DlmSystemType.none;
                          });
                        },
                      );
                    }).toList(),
                    if (_evChargingStationsCount > 5 &&
                        _dlmSystemType == DlmSystemType.none) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '🚨 Więcej niż 5 stanowisk ładowania wymaga systemu DLM (zarządzania mocą) aby uniknąć przeciążenia sieci!',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Podsumowanie konfiguracji OZE/EV
          if (_hasPV || _hasBESS || _hasEVCharging) ...[
            Card(
              color: Colors.lightBlue.shade50,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.summarize, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Podsumowanie konfiguracji OZE/EV',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_hasPV)
                      ListTile(
                        leading:
                            const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(
                            'Instalacja PV: ${_pvPowerKwp.toStringAsFixed(1)} kWp'),
                        subtitle: Text(
                          _pvPowerKwp > 6.5
                              ? 'Wymaga zgłoszenia do Straży Pożarnej'
                              : 'Zgłoszenie do OSD (mikroinstalacja)',
                        ),
                      ),
                    if (_hasBESS)
                      ListTile(
                        leading:
                            const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(
                            'Magazyn energii: ${_bessCapacityKwh.toStringAsFixed(1)} kWh'),
                      ),
                    if (_hasEVCharging)
                      ListTile(
                        leading:
                            const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(
                            'Ładowarki EV: $_evChargingStationsCount stanowisk'),
                        subtitle: Text(
                            'System DLM: ${_getDlmSystemLabel(_dlmSystemType)}'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDlmSystemLabel(DlmSystemType dlm) {
    switch (dlm) {
      case DlmSystemType.none:
        return 'Brak systemu DLM';
      case DlmSystemType.passive:
        return 'DLM Pasywny (limitery mocy)';
      case DlmSystemType.activeRealtime:
        return 'DLM Aktywny (zarządzanie w czasie rzeczywistym)';
    }
  }

  String _getDlmSystemDescription(DlmSystemType dlm) {
    switch (dlm) {
      case DlmSystemType.none:
        return 'Bez zarządzania mocą (tylko dla małych instalacji)';
      case DlmSystemType.passive:
        return 'Limity mocy na stanowiskach, proste rozwiązanie';
      case DlmSystemType.activeRealtime:
        return 'Dynamiczne zarządzanie obciążeniem w czasie rzeczywistym';
    }
  }

  List<ChargingStation> _buildDefaultEVStations() {
    if (!_hasEVCharging || _evChargingStationsCount == 0) {
      return [];
    }

    return List.generate(
      _evChargingStationsCount,
      (index) => ChargingStation(
        stationId: 'ev-station-${index + 1}',
        stationName: 'Stanowisko ładowania ${index + 1}',
        stationType: ChargingStationType.wallbox,
        chargingPowerKw: 7.0, // Domyślnie 7 kW (standardowy wallbox)
        numberOfConnectors: 1,
      ),
    );
  }
}

class _SystemOption {
  final ElectricalSystemType system;
  final String label;

  const _SystemOption(this.system, this.label);
}
