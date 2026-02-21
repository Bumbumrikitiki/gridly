import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/zwarcie/models/short_circuit_models.dart';
import 'package:gridly/multitool/zwarcie/logic/short_circuit_provider.dart';

class ShortCircuitScreen extends StatefulWidget {
  const ShortCircuitScreen({super.key});

  @override
  State<ShortCircuitScreen> createState() => _ShortCircuitScreenState();
}

class _ShortCircuitScreenState extends State<ShortCircuitScreen> {
  final _iscNetworkController = TextEditingController(text: '3.0');
  final _cableLengthController = TextEditingController(text: '50');
  final _cableCrossSectionController = TextEditingController(text: '2.5');
  final _nominalVoltageController = TextEditingController(text: '230');

  CableMaterial _selectedMaterial = CableMaterial.copper;
  bool _isWarmCable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ShortCircuitProvider>();
      if (provider.input == null) {
        provider.calculateShortCircuit(
          ShortCircuitInput(
            iscNetwork: 3.0,
            cableLength: 50,
            cableCrossSection: 2.5,
            cableMaterial: CableMaterial.copper,
            isWarmCable: true,
            nominalVoltage: 230,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _iscNetworkController.dispose();
    _cableLengthController.dispose();
    _cableCrossSectionController.dispose();
    _nominalVoltageController.dispose();
    super.dispose();
  }

  void _calculateAndUpdate() {
    final iscNetwork = double.tryParse(_iscNetworkController.text) ?? 3.0;
    final cableLength = double.tryParse(_cableLengthController.text) ?? 50;
    final cableCrossSection = double.tryParse(_cableCrossSectionController.text) ?? 2.5;
    final nominalVoltage = double.tryParse(_nominalVoltageController.text) ?? 230;

    final input = ShortCircuitInput(
      iscNetwork: iscNetwork,
      cableLength: cableLength,
      cableCrossSection: cableCrossSection,
      cableMaterial: _selectedMaterial,
      isWarmCable: _isWarmCable,
      nominalVoltage: nominalVoltage,
    );

    context.read<ShortCircuitProvider>().calculateShortCircuit(input);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obliczenia Zwarciowe'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro card
            Card(
              color: colors.surfaceContainerHighest,
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
                            'Szybka ocena prądu zwarcia',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Narzędzie do wstępnej oceny obwodów zwarciowych na budowie. '
                      'Wyniki muszą być weryfikowane przez projektanta.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input section
            Text(
              'Parametry sieci i kabla',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Isc network
            TextField(
              controller: _iscNetworkController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Isc sieciowe (źródło) [kA]',
                hintText: '3.0',
                helperText: 'Pobierz z umowy dostawcy energii lub deklaracji przyłącza',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Tooltip(
                  message: 'Prąd zwarcia znamionowy źródła zasilania',
                  child: const Icon(Icons.flash_on),
                ),
              ),
              onChanged: (_) => _calculateAndUpdate(),
            ),
            const SizedBox(height: 12),

            // Cable length
            TextField(
              controller: _cableLengthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Długość kabla [m]',
                hintText: '50',
                helperText: 'Od rozdzielnika głównego do punktu zwarcia',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Tooltip(
                  message: 'Długość przewodu zasilającego',
                  child: const Icon(Icons.straighten),
                ),
              ),
              onChanged: (_) => _calculateAndUpdate(),
            ),
            const SizedBox(height: 12),

            // Cable cross-section
            TextField(
              controller: _cableCrossSectionController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Przekrój kabla [mm²]',
                hintText: '2.5',
                helperText: 'Wartość z dokumentacji kabla (zwykle 1.5, 2.5, 4, 6, 10 mm²)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Tooltip(
                  message: 'Powierzchnia przekroju poprzecznego przewodu',
                  child: const Icon(Icons.circle),
                ),
              ),
              onChanged: (_) => _calculateAndUpdate(),
            ),
            const SizedBox(height: 12),

            // Material dropdown
            DropdownButtonFormField<CableMaterial>(
              initialValue: _selectedMaterial,
              decoration: InputDecoration(
                labelText: 'Materiał kabla',
                helperText: 'Miedź ma lepszą przewodność niż aluminium',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Tooltip(
                  message: 'Materiał przewodu zasilającego',
                  child: const Icon(Icons.category),
                ),
              ),
              items: CableMaterial.values.map((material) {
                return DropdownMenuItem(
                  value: material,
                  child: Text('${material.code} - ${material.name}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMaterial = value);
                  _calculateAndUpdate();
                }
              },
            ),
            const SizedBox(height: 12),

            // Nominal voltage
            TextField(
              controller: _nominalVoltageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Napięcie znamionowe [V]',
                hintText: '230',
                helperText: 'Zwykle 230V (faza-ziemia) lub 400V (faza-faza)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Tooltip(
                  message: 'Napięcie robocze systemu',
                  child: const Icon(Icons.electrical_services),
                ),
              ),
              onChanged: (_) => _calculateAndUpdate(),
            ),
            const SizedBox(height: 12),

            // Temperature toggle
            Card(
              color: _isWarmCable
                  ? colors.errorContainer.withOpacity(0.3)
                  : colors.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isWarmCable
                            ? '🌡️ Kabel w pracy (70°C)'
                            : '❄️ Kabel zimny (20°C)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Switch(
                      value: _isWarmCable,
                      onChanged: (value) {
                        setState(() => _isWarmCable = value);
                        _calculateAndUpdate();
                      },
                      activeThumbColor: colors.error,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results section
            Consumer<ShortCircuitProvider>(
              builder: (context, provider, _) {
                if (provider.errorMessage != null) {
                  return Card(
                    color: colors.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  );
                }

                if (provider.result == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final result = provider.result!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main result card
                    Card(
                      color: result.isHazardous
                          ? colors.errorContainer.withOpacity(0.5)
                          : colors.primaryContainer.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Isc w punkcie pomiaru',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Icon(
                                  result.isHazardous ? Icons.warning : Icons.check_circle,
                                  color: result.isHazardous ? colors.error : colors.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${result.iscatPoint.toStringAsFixed(2)} kA',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: result.isHazardous ? colors.error : colors.primary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Opór kabla: ${result.cableResistance.toStringAsFixed(4)} Ω',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Impedancja: ${result.impedance.toStringAsFixed(4)} Ω',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Device compatibility
                    Text(
                      'Weryfikacja urządzeń ochronnych',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildDeviceTable(result.deviceChecks, context),
                    const SizedBox(height: 24),

                    // Warnings
                    if (result.warnings.isNotEmpty) ...[
                      Text(
                        'Uwagi i wskazówki',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      for (final warning in result.warnings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            color: colors.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                warning,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Information card - factors affecting short circuit current
                    Card(
                      color: colors.primaryContainer.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Od czego zależy prąd zwarcia',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFactorRow(
                                  context,
                                  '⬆️ Wzrost Isc sieci',
                                  'Zwiększa prąd zwarcia',
                                  colors,
                                ),
                                _buildFactorRow(
                                  context,
                                  '⬆️ Większy przekrój kabla',
                                  'Zwiększa prąd zwarcia (niższy opór)',
                                  colors,
                                ),
                                _buildFactorRow(
                                  context,
                                  '⬇️ Dłuższy kabel',
                                  'Zmniejsza prąd zwarcia (wyższy opór)',
                                  colors,
                                ),
                                _buildFactorRow(
                                  context,
                                  '🌡️ Ciepły kabel (70°C)',
                                  'Zmniejsza prąd zwarcia (wyższy opór)',
                                  colors,
                                ),
                                _buildFactorRow(
                                  context,
                                  '⬆️ Wyższe napięcie',
                                  'Zwiększa prąd zwarcia',
                                  colors,
                                ),
                                _buildFactorRow(
                                  context,
                                  '🔴 Miedź zamiast aluminium',
                                  'Zwiększa prąd zwarcia (lepszy przewodnik)',
                                  colors,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Standards + disclaimer
                    Card(
                      color: colors.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.gavel, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Odpowiedzialność prawna',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ReferenceTable.disclaimerText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Standards note
                    Card(
                      color: colors.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.library_books, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Normy i standardy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ReferenceTable.standardsNote,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reset button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.reset();
                          _iscNetworkController.text = '3.0';
                          _cableLengthController.text = '50';
                          _cableCrossSectionController.text = '2.5';
                          _nominalVoltageController.text = '230';
                          setState(() {
                            _selectedMaterial = CableMaterial.copper;
                            _isWarmCable = true;
                          });
                        },
                        child: const Text('Resetuj obliczenia'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorRow(
    BuildContext context,
    String factor,
    String description,
    ColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              factor,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTable(List<DeviceCheck> checks, BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Urządzenie')),
            DataColumn(label: Text('I[A]')),
            DataColumn(label: Text('Ik[kA]')),
            DataColumn(label: Text('Status')),
          ],
          rows: checks
              .map(
                (check) => DataRow(
                  color: WidgetStateColor.resolveWith((states) {
                    if (check.canWithstand) {
                      return colors.primaryContainer.withOpacity(0.2);
                    }
                    return colors.errorContainer.withOpacity(0.2);
                  }),
                  cells: <DataCell>[
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          check.deviceName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    DataCell(Text(
                      check.ratedCurrent.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.bodySmall,
                    )),
                    DataCell(Text(
                      check.breakingCapacity.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall,
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: check.canWithstand
                              ? colors.primaryContainer
                              : colors.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          check.status,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: check.canWithstand ? colors.primary : colors.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
