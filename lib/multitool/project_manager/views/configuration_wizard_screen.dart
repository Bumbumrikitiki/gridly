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
  
  const ConfigurationWizardScreen({
    super.key,
    required this.editMode,
    this.existingConfig,
  });
  
  @override
  State<ConfigurationWizardScreen> createState() => _ConfigurationWizardScreenState();
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

  // Step 2: Parametry budynków
  late int _numberOfBuildings;
  late bool _hasGarage;
  late bool _hasParking;
  late List<BuildingDetails> _buildings;

  // Step 3: Zasilanie
  late PowerSupplyType _powerSupply;
  late ConnectionType _connectionType;
  late String _energySupplier;
  late String _customEnergySupplier;

  // Step 4: Systemy
  late Set<ElectricalSystemType> _selectedSystems;

  // Step 4: Pomieszczenia dodatkowe
  late List<AdditionalRoom> _additionalRooms;

  // Step 5: Harmonogram i etap
  late int _totalBuildingWeeks;
  late BuildingStage _currentBuildingStage;

  // Step 6: OZE i Elektromobilność
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
      
      _powerSupply = config.powerSupplyType;
      _connectionType = config.connectionType;
      if (_energySuppliers.contains(config.energySupplier)) {
        _energySupplier = config.energySupplier;
        _customEnergySupplier = '';
      } else {
        _energySupplier = 'Inny';
        _customEnergySupplier = config.energySupplier;
      }
      _selectedSystems = Set<ElectricalSystemType>.from(config.selectedSystems);
      _additionalRooms = List<AdditionalRoom>.from(config.additionalRooms);
      
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
        _evChargingStationsCount = ozeConfig.electricMobility.chargingStations.length;
        _dlmSystemType = ozeConfig.electricMobility.dlmSystem;
      }
    } else {
      // Default initialization for new project
      _projectName = '';
      _buildingType = BuildingType.mieszkalny;
      _address = '';
      _projectStartDate = DateTime.now();
      _projectEndDate = DateTime.now().add(const Duration(days: 224)); // ~32 tygodnie
      
      _numberOfBuildings = 1;
      _hasGarage = false;
      _hasParking = false;
      
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
      _energySupplier = _energySuppliers.first;
      _customEnergySupplier = '';
      _selectedSystems = {};
      _additionalRooms = [];
      
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
                7,
                (index) => Expanded(
                  child: Column(
                    children: [
                      Container(
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
                      const SizedBox(height: 8),
                      Text(
                        [
                          'Dane',
                          'Zasilanie',
                          'Budynki',
                          'Pomieszczenia',
                          'Systemy',
                          'Harmonogram',
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
                if (_currentStep < 6)
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _currentStep++);
                    },
                    child: const Text('Dalej'),
                  )
                else
                  ElevatedButton(
                    onPressed: widget.editMode
                        ? _confirmEditSave
                        : _createProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.editMode ? 'Zapisz zmiany' : 'Stwórz projekt'),
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
        return _buildStep3(); // Zasilanie
      case 2:
        return _buildStep2(); // Budynki
      case 3:
        return _buildStepAdditionalRooms();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      case 6:
        return _buildStepOZEAndEV();
      default:
        return const SizedBox();
    }
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

  String _generateRandomName() {
    final List<String> adjectives = [
      'Nowe', 'Piękne', 'Nowoczesne', 'Słoneczne', 'Spokojne', 'Prestiżowe'
    ];
    final List<String> nouns = [
      'Mieszkania', 'Apartamenty', 'Osiedle', 'Budynki', 'Rezydencja', 'Kompleks'
    ];
    final List<String> spots = [
      'ul. Główna', 'ul. Nowa', 'ul. Zielona', 'ul. Słoneczna', 'Centrum', 'Strefa Premium'
    ];
    
    final adjective = adjectives[(DateTime.now().millisecond) % adjectives.length];
    final noun = nouns[(DateTime.now().millisecond) % nouns.length];
    final spot = spots[(DateTime.now().millisecond) % spots.length];
    
    return '$adjective $noun $spot';
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
    final buildingName = (room.buildingIndex >= 0 &&
            room.buildingIndex < _buildings.length)
        ? _buildings[room.buildingIndex].buildingName
        : 'Budynek ${room.buildingIndex + 1}';
    final levelLabel = room.levelType == AdditionalRoomLevelType.nadziemna
        ? 'Nadziemna'
        : 'Podziemna';
    final stair = room.stairCaseName == null
        ? ''
        : ' · Klatka ${room.stairCaseName}';
    return '$buildingName$stair · $levelLabel ${room.floorNumber}';
  }

  String _generateRandomAddress() {
    final List<String> streets = [
      'ul. Piastowska 123',
      'ul. Warszawska 456', 
      'al. Jerozolimskie 789',
      'ul. Krakowska 321',
      'ul. Gdańska 654',
      'ul. Poznańska 987'
    ];
    
    final street = streets[(DateTime.now().millisecond) % streets.length];
    return '$street, Warszawa';
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nazwa projektu (opcjonalnie)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _projectNameController,
            onChanged: (v) => _projectName = v,
            decoration: InputDecoration(
              hintText: 'Zostanie wygenerowana automatycznie jeśli puste',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Adres budowy (opcjonalnie)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            onChanged: (v) => _address = v,
            decoration: InputDecoration(
              hintText: 'Zostanie wygenerowany automatycznie jeśli puste',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Typ budynku', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
          const Text('Data rozpoczęcia budowy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                setState(() => _projectStartDate = picked);
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
          const Text('Data zakończenia budowy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                      const Icon(Icons.calendar_today, size: 28, color: Colors.white),
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          const Text('1. Liczba budynków', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          Text('$_numberOfBuildings ${_numberOfBuildings == 1 ? "budynek" : "budynki"}'),
          const SizedBox(height: 32),

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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            building.buildingName.isEmpty ? 'Budynek ${buildingIndex + 1}' : building.buildingName,
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
                                building.buildingName.isEmpty ? 'Budynek ${buildingIndex + 1}' : building.buildingName,
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
                      value: building.stairCases.length.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: building.stairCases.length.toString(),
                      onChanged: (v) {
                        final newCount = v.toInt();
                        final updatedStairCases = List<StairCaseDetails>.from(building.stairCases);
                        
                        if (newCount > updatedStairCases.length) {
                          for (int i = updatedStairCases.length; i < newCount; i++) {
                            final letter = String.fromCharCode(65 + i);
                            updatedStairCases.add(StairCaseDetails(
                              stairCaseName: letter,
                              numberOfLevels: 3,
                            ));
                          }
                        } else if (newCount < updatedStairCases.length) {
                          updatedStairCases.removeRange(newCount, updatedStairCases.length);
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
                    Text('${building.stairCases.length} ${building.stairCases.length == 1 ? "klatka" : "klatki"}'),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                        final newName = await _showEditNameDialog(
                                          context,
                                          stairCase.stairCaseName,
                                          'Edytuj nazwę klatki',
                                        );
                                        if (newName != null && newName.isNotEmpty) {
                                          setState(() {
                                            final updatedStairCases = List<StairCaseDetails>.from(building.stairCases);
                                            updatedStairCases[stairIndex] = StairCaseDetails(
                                              stairCaseName: newName,
                                              numberOfLevels: stairCase.numberOfLevels,
                                              unitsPerFloor: stairCase.unitsPerFloor,
                                              numberOfElevators: stairCase.numberOfElevators,
                                              floorNames: stairCase.floorNames,
                                            );
                                            _buildings[buildingIndex] = BuildingDetails(
                                              buildingName: building.buildingName,
                                              stairCases: updatedStairCases,
                                              basementLevels: building.basementLevels,
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
                                    final updatedStairCases = List<StairCaseDetails>.from(building.stairCases);
                                    updatedStairCases[stairIndex] = StairCaseDetails(
                                      stairCaseName: stairCase.stairCaseName,
                                      numberOfLevels: v.toInt(),
                                      unitsPerFloor: stairCase.unitsPerFloor,
                                      numberOfElevators: stairCase.numberOfElevators,
                                      floorNames: stairCase.floorNames,
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
                              ...List.generate(stairCase.numberOfLevels, (floorIndex) {
                                final floor = floorIndex + 1;
                                final currentCount = stairCase.unitsPerFloor[floor] ?? 2;
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${stairCase.getFloorName(floor)}:',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                final newName = await _showEditNameDialog(
                                                  context,
                                                  stairCase.getFloorName(floor).replaceAll(':', ''),
                                                  'Edytuj nazwę piętra',
                                                );
                                                if (newName != null && newName.isNotEmpty) {
                                                  setState(() {
                                                    final updatedStairCases = List<StairCaseDetails>.from(building.stairCases);
                                                    final updatedFloorNames = Map<int, String>.from(stairCase.floorNames);
                                                    updatedFloorNames[floor] = newName;
                                                    updatedStairCases[stairIndex] = StairCaseDetails(
                                                      stairCaseName: stairCase.stairCaseName,
                                                      numberOfLevels: stairCase.numberOfLevels,
                                                      unitsPerFloor: stairCase.unitsPerFloor,
                                                      numberOfElevators: stairCase.numberOfElevators,
                                                      floorNames: updatedFloorNames,
                                                    );
                                                    _buildings[buildingIndex] = BuildingDetails(
                                                      buildingName: building.buildingName,
                                                      stairCases: updatedStairCases,
                                                      basementLevels: building.basementLevels,
                                                    );
                                                  });
                                                }
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
                                          max: 10,
                                          divisions: 9,
                                          label: currentCount.toString(),
                                          activeColor: Colors.green.shade600,
                                          onChanged: (v) {
                                            setState(() {
                                              final updatedStairCases = List<StairCaseDetails>.from(building.stairCases);
                                              final updatedUnits = Map<int, int>.from(stairCase.unitsPerFloor);
                                              updatedUnits[floor] = v.toInt();
                                              updatedStairCases[stairIndex] = StairCaseDetails(
                                                stairCaseName: stairCase.stairCaseName,
                                                numberOfLevels: stairCase.numberOfLevels,
                                                unitsPerFloor: updatedUnits,
                                                numberOfElevators: stairCase.numberOfElevators,
                                                floorNames: stairCase.floorNames,
                                              );
                                              _buildings[buildingIndex] = BuildingDetails(
                                                buildingName: building.buildingName,
                                                stairCases: updatedStairCases,
                                                basementLevels: building.basementLevels,
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
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              building.buildingName.isEmpty ? 'Budynek ${buildingIndex + 1}' : building.buildingName,
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
                                  building.buildingName.isEmpty ? 'Budynek ${buildingIndex + 1}' : building.buildingName,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            building.buildingName.isEmpty ? 'Budynek ${buildingIndex + 1}' : building.buildingName,
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
                                building.buildingName.isEmpty ? 'Budynek ${buildingIndex + 1}' : building.buildingName,
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                        final newName = await _showEditNameDialog(
                                          context,
                                          stairCase.stairCaseName,
                                          'Edytuj nazwę klatki',
                                        );
                                        if (newName != null && newName.isNotEmpty) {
                                          setState(() {
                                            final updatedStairCases = List<StairCaseDetails>.from(building.stairCases);
                                            updatedStairCases[stairIndex] = StairCaseDetails(
                                              stairCaseName: newName,
                                              numberOfLevels: stairCase.numberOfLevels,
                                              unitsPerFloor: stairCase.unitsPerFloor,
                                              numberOfElevators: stairCase.numberOfElevators,
                                              floorNames: stairCase.floorNames,
                                            );
                                            _buildings[buildingIndex] = BuildingDetails(
                                              buildingName: building.buildingName,
                                              stairCases: updatedStairCases,
                                              basementLevels: building.basementLevels,
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
                                    final updatedStairCases = List<StairCaseDetails>.from(building.stairCases);
                                    updatedStairCases[stairIndex] = StairCaseDetails(
                                      stairCaseName: stairCase.stairCaseName,
                                      numberOfLevels: stairCase.numberOfLevels,
                                      unitsPerFloor: stairCase.unitsPerFloor,
                                      numberOfElevators: v.toInt(),
                                      floorNames: stairCase.floorNames,
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
          const Text('Typ zasilania', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...PowerSupplyType.values.map((type) => RadioListTile(
            value: type,
            groupValue: _powerSupply,
            onChanged: (v) {
              setState(() => _powerSupply = v ?? _powerSupply);
            },
            title: Text(_getPowerSupplyLabel(type)),
          )),
          const SizedBox(height: 24),
          const Text('Dostawca energii', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                errorText: customSupplierError
                    ? 'Uzupełnij nazwę dostawcy'
                    : null,
              ),
              onChanged: (value) {
                setState(() => _customEnergySupplier = value);
              },
            ),
          ],
          const SizedBox(height: 24),
          const Text('Typ połączenia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...ConnectionType.values.map((type) => RadioListTile(
            value: type,
            groupValue: _connectionType,
            onChanged: (v) {
              setState(() => _connectionType = v ?? _connectionType);
            },
            title: Text(_getConnectionLabel(type)),
          )),
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
              final total = room.tasks.length;
              final completed = room.completedTasks.length;
              final progress = total > 0 ? completed / total : 0.0;
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                  _additionalRooms.removeWhere((r) => r.id == room.id);
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 0.85
                                ? Colors.green
                                : progress >= 0.5
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        total == 0
                            ? 'Brak czynności'
                            : 'Czynności: $completed/$total',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

  Future<AdditionalRoom?> _showAdditionalRoomDialog({AdditionalRoom? existing}) async {
    final isEdit = existing != null;
    String selectedType = existing?.name ?? _additionalRoomTypes.first;
    String customName = '';
    if (!_additionalRoomTypes.contains(selectedType)) {
      selectedType = 'Inne';
      customName = existing?.name ?? '';
    }

    int buildingIndex = existing?.buildingIndex ?? 0;
    String? stairCaseName = existing?.stairCaseName;
    AdditionalRoomLevelType levelType =
        existing?.levelType ?? AdditionalRoomLevelType.nadziemna;
    int floorNumber = existing?.floorNumber ?? 0;
    Set<AdditionalRoomInstallation> installations =
        Set<AdditionalRoomInstallation>.from(existing?.installations ?? {});
    Set<AdditionalRoomTask> tasks =
        Set<AdditionalRoomTask>.from(existing?.tasks ?? {});
    Set<AdditionalRoomTask> completedTasks =
        Set<AdditionalRoomTask>.from(existing?.completedTasks ?? {});

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
            final stairCaseOptions = <String?>[null, ...stairCases.map((s) => s.stairCaseName)];

            if (!stairCaseOptions.contains(stairCaseName)) {
              stairCaseName = null;
            }

            final customNameError =
                selectedType == 'Inne' && customName.trim().isEmpty;

            return AlertDialog(
              title: Text(isEdit ? 'Edytuj pomieszczenie' : 'Dodaj pomieszczenie'),
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
                                  child: Text(value == null ? 'Brak klatki' : 'Klatka $value'),
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
                      const Text('Instalacje'),
                      const SizedBox(height: 6),
                      ...AdditionalRoomInstallation.values.map((installation) {
                        final label = _getAdditionalRoomInstallationLabel(installation);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: installations.contains(installation),
                          title: Text(label),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                installations.add(installation);
                              } else {
                                installations.remove(installation);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text('Czynności do wykonania'),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Expanded(child: Text('Czynność')),
                          Text('Do'),
                          SizedBox(width: 12),
                          Text('Zrob.'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...AdditionalRoomTask.values.map((task) {
                        final label = _getAdditionalRoomTaskLabel(task);
                        final isSelected = tasks.contains(task);
                        final isCompleted = completedTasks.contains(task);
                        return Row(
                          children: [
                            Expanded(child: Text(label)),
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    tasks.add(task);
                                  } else {
                                    tasks.remove(task);
                                    completedTasks.remove(task);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            Checkbox(
                              value: isSelected && isCompleted,
                              onChanged: isSelected
                                  ? (value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          completedTasks.add(task);
                                        } else {
                                          completedTasks.remove(task);
                                        }
                                      });
                                    }
                                  : null,
                            ),
                          ],
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
                    final name = selectedType == 'Inne'
                        ? customName.trim()
                        : selectedType.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    final sanitizedCompleted =
                        completedTasks.intersection(tasks);
                    final id = existing?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString();
                    Navigator.of(dialogContext).pop(
                      AdditionalRoom(
                        id: id,
                        name: name,
                        buildingIndex: buildingIndex,
                        stairCaseName: stairCaseName,
                        levelType: levelType,
                        floorNumber: floorNumber,
                        installations: installations,
                        tasks: tasks,
                        completedTasks: sanitizedCompleted,
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

  Widget _buildStep4() {
    // Systemy podstawowe (zawsze dostępne)
    final basicSystems = [
      ElectricalSystemType.oswietlenie,
      ElectricalSystemType.zasilanie,
      ElectricalSystemType.internet,
      ElectricalSystemType.odgromowa,
    ];

    // Systemy bezpieczeństwa
    final securitySystems = [
      ElectricalSystemType.ppoz,
      ElectricalSystemType.dso,
      ElectricalSystemType.cctv,
      ElectricalSystemType.czujnikiRuchu,
      ElectricalSystemType.sswim,
      ElectricalSystemType.gaszeniGazem,
      ElectricalSystemType.ewakuacyjne,
      ElectricalSystemType.wykrywaniWyciekow,
    ];

    // Systemy komunikacji (zależne od typu budynku)
    final communicationSystems = _buildingType == BuildingType.mieszkalny
        ? [
            ElectricalSystemType.domofonowa,
            ElectricalSystemType.telewizja,
          ]
        : [
            ElectricalSystemType.telewizja,
          ];

    // Systemy klimatyczne (głównie biura)
    final climateSystems = _buildingType == BuildingType.biurowy
        ? [
            ElectricalSystemType.klimatyzacja,
            ElectricalSystemType.bms,
            ElectricalSystemType.oddymianieKlatek,
          ]
        : [
            ElectricalSystemType.oddymianieKlatek,
          ];

    // Systemy transportu i parkingu
    final transportSystems = [
      ElectricalSystemType.windaAscensor,
      ElectricalSystemType.ladownarki,
      ElectricalSystemType.podgrzewanePodjazdy,
      ElectricalSystemType.ogrzewanieRur,
    ];

    // Systemy energetyczne i zasilanie awaryjne
    final energySystems = [
      ElectricalSystemType.panelePV,
      ElectricalSystemType.agregat,
    ];

    // Systemy inteligentne
    final smartSystems = [
      ElectricalSystemType.smartHome,
    ];

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

          // Systemy podstawowe
          _buildSystemCategory('📦 Systemy podstawowe (wymagane)', basicSystems),
          const SizedBox(height: 16),

          // Systemy bezpieczeństwa
          _buildSystemCategory('🚨 Systemy bezpieczeństwa', securitySystems),
          const SizedBox(height: 16),

          // Systemy komunikacji
          _buildSystemCategory('📞 Systemy komunikacji', communicationSystems),
          const SizedBox(height: 16),

          // Systemy klimatyczne
          _buildSystemCategory('❄️ Systemy klimatyczne i wentylacja', climateSystems),
          const SizedBox(height: 16),

          // Systemy transportu
          _buildSystemCategory('🚗 Transport i parking', transportSystems),
          const SizedBox(height: 16),

          // Systemy energetyczne
          _buildSystemCategory('⚡ Systemy energetyczne', energySystems),
          const SizedBox(height: 16),

          // Systemy inteligentne
          _buildSystemCategory('🏠 Systemy inteligentne', smartSystems),
          const SizedBox(height: 16),

          // Inne
          _buildSystemCategory('📋 Inne', [ElectricalSystemType.itp]),
        ],
      ),
    );
  }

  Widget _buildSystemCategory(String title, List<ElectricalSystemType> systems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        ...systems.map((system) => CheckboxListTile(
          dense: true,
          title: Text(_getSystemLabel(system)),
          value: _selectedSystems.contains(system),
          onChanged: (v) {
            setState(() {
              if (v ?? false) {
                _selectedSystems.add(system);
              } else {
                _selectedSystems.remove(system);
              }
            });
          },
        )),
      ],
    );
  }

  Widget _buildStep5() {
    // Oblicz przewidywany czas budowy na podstawie konfiguracji
    final totalLevels = _buildings.fold(
      0,
      (sum, building) => sum + building.stairCases.fold(
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
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
                      _currentBuildingStage = value ?? BuildingStage.przygotowanie;
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
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Główne prace:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...stageData.tasks.take(5).map((task) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 12)),
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
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
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
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Garaż podziemny dodaje ${basementLevels == 1 ? "1-2 miesiące" : "3-5 miesięcy"} do czasu budowy',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
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

  Future<String?> _showEditNameDialog(BuildContext context, String currentName, String title) async {
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
    switch (system) {
      case ElectricalSystemType.oswietlenie:
        return '💡 Oświetlenie';
      case ElectricalSystemType.zasilanie:
        return '🔌 Zasilanie (gniazda)';
      case ElectricalSystemType.domofonowa:
        return '📞 Domofon / Wideodomofon';
      case ElectricalSystemType.odgromowa:
        return '⚡ Ochrona odgromowa';
      case ElectricalSystemType.panelePV:
        return '☀️ Panele słoneczne (PV)';
      case ElectricalSystemType.ladownarki:
        return '🔋 Ładowarki samochodowe';
      case ElectricalSystemType.ppoz:
        return '🚨 System przeciwpożarowy (SSP)';
      case ElectricalSystemType.cctv:
        return '📹 Monitoring (CCTV)';
      case ElectricalSystemType.internet:
        return '🌐 Internet / Sieć LAN';
      case ElectricalSystemType.oddymianieKlatek:
        return '💨 Oddymianie klatek schodowych';
      case ElectricalSystemType.klimatyzacja:
        return '❄️ Klimatyzacja i wentylacja';
      case ElectricalSystemType.windaAscensor:
        return '🛗 Windy / Ascensory';
      case ElectricalSystemType.telewizja:
        return '📺 Antena TV / Telewizja';
      case ElectricalSystemType.agregat:
        return '⚡ Agregat prądotwórczy (UPS)';
      case ElectricalSystemType.dso:
        return '🔥 DSO (detektory dymu)';
      case ElectricalSystemType.czujnikiRuchu:
        return '👁️ Czujniki ruchu / Alarm';
      case ElectricalSystemType.podgrzewanePodjazdy:
        return '🌡️ Podgrzewane podjazdy';
      case ElectricalSystemType.ogrzewanieRur:
        return '🔥 Ogrzewanie rur (kable grzewcze)';
      case ElectricalSystemType.sswim:
        return '🚨 SSWIM (sygnalizacja włamania)';
      case ElectricalSystemType.gaszeniGazem:
        return '💨 Gaszenie gazem (FM200, CO2)';
      case ElectricalSystemType.ewakuacyjne:
        return '🚪 Oprawy ewakuacyjne';
      case ElectricalSystemType.smartHome:
        return '🏠 Smart Home / Automatyka';
      case ElectricalSystemType.bms:
        return '🖥️ BMS (Building Management System)';
      case ElectricalSystemType.wykrywaniWyciekow:
        return '💧 Detektory wycieków wody';
      case ElectricalSystemType.itp:
        return '📋 Inne systemy';
    }
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
          content: Text('Uzupełnij brakujące pola:\n${errors.join('\n')}$guidance'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Generuj losową nazwę jeśli pusta
    if (_projectName.isEmpty) {
      _projectName = _generateRandomName();
      _projectNameController.text = _projectName;
    }
    
    // Generuj losowy adres jeśli pusty
    if (_address.isEmpty) {
      _address = _generateRandomAddress();
      _addressController.text = _address;
    }

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
      energySupplier: _energySupplier == 'Inny'
          ? _customEnergySupplier.trim()
          : _energySupplier,
      estimatedPowerDemand: 100.0,
      selectedSystems: _selectedSystems,
      additionalRooms: _additionalRooms,
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

    try {
      print('[Wizard] Zapisywanie projektu...');
      
      // Get the provider and save the project
      final provider = Provider.of<ProjectManagerProvider>(context, listen: false);
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
            content: Text('Błąd: Nie udało się zapisać projektu'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
                      const Icon(Icons.wb_sunny, size: 28, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Text(
                        'Instalacja Fotowoltaiczna (PV)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Czy projekt zawiera instalację PV?'),
                    subtitle: const Text('Panele fotowoltaiczne na dachu lub gruncie'),
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
                    const Text(
                      'Moc zainstalowana (kWp)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '⚠️ PV > 6,5 kWp wymaga zgłoszenia do Straży Pożarnej oraz uzgodnienia z rzeczoznawcą ppoż.',
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
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
                      const Icon(Icons.battery_charging_full, size: 28, color: Colors.green),
                      const SizedBox(width: 12),
                      const Text(
                        'Magazyn Energii (BESS)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Czy projekt zawiera magazyn energii?'),
                    subtitle: const Text('Baterie litowo-jonowe lub inne typy akumulatorów'),
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
                    const Text(
                      'Pojemność magazynu (kWh)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      const Icon(Icons.ev_station, size: 28, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'Ładowarki Pojazdów Elektrycznych (EV)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Czy projekt zawiera ładowarki EV?'),
                    subtitle: const Text('Wallboxy, słupki ładowania lub stacje szybkiego ładowania'),
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
                    const Text(
                      'Liczba stanowisk ładowania',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'System zarządzania mocą (DLM)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                    if (_evChargingStationsCount > 5 && _dlmSystemType == DlmSystemType.none) ...[
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
                                style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_hasPV)
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Instalacja PV: ${_pvPowerKwp.toStringAsFixed(1)} kWp'),
                        subtitle: Text(
                          _pvPowerKwp > 6.5
                              ? 'Wymaga zgłoszenia do Straży Pożarnej'
                              : 'Zgłoszenie do OSD (mikroinstalacja)',
                        ),
                      ),
                    if (_hasBESS)
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Magazyn energii: ${_bessCapacityKwh.toStringAsFixed(1)} kWh'),
                      ),
                    if (_hasEVCharging)
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Ładowarki EV: $_evChargingStationsCount stanowisk'),
                        subtitle: Text('System DLM: ${_getDlmSystemLabel(_dlmSystemType)}'),
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
