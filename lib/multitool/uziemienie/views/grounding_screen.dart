import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/uziemienie/models/grounding_models.dart';
import 'package:gridly/multitool/uziemienie/logic/grounding_provider.dart';

class GroundingScreen extends StatefulWidget {
  const GroundingScreen({Key? key}) : super(key: key);

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Input controllers
  final _systemVoltageController = TextEditingController(text: '230');
  final _designCurrentController = TextEditingController(text: '63');
  final _customSoilResistivityController = TextEditingController();
  final _electrodeCountController = TextEditingController(text: '1');
  final _electrodeLengthController = TextEditingController(text: '1.5');
  final _electrodeDiameterController = TextEditingController(text: '15');
  final _spacingController = TextEditingController(text: '3.0');

  SoilType _selectedSoilType = SoilType.clay;
  GroundingElectrodeType _selectedElectrodeType =
      GroundingElectrodeType.verticalRod;
  GroundingSystemType _selectedSystemType = GroundingSystemType.tnCS;
  bool _applySeasonalVariation = true;
  List<GroundableElement> _elements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _elements = GroundingProvider.getDefaultElements(_selectedSystemType);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroundingProvider>();
      _performInitialCalculation(provider);
    });
  }

  void _performInitialCalculation(GroundingProvider provider) {
    final input = GroundingInput(
      systemVoltage: double.tryParse(_systemVoltageController.text) ?? 230,
      soilType: _selectedSoilType,
      customSoilResistivity:
          double.tryParse(_customSoilResistivityController.text) ?? 0,
      electrodeType: _selectedElectrodeType,
      numberOfElectrodes:
          int.tryParse(_electrodeCountController.text) ?? 1,
      electrodeLength:
          double.tryParse(_electrodeLengthController.text) ?? 1.5,
      electrodeDiameter:
          double.tryParse(_electrodeDiameterController.text) ?? 15,
      spacingBetweenElectrodes:
          double.tryParse(_spacingController.text) ?? 3.0,
      isSeasonalVariation: _applySeasonalVariation,
      elementsToGround: _elements,
      designCurrent: double.tryParse(_designCurrentController.text) ?? 63,
      systemType: _selectedSystemType,
    );
    provider.calculateGrounding(input);
  }

  void _updateCalculation() {
    final provider = context.read<GroundingProvider>();
    _performInitialCalculation(provider);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _systemVoltageController.dispose();
    _designCurrentController.dispose();
    _customSoilResistivityController.dispose();
    _electrodeCountController.dispose();
    _electrodeLengthController.dispose();
    _electrodeDiameterController.dispose();
    _spacingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projekt Uziemienia'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Parametry'),
            Tab(icon: Icon(Icons.calculate), text: 'Kalkulator'),
            Tab(icon: Icon(Icons.checklist), text: 'Elementy'),
            Tab(icon: Icon(Icons.cable), text: 'Przewody'),
            Tab(icon: Icon(Icons.description), text: 'Raport'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildParametersTab(colors),
          _buildCalculatorTab(colors),
          _buildElementsTab(colors),
          _buildCablesTab(colors),
          _buildReportTab(colors),
        ],
      ),
    );
  }

  /// Tab 1: Input parameters
  Widget _buildParametersTab(ColorScheme colors) {
    return Consumer<GroundingProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System type selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Typ systemu uziemienia',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...GroundingSystemType.values
                          .where((t) => t.commonInPoland)
                          .map((type) => RadioListTile<GroundingSystemType>(
                            title: Text(type.code),
                            subtitle: Text(type.examplePl),
                            value: type,
                            groupValue: _selectedSystemType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSystemType = value;
                                  _elements = GroundingProvider.getDefaultElements(value);
                                });
                                _updateCalculation();
                              }
                            },
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Voltage and current
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parametry elektryczne',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _systemVoltageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Napięcie systemu [V]',
                          hintText: '230 lub 400',
                          border: OutlineInputBorder(),
                          suffixText: 'V',
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _designCurrentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Prąd projektowy [A]',
                          hintText: '63 A (typowo)',
                          border: OutlineInputBorder(),
                          suffixText: 'A',
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Soil parameters
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parametry gruntu',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Typ gruntu (orientacyjnie)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ...SoilType.values.map((soil) => RadioListTile<SoilType>(
                            title: Text('${soil.name} (${soil.minResistivity.toStringAsFixed(0)}-${soil.maxResistivity.toStringAsFixed(0)} Ω·m)'),
                            subtitle: Text(soil.description),
                            value: soil,
                            groupValue: _selectedSoilType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSoilType = value);
                                _updateCalculation();
                              }
                            },
                          )),
                      const SizedBox(height: 16),
                      Text(
                        'Rezystywność gruntu (wg pomiaru - opcjonalnie)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customSoilResistivityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Rezystywność [Ω·m]',
                          hintText: 'Wg pomiaru Wenner\'a',
                          border: OutlineInputBorder(),
                          helperText: 'Pozostaw puste aby użyć średniej z typu gruntu',
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Seasonal variation
              Card(
                child: CheckboxListTile(
                  title: const Text('Uwzględnić zmienność sezonową'),
                  subtitle: const Text('Zwiększa rezystancję o ~2x w okresie suchym'),
                  value: _applySeasonalVariation,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _applySeasonalVariation = value);
                      _updateCalculation();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 2: Electrode calculator
  Widget _buildCalculatorTab(ColorScheme colors) {
    return Consumer<GroundingProvider>(
      builder: (context, provider, _) {
        if (provider.errorMessage != null) {
          return Center(
            child: Card(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  provider.errorMessage ?? 'Błąd',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ),
          );
        }

        if (provider.result == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = provider.result!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Electrode selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Typ elektrody uziemiającej',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...GroundingElectrodeType.values.map((type) =>
                          RadioListTile<GroundingElectrodeType>(
                            title: Text(type.name),
                            subtitle: Text(type.description),
                            value: type,
                            groupValue: _selectedElectrodeType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedElectrodeType = value);
                                _updateCalculation();
                              }
                            },
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Electrode parameters
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parametry elektrody',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _electrodeCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Liczba elektrod',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _electrodeLengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Długość elektrody [m]',
                          border: OutlineInputBorder(),
                          suffixText: 'm',
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _electrodeDiameterController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Średnica [mm]',
                          border: OutlineInputBorder(),
                          suffixText: 'mm',
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _spacingController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Rozstaw między elektrodami [m]',
                          border: OutlineInputBorder(),
                          suffixText: 'm',
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results
              Card(
                color: result.meetsRequirements
                    ? colors.primaryContainer.withOpacity(0.5)
                    : colors.errorContainer.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            result.meetsRequirements
                                ? 'SPEŁNIA WYMAGANIA ✅'
                                : 'NIE SPEŁNIA WYMAGAŃ ❌',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: result.meetsRequirements
                                      ? colors.primary
                                      : colors.error,
                                ),
                          ),
                          Icon(
                            result.meetsRequirements
                                ? Icons.check_circle
                                : Icons.error,
                            color: result.meetsRequirements
                                ? colors.primary
                                : colors.error,
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ResultRow(
                        label: 'Rezystancja jednej elektrody',
                        value:
                            '${result.singleElectrodeResistance.toStringAsFixed(2)} Ω',
                      ),
                      const SizedBox(height: 8),
                      _ResultRow(
                        label: 'Rezystancja całego systemu',
                        value:
                            '${result.totalGroundingResistance.toStringAsFixed(2)} Ω',
                      ),
                      const SizedBox(height: 8),
                      _ResultRow(
                        label: 'Współczynnik sezonowy',
                        value: '${result.seasonalAdjustmentFactor.toStringAsFixed(2)}x',
                      ),
                      const SizedBox(height: 8),
                      _ResultRow(
                        label: 'Rezystancja (po korekcie sezonowej)',
                        value:
                            '${result.adjustedGroundingResistance.toStringAsFixed(2)} Ω',
                        highlight: true,
                      ),
                      const SizedBox(height: 8),
                      _ResultRow(
                        label: 'Maksymalna dozwolona',
                        value:
                            '${result.maxAllowedResistance.toStringAsFixed(2)} Ω',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Detailed checks
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Szczegółowe sprawdzenia',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...result.requirementChecks.map((check) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              check,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 3: Elements to ground checklist
  Widget _buildElementsTab(ColorScheme colors) {
    return Consumer<GroundingProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: colors.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: colors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Elementy do uziemienia wg PN-IEC 60364',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Zaznacz elementy metalowe budynku, które muszą być uziemione:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._elements.map((element) {
                final isRequired = element.required;
                return Card(
                  child: CheckboxListTile(
                    title: Text(
                      element.name,
                      style: TextStyle(
                        fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
                        color: isRequired ? colors.error : null,
                      ),
                    ),
                    subtitle: Text(
                      '${element.description}${isRequired ? ' (wymagane)' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: element.isSelected,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          final idx = _elements.indexOf(element);
                          _elements[idx] = element.copyWith(isSelected: value);
                        });
                        _updateCalculation();
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
              Card(
                color: colors.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: colors.onTertiaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Uwaga',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Każdy element metalowy w zasięgu osoby musi być uziemiony lub bezpiecznie odizolowany. Wymóg szczególnie ważny w łazienkach i strefach vlgc.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 4: Cable selection
  Widget _buildCablesTab(ColorScheme colors) {
    return Consumer<GroundingProvider>(
      builder: (context, provider, _) {
        if (provider.result == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = provider.result!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: colors.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cable, color: colors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dobór przewodów uziemiających (PE)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Minimalne przekroje polecane dla Twojej instalacji:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...result.suggestedCables.map((cable) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${cable.minCrossSectionMm2} mm²',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cable.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Material: ${cable.material} | Standard: ${cable.standard}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Card(
                color: colors.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sprawdzenie urządzeń ochronnych (RCD)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...result.protectionDevices.map((check) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              color: check.suitable
                                  ? colors.primaryContainer.withOpacity(0.3)
                                  : colors.errorContainer.withOpacity(0.3),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            check.device.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        Icon(
                                          check.suitable
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color: check.suitable
                                              ? colors.primary
                                              : colors.error,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      check.reason,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 5: Report
  Widget _buildReportTab(ColorScheme colors) {
    return Consumer<GroundingProvider>(
      builder: (context, provider, _) {
        if (provider.result == null) {
          return const Center(child: Text('Brak wyników do wyświetlenia'));
        }

        final result = provider.result!;
        final input = result.input;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: colors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RAPORT UZIEMIENIA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.onPrimaryContainer,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stan: ${result.meetsRequirements ? 'SPEŁNIA WYMOGI ✅' : 'WYMAGA POPRAWY ❌'}',
                                  style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Raport gotów do wydruku'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Drukuj'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ReportSection(
                title: 'PARAMETRY WEJŚCIOWE',
                content: [
                  'System uziemienia: ${input.systemType.code}',
                  'Napięcie: ${input.systemVoltage.toStringAsFixed(0)} V',
                  'Prąd projektowy: ${input.designCurrent.toStringAsFixed(0)} A',
                  'Typ gruntu: ${input.soilType.name} (${input.getSoilResistivity().toStringAsFixed(0)} Ω·m)',
                  'Typ elektrody: ${input.electrodeType.name}',
                  'Liczba elektrod: ${input.numberOfElectrodes}',
                  'Długość: ${input.electrodeLength.toStringAsFixed(1)} m | Średnica: ${input.electrodeDiameter.toStringAsFixed(0)} mm',
                ].map((t) => _reportRow(t)),
              ),
              const SizedBox(height: 16),
              _ReportSection(
                title: 'WYNIKI OBLICZEŃ',
                content: [
                  'Rezystancja jednej elektrody: ${result.singleElectrodeResistance.toStringAsFixed(3)} Ω',
                  'Rezystancja systemu: ${result.totalGroundingResistance.toStringAsFixed(3)} Ω',
                  'Współczynnik sezonowy: ${result.seasonalAdjustmentFactor.toStringAsFixed(2)}x',
                  'Rezystancja (skorygowana): ${result.adjustedGroundingResistance.toStringAsFixed(3)} Ω',
                  'Limit dozwolony: ${result.maxAllowedResistance.toStringAsFixed(3)} Ω',
                  result.meetsRequirements
                      ? '✅ SPEŁNIA WYMOGI'
                      : '❌ PRZEKRACZA LIMIT',
                ].map((t) => _reportRow(t)),
              ),
              const SizedBox(height: 16),
              _ReportSection(
                title: 'BEZPIECZEŃSTWO',
                content: result.requirementChecks.map((t) => _reportRow(t)),
              ),
              const SizedBox(height: 16),
              Card(
                color: colors.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OGRANICZENIA ODPOWIEDZIALNOŚCI',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ReferenceTable.disclaimerText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ResultRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: highlight
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Iterable<Widget> content;

  const _ReportSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 1,
              color: colors.outlineVariant,
            ),
            const SizedBox(height: 12),
            ...content.toList(),
          ],
        ),
      ),
    );
  }
}
