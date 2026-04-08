/// Configuration wizard dla Project Managera
/// 
/// 7-krokowy wizard:
/// 1. Dane podstawowe (nazwa, adres, daty - opcjonalne)
/// 2. Budynki i klatki
/// 3. Garaże, parkingi, piętra podziemne
/// 4. Dźwigi na klatkach
/// 5. Mieszkania na piętrach
/// 6. Systemy elektryczne
/// 7. OZE i Elektromobilność

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/models/building_hierarchy.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/models/renewable_energy_config.dart';

class AdvancedConfigurationWizard extends StatefulWidget {
  final Function(AdvancedProjectConfiguration) onComplete;

  const AdvancedConfigurationWizard({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<AdvancedConfigurationWizard> createState() =>
      _AdvancedConfigurationWizardState();
}

class _AdvancedConfigurationWizardState
    extends State<AdvancedConfigurationWizard> {
  int _currentStep = 0;

  // Dane zebrane przez wizard
  final _projectNameController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  int _numberOfBuildings = 1;
  List<_BuildingSetup> _buildings = [_BuildingSetup()];

  Set<ElectricalSystemType> _selectedSystems = {};

  // OZE i EV (Krok 7)
  bool _pvInstalled = false;
  double _pvPower = 0.0;
  bool _bessInstalled = false;
  double _bessCapacity = 0.0;
  bool _evInstalled = false;
  int _evChargingPoints = 0;
  DlmSystemType _dlmSystem = DlmSystemType.none;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 6) {
      setState(() => _currentStep++);
    } else {
      _finishConfiguration();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _finishConfiguration() {
    // Generuj nazwę sekwencyjną jeśli pusta
    String projectName = _projectNameController.text.trim();
    if (projectName.isEmpty) {
      final provider = Provider.of<ProjectManagerProvider>(context, listen: false);
      final nextNumber = provider.allProjects.length + 1;
      projectName = 'Projekt #$nextNumber';
    }

    // Adres pozostaje pusty jeśli nie podano
    final String address = _addressController.text.trim();

    // Stwórz hierarchię budynków
    final buildings = <Building>[];
    for (int i = 0; i < _buildings.length; i++) {
      final setup = _buildings[i];
      final stairCases = <StairCase>[];

      for (int j = 0; j < setup.stairCases.length; j++) {
        final scSetup = setup.stairCases[j];
        stairCases.add(
          StairCase(
            name: String.fromCharCode(65 + j), // A, B, C...
            numberOfFloors: scSetup.numberOfFloors,
            numberOfElevators: scSetup.numberOfElevators,
            unitsPerFloor: Map.from(scSetup.unitsPerFloor),
          ),
        );
      }

      buildings.add(
        Building(
          name: 'Budynek ${i + 1}',
          numberOfFloors: setup.numberOfFloors,
          basementLevels: setup.basementLevels,
          hasGarage: setup.hasGarage,
          hasParking: setup.hasParking,
          stairCases: stairCases,
        ),
      );
    }

    // Stwórz konfigurację OZE/EV
    RenewableEnergyConfig? renewableConfig;
    if (_pvInstalled || _bessInstalled || _evInstalled) {
      final pvConfig = _pvInstalled
          ? PhotovoltaicConfiguration(
              isInstalled: true,
              peakPower: _pvPower,
              systemSize: PhotovoltaicConfiguration.determineSizeFromPower(_pvPower),
              requiresFireDeptApproval: _pvPower > 6.5,
              requiresOsdNotification: _pvPower <= 50,
            )
          : const PhotovoltaicConfiguration();

      final bessConfig = _bessInstalled
          ? BatteryStorageConfiguration(
              isInstalled: true,
              capacity: _bessCapacity,
              storageType: BatteryStorageConfiguration.determineTypeFromCapacity(_bessCapacity),
              requiresCertification: _bessCapacity > 20,
            )
          : const BatteryStorageConfiguration();

      final evConfig = _evInstalled
          ? ElectricMobilityConfiguration(
              isInstalled: true,
              numberOfChargingPoints: _evChargingPoints,
              stationType: ChargingStationType.wallbox,
             dlmSystem: _dlmSystem,
              requiresUdtInspection: false,
              requiresDlm: _evChargingPoints > 5,
            )
          : const ElectricMobilityConfiguration();

      renewableConfig = RenewableEnergyConfig(
        photovoltaic: pvConfig,
        batteryStorage: bessConfig,
        electricMobility: evConfig,
      );
    }

    final config = AdvancedProjectConfiguration(
      projectName: projectName,
      address: address,
      projectStartDate: _startDate!,
      projectEndDate: _endDate!,
      buildings: buildings,
      selectedSystems: _selectedSystems,
      renewableEnergyConfig: renewableConfig,
    );

    widget.onComplete(config);
  }



  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Nowy projekt - Krok ${_currentStep + 1}/7'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 7,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Wstecz'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _canProceed() ? _nextStep : null,
                    icon: Icon(
                      _currentStep == 6 ? Icons.check : Icons.arrow_forward,
                    ),
                    label: Text(_currentStep == 6 ? 'Utwórz projekt' : 'Dalej'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _startDate != null && _endDate != null;
      case 1:
        return _buildings.isNotEmpty;
      case 2:
        return true; // Garaż/parking opcjonalne
      case 3:
        return true; // Dźwigi opcjonalne
      case 4:
        return true; // Mieszkania mogą być 0
      case 5:
        return _selectedSystems.isNotEmpty;
      case 6:
        return true; // OZE/EV opcjonalne
      default:
        return false;
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2BuildingsAndStairCases();
      case 2:
        return _buildStep3GaragesAndParking();
      case 3:
        return _buildStep4Elevators();
      case 4:
        return _buildStep5UnitsPerFloor();
      case 5:
        return _buildStep6SystemsAndPreview();
      case 6:
        return _buildStep7OzeAndEv();
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KROK 1: DANE PODSTAWOWE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStep1BasicInfo() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Podstawowe informacje o projekcie',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pole nazwy i adresu są opcjonalne - system wygeneruje je automatycznie',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),

        // Nazwa projektu (opcjonalna)
        TextField(
          controller: _projectNameController,
          decoration: InputDecoration(
            labelText: 'Nazwa projektu (opcjonalna)',
            hintText: 'np. "Osiedle Słoneczne"',
            helperText: 'Zostaw puste aby system wygenerował automatycznie',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 16),

        // Adres (opcjonalny)
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Adres budowy (opcjonalny)',
            hintText: 'ul. Przykładowa 123, Warszawa',
            helperText: 'Zostaw puste aby system wygenerował automatycznie',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 24),

        // Daty
        Text(
          'Terminy realizacji',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Data rozpoczęcia
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Data rozpoczęcia'),
            subtitle: Text(
              _startDate == null
                  ? 'Wybierz datę'
                  : _formatDate(_startDate!),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                  // Jeśli data startu jest późniejsza niż koniec — przesuń koniec
                  if (_endDate != null && !_endDate!.isAfter(_startDate!)) {
                    _endDate = _startDate!.add(const Duration(days: 1));
                  }
                });
              }
            },
          ),
        ),
        const SizedBox(height: 8),

        // Data zakończenia
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Data zakończenia'),
            subtitle: Text(
              _endDate == null ? 'Wybierz datę' : _formatDate(_endDate!),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                firstDate: _startDate ?? DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _endDate = picked);
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Podsumowanie czasu
        if (_startDate != null && _endDate != null)
          Card(
            color: Colors.deepOrange.shade100,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'CZAS BUDOWY',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_endDate!.difference(_startDate!).inDays}',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'DNI BUDOWY',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(_endDate!.difference(_startDate!).inDays / 7).ceil()}',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'TYGODNI',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KROK 2: BUDYNKI I KLATKI SCHODOWE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStep2BuildingsAndStairCases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konfiguracja budynków i klatek',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),

        // Liczba budynków
        Text(
          'Liczba budynków: $_numberOfBuildings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _numberOfBuildings.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: '$_numberOfBuildings',
          onChanged: (value) {
            setState(() {
              _numberOfBuildings = value.toInt();
              // Dostosuj listę budynków
              while (_buildings.length < _numberOfBuildings) {
                _buildings.add(_BuildingSetup());
              }
              while (_buildings.length > _numberOfBuildings) {
                _buildings.removeLast();
              }
            });
          },
        ),
        const SizedBox(height: 24),

        // Konfiguracja każdego budynku
        ...List.generate(_buildings.length, (index) {
          return _buildBuildingCard(index);
        }),
      ],
    );
  }

  Widget _buildBuildingCard(int buildingIndex) {
    final setup = _buildings[buildingIndex];
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budynek ${buildingIndex + 1}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Liczba pięter nadziemnych
            Text('Liczba pięter nadziemnych: ${setup.numberOfFloors}'),
            Slider(
              value: setup.numberOfFloors.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: '${setup.numberOfFloors}',
              onChanged: (value) {
                setState(() {
                  setup.numberOfFloors = value.toInt();
                });
              },
            ),
            const SizedBox(height: 12),

            // Liczba klatek schodowych
            Text('Liczba klatek schodowych: ${setup.stairCases.length}'),
            Slider(
              value: setup.stairCases.length.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${setup.stairCases.length}',
              onChanged: (value) {
                setState(() {
                  final newCount = value.toInt();
                  while (setup.stairCases.length < newCount) {
                    setup.stairCases.add(_StairCaseSetup(
                      numberOfFloors: setup.numberOfFloors,
                    ));
                  }
                  while (setup.stairCases.length > newCount) {
                    setup.stairCases.removeLast();
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            // Szczegóły każdej klatki
            Text(
              'Szczegóły klatek schodowych:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...List.generate(setup.stairCases.length, (scIndex) {
              final sc = setup.stairCases[scIndex];
              return Card(
                color: colors.surfaceContainer,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Klatka ${String.fromCharCode(65 + scIndex)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Liczba pięter: ${sc.numberOfFloors}'),
                      Slider(
                        value: sc.numberOfFloors.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '${sc.numberOfFloors}',
                        onChanged: (value) {
                          setState(() {
                            sc.numberOfFloors = value.toInt();
                            // Zaktualizuj unitsPerFloor
                            for (int floor = 1; floor <= sc.numberOfFloors; floor++) {
                              sc.unitsPerFloor.putIfAbsent(floor, () => 4);
                            }
                            // Usuń nadmiarowe piętra
                            sc.unitsPerFloor.removeWhere(
                              (floor, _) => floor > sc.numberOfFloors,
                            );
                          });
                        },
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KROK 3: GARAŻE I PARKINGI
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStep3GaragesAndParking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Garaże i parkingi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zaznacz które budynki mają garaż lub parking',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        ...List.generate(_buildings.length, (index) {
          final setup = _buildings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budynek ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Parking checkbox
                  CheckboxListTile(
                    title: const Text('Parking'),
                    subtitle: const Text('Parking naziemny'),
                    value: setup.hasParking,
                    onChanged: (value) {
                      setState(() => setup.hasParking = value ?? false);
                    },
                  ),

                  // Garaż checkbox
                  CheckboxListTile(
                    title: const Text('Garaż'),
                    subtitle: const Text('Garaż podziemny'),
                    value: setup.hasGarage,
                    onChanged: (value) {
                      setState(() => setup.hasGarage = value ?? false);
                    },
                  ),

                  // Piętra podziemne (jeśli garaż)
                  if (setup.hasGarage) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.deepOrange.shade100,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liczba kondygnacji podziemnych: ${setup.basementLevels}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: setup.basementLevels.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: '${setup.basementLevels}',
                              activeColor: Colors.deepOrange,
                              onChanged: (value) {
                                setState(() {
                                  setup.basementLevels = value.toInt();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KROK 4: DŹWIGI
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStep4Elevators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dźwigi osobowe',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ustaw liczbę dźwigów dla każdej klatki schodowej',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        ...List.generate(_buildings.length, (buildingIndex) {
          final building = _buildings[buildingIndex];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budynek ${buildingIndex + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  ...List.generate(building.stairCases.length, (scIndex) {
                    final sc = building.stairCases[scIndex];
                    return Card(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Klatka ${String.fromCharCode(65 + scIndex)} - Dźwigów: ${sc.numberOfElevators}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: sc.numberOfElevators.toDouble(),
                              min: 0,
                              max: 5,
                              divisions: 5,
                              label: '${sc.numberOfElevators}',
                              onChanged: (value) {
                                setState(() {
                                  sc.numberOfElevators = value.toInt();
                                });
                              },
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KROK 5: MIESZKANIA NA PIĘTRACH
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStep5UnitsPerFloor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mieszkania na piętrach',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ustaw liczbę mieszkań dla każdego piętra w każdej klatce',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        ...List.generate(_buildings.length, (buildingIndex) {
          final building = _buildings[buildingIndex];
          int buildingTotal = 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budynek ${buildingIndex + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  ...List.generate(building.stairCases.length, (scIndex) {
                    final sc = building.stairCases[scIndex];
                    int scTotal = 0;

                    return Card(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Klatka ${String.fromCharCode(65 + scIndex)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Divider(height: 16),

                            // Drzewko: piętro → mieszkania
                            ...List.generate(sc.numberOfFloors, (floorIndex) {
                              final floor = floorIndex + 1;
                              final units = sc.unitsPerFloor[floor] ?? 4;
                              scTotal += units;
                              buildingTotal += units;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Piętro $floor:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                              value: units.toDouble(),
                                              min: 0,
                                              max: 25,
                                              divisions: 25,
                                              label: '$units mieszkań',
                                              onChanged: (value) {
                                                setState(() {
                                                  sc.unitsPerFloor[floor] =
                                                      value.toInt();
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '$units',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const Divider(height: 8),
                            Text(
                              'Razem w klatce: $scTotal mieszkań',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const Divider(height: 16),
                  Text(
                    'Razem w budynku: $buildingTotal mieszkań',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Całkowite podsumowanie
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RAZEM WSZYSTKICH MIESZKAŃ:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_calculateTotalUnits()}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _calculateTotalUnits() {
    int total = 0;
    for (final building in _buildings) {
      for (final sc in building.stairCases) {
        total += sc.unitsPerFloor.values.fold(0, (sum, units) => sum + units);
      }
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KROK 6: SYSTEMY ELEKTRYCZNE + PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStep6SystemsAndPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Systemy elektryczne',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wybierz systemy, które będą instalowane w projekcie',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Systemy podstawowe
        _buildSystemCategory('Podstawowe', [
          ElectricalSystemType.oswietlenie,
          ElectricalSystemType.zasilanie,
          ElectricalSystemType.klimatyzacja,
        ]),
        const SizedBox(height: 16),

        // Komunikacja
        _buildSystemCategory('Komunikacja i bezpieczeństwo', [
          ElectricalSystemType.domofonowa,
          ElectricalSystemType.internet,
          ElectricalSystemType.cctv,
          ElectricalSystemType.czujnikiRuchu,
        ]),
        const SizedBox(height: 16),

        // Zaawansowane
        _buildSystemCategory('Zaawansowane', [
          ElectricalSystemType.windaAscensor,
          ElectricalSystemType.panelePV,
          ElectricalSystemType.ladownarki,
          ElectricalSystemType.agregat,
          ElectricalSystemType.smartHome,
        ]),
        const SizedBox(height: 16),

        // Ochrona
        _buildSystemCategory('Ochrona przeciwpożarowa', [
          ElectricalSystemType.ppoz,
          ElectricalSystemType.dso,
          ElectricalSystemType.gaszeniGazem,
          ElectricalSystemType.ewakuacyjne,
          ElectricalSystemType.oddymianieKlatek,
        ]),
        const SizedBox(height: 24),

        // Podsumowanie wyboru
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Podsumowanie projektu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Divider(),
                Text('Budynków: ${_buildings.length}'),
                Text('Łączna liczba mieszkań: ${_calculateTotalUnits()}'),
                Text('Wybranych systemów: ${_selectedSystems.length}'),
                Text(
                  'Czas realizacji: ${_endDate!.difference(_startDate!).inDays} dni',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemCategory(String title, List<ElectricalSystemType> systems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: systems.map((system) {
            final isSelected = _selectedSystems.contains(system);
            return FilterChip(
              label: Text(system.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSystems.add(system);
                  } else {
                    _selectedSystems.remove(system);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'sty',
      'lut',
      'mar',
      'kwi',
      'maj',
      'cze',
      'lip',
      'sie',
      'wrz',
      'paź',
      'lis',
      'gru'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KROK 7: OZE I ELEKTROMOBILNOŚĆ
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStep7OzeAndEv() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OZE i Elektromobilność',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Czy projekt obejmuje instalacje OZE lub infrastrukturę ładowania pojazdów?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // FOTOWOLTAIKA (PV)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.orange, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Instalacja Fotowoltaiczna (PV)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                SwitchListTile(
                  title: const Text('Zainstalowana'),
                  subtitle: const Text('Czy projekt obejmuje panele fotowoltaiczne?'),
                  value: _pvInstalled,
                  onChanged: (value) {
                    setState(() => _pvInstalled = value);
                  },
                ),
                if (_pvInstalled) ...[
                  const SizedBox(height: 16),
                  Text('Moc szczytowa: ${_pvPower.toStringAsFixed(1)} kWp'),
                  Slider(
                    value: _pvPower,
                    min: 0,
                    max: 100,
                    divisions: 40,
                    label: '${_pvPower.toStringAsFixed(1)} kWp',
                    onChanged: (value) {
                      setState(() => _pvPower = value);
                    },
                  ),
                  if (_pvPower > 6.5)
                    Card(
                      color: Colors.orange.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade900),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'PV > 6.5 kWp: wymagane zgłoszenie do Państwowej Straży Pożarnej',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // MAGAZYN ENERGII (BESS)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.battery_charging_full, color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Magazyn Energii (BESS)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                SwitchListTile(
                  title: const Text('Zainstalowany'),
                  subtitle: const Text('Czy projekt obejmuje magazyn energii (baterie)?'),
                  value: _bessInstalled,
                  onChanged: (value) {
                    setState(() => _bessInstalled = value);
                  },
                ),
                if (_bessInstalled) ...[
                  const SizedBox(height: 16),
                  Text('Pojemność: ${_bessCapacity.toStringAsFixed(1)} kWh'),
                  Slider(
                    value: _bessCapacity,
                    min: 0,
                    max: 150,
                    divisions: 30,
                    label: '${_bessCapacity.toStringAsFixed(1)} kWh',
                    onChanged: (value) {
                      setState(() => _bessCapacity = value);
                    },
                  ),
                  if (_bessCapacity > 20)
                    Card(
                      color: Colors.blue.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade900),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'BESS > 20 kWh: wymagany certyfikat NC RfG',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ELEKTROMOBILNOŚĆ (EV)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.ev_station, color: Colors.blue, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Ładowarki EV',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                SwitchListTile(
                  title: const Text('Zainstalowane'),
                  subtitle: const Text('Czy projekt obejmuje stacje ładowania pojazdów?'),
                  value: _evInstalled,
                  onChanged: (value) {
                    setState(() => _evInstalled = value);
                  },
                ),
                if (_evInstalled) ...[
                  const SizedBox(height: 16),
                  Text('Liczba stanowisk ładowania: $_evChargingPoints'),
                  Slider(
                    value: _evChargingPoints.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    label: '$_evChargingPoints',
                    onChanged: (value) {
                      setState(() => _evChargingPoints = value.toInt());
                    },
                  ),
                  if (_evChargingPoints > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      'System zarządzania mocą (DLM)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<DlmSystemType>(
                      segments: const [
                        ButtonSegment(
                          value: DlmSystemType.none,
                          label: Text('Brak'),
                        ),
                        ButtonSegment(
                          value: DlmSystemType.passive,
                          label: Text('Pasywny'),
                        ),
                        ButtonSegment(
                          value: DlmSystemType.active,
                          label: Text('Aktywny'),
                        ),
                      ],
                      selected: {_dlmSystem},
                      onSelectionChanged: (Set<DlmSystemType> selected) {
                        setState(() => _dlmSystem = selected.first);
                      },
                    ),
                  ],
                  if (_evChargingPoints > 5)
                    Card(
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade900),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '> 5 stanowisk EV: system DLM jest OBOWIĄZKOWY (zapobieganie awariom zasilania)',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),

        // Podsumowanie ostrzeżeń
        if (_pvInstalled || _bessInstalled || _evInstalled) ...[
          const SizedBox(height: 24),
          Card(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Wymagane dokumenty',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ..._getRequiredDocsPreview().map((doc) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(doc)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<String> _getRequiredDocsPreview() {
    final docs = <String>[];
    
    if (_pvInstalled) {
      docs.add('Schemat jednokreskowy instalacji PV');
      if (_pvPower > 6.5) {
        docs.add('Zgłoszenie do Państwowej Straży Pożarnej');
      }
      if (_pvPower <= 50) {
        docs.add('Zgłoszenie mikroinstalacji do OSD');
      }
    }
    
    if (_bessInstalled) {
      docs.add('Karta gwarancyjna magazynu energii');
      if (_bessCapacity > 20) {
        docs.add('Certyfikat NC RfG');
      }
    }
    
    if (_evInstalled) {
      docs.add('Deklaracja zgodności stacji ładowania');
      if (_evChargingPoints > 5) {
        docs.add('Raport konfiguracji systemu DLM');
      }
    }
    
    return docs;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POMOCNICZE KLASY DO KONFIGURACJI
// ═══════════════════════════════════════════════════════════════════════════

class _BuildingSetup {
  int numberOfFloors;
  int basementLevels;
  bool hasGarage;
  bool hasParking;
  List<_StairCaseSetup> stairCases;

  _BuildingSetup({
    this.numberOfFloors = 5,
    this.basementLevels = 1,
    this.hasGarage = false,
    this.hasParking = false,
  }) : stairCases = [_StairCaseSetup(numberOfFloors: numberOfFloors)];
}

class _StairCaseSetup {
  int numberOfFloors;
  int numberOfElevators;
  Map<int, int> unitsPerFloor; // floor -> number of units

  _StairCaseSetup({
    this.numberOfFloors = 5,
    this.numberOfElevators = 0,
  }) : unitsPerFloor = {
          for (int i = 1; i <= numberOfFloors; i++) i: 4,
        };
}
