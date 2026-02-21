import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/uziemienie/models/measurement_analyzer_models.dart';
import 'package:gridly/multitool/uziemienie/logic/measurement_analyzer_provider.dart';

class MeasurementAnalyzerScreen extends StatefulWidget {
  const MeasurementAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<MeasurementAnalyzerScreen> createState() => _MeasurementAnalyzerScreenState();
}

class _MeasurementAnalyzerScreenState extends State<MeasurementAnalyzerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Input fields
  final _measuredResistanceController = TextEditingController(text: '1.5');
  final _locationController = TextEditingController(text: 'Główne uziemienie');
  final _notesController = TextEditingController();
  final _engineerController = TextEditingController(text: 'Inżynier');
  final _spacingController = TextEditingController(text: '3.0');
  final _lengthController = TextEditingController(text: '1.5');
  final _electrodeCountController = TextEditingController(text: '1');

  SoilTemperature _selectedTemperature = SoilTemperature.moderate;
  SoilHumidity _selectedHumidity = SoilHumidity.normal;
  Season _selectedSeason = Season.summer;
  ElectrodeInstallation _selectedInstallation =
      ElectrodeInstallation.standard;
  ElectrodeMaterial _selectedMaterial = ElectrodeMaterial.copper;
  bool _applyWeatherCorrection = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _measuredResistanceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _engineerController.dispose();
    _spacingController.dispose();
    _lengthController.dispose();
    _electrodeCountController.dispose();
    super.dispose();
  }

  void _addMeasurement(MeasurementAnalyzerProvider provider) {
    try {
      provider.addMeasurement(
        measuredResistance:
            double.tryParse(_measuredResistanceController.text) ?? 1.0,
        temperature: _selectedTemperature,
        humidity: _selectedHumidity,
        season: _selectedSeason,
        installation: _selectedInstallation,
        material: _selectedMaterial,
        numberOfElectrodes:
            int.tryParse(_electrodeCountController.text) ?? 1,
        spacingBetweenElectrodes:
            double.tryParse(_spacingController.text) ?? 3.0,
        electrodeLength: double.tryParse(_lengthController.text) ?? 1.5,
        location: _locationController.text,
        notes: _notesController.text,
        engineer: _engineerController.text,
        allowedResistance: 1.0,
        systemType: 'TN-S',
        weatherConsiderations: _applyWeatherCorrection,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pomiar dodany i przeanalizowany')),
      );

      // Move to results tab
      _tabController.animateTo(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizator Pomiaru Rezystancji'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Pomiar'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analiza'),
            Tab(icon: Icon(Icons.history), text: 'Historia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeasurementTab(colors),
          _buildAnalysisTab(colors),
          _buildHistoryTab(colors),
        ],
      ),
    );
  }

  Widget _buildMeasurementTab(ColorScheme colors) {
    return Consumer<MeasurementAnalyzerProvider>(
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
                              'Wprowadź wynik pomiaru i warunki',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pomiar zostanie skorygowany wg warunków panujących podczas pomiaru',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Measured value
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wynik pomiaru',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _measuredResistanceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Rezystancja zmierzona [Ω]',
                          border: OutlineInputBorder(),
                          suffixText: 'Ω',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Lokalizacja pomiaru',
                          hintText: 'np. Główne uziemienie budynku',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _engineerController,
                        decoration: InputDecoration(
                          labelText: 'Inżynier wykonujący pomiar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Environmental conditions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Warunki podczas pomiaru',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Temperatura gruntu',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      ...SoilTemperature.values.map((temp) =>
                          RadioListTile<SoilTemperature>(
                            title: Text(temp.label),
                            subtitle: Text(temp.description),
                            value: temp,
                            groupValue: _selectedTemperature,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() =>
                                    _selectedTemperature = value);
                              }
                            },
                          )),
                      const Divider(height: 24),
                      Text(
                        'Wilgotność gruntu',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      ...SoilHumidity.values.map((humidity) =>
                          RadioListTile<SoilHumidity>(
                            title: Text(humidity.label),
                            subtitle: Text(
                              '${humidity.description} - ${humidity.colorNote}',
                            ),
                            value: humidity,
                            groupValue: _selectedHumidity,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedHumidity = value);
                              }
                            },
                          )),
                      const Divider(height: 24),
                      Text(
                        'Sezonowość',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      ...Season.values.map((season) =>
                          RadioListTile<Season>(
                            title: Text(season.label),
                            subtitle: Text(season.description),
                            value: season,
                            groupValue: _selectedSeason,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSeason = value);
                              }
                            },
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Electrode conditions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elektrody i parametry',
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
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Długość elektrody [m]',
                          border: OutlineInputBorder(),
                          suffixText: 'm',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _spacingController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Rozstaw elektrod [m]',
                          border: OutlineInputBorder(),
                          suffixText: 'm',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Osadzenie elektrod',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      ...ElectrodeInstallation.values.map((install) =>
                          RadioListTile<ElectrodeInstallation>(
                            title: Text(install.label),
                            subtitle: Text(install.description),
                            value: install,
                            groupValue: _selectedInstallation,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() =>
                                    _selectedInstallation = value);
                              }
                            },
                          )),
                      const Divider(height: 24),
                      Text(
                        'Materiał elektrody',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      ...ElectrodeMaterial.values.map((material) =>
                          RadioListTile<ElectrodeMaterial>(
                            title: Text(material.label),
                            subtitle: Text(material.description),
                            value: material,
                            groupValue: _selectedMaterial,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedMaterial = value);
                              }
                            },
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Additional options
              Card(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Uwzględnić zmienność sezonową'),
                      value: _applyWeatherCorrection,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _applyWeatherCorrection = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Uwagi inżyniera',
                  hintText: 'Dodatkowe obserwacje, ograniczenia, uwagi...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _addMeasurement(context.read<MeasurementAnalyzerProvider>()),
                  icon: const Icon(Icons.check),
                  label: const Text('Przeanalizuj pomiar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisTab(ColorScheme colors) {
    return Consumer<MeasurementAnalyzerProvider>(
      builder: (context, provider, _) {
        if (provider.currentAnalysis == null) {
          return Center(
            child: Text(
              'Brak pomiaru do analizy\n\nDodaj pomiar w karcie "Pomiar"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        final analysis = provider.currentAnalysis!;
        final measurement = analysis.measurement;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main result
              Card(
                color: analysis.meetsRequirementsAfterCorrection
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
                          Expanded(
                            child: Text(
                              analysis.getStatus(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(
                            analysis.meetsRequirementsAfterCorrection
                                ? Icons.check_circle
                                : Icons.error,
                            size: 32,
                            color: analysis.meetsRequirementsAfterCorrection
                                ? colors.primary
                                : colors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _AnalysisRow(
                        label: 'Zmierzona rezystancja',
                        value:
                            '${measurement.measuredResistance.toStringAsFixed(3)} Ω',
                        boldValue: true,
                      ),
                      const SizedBox(height: 8),
                      _AnalysisRow(
                        label: 'Współczynnik korekcji',
                        value:
                            '×${analysis.totalCorrectionFactor.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _AnalysisRow(
                        label: 'Skorygowana rezystancja',
                        value:
                            '${analysis.correctedResistance.toStringAsFixed(3)} Ω',
                        highlight: true,
                      ),
                      const SizedBox(height: 8),
                      _AnalysisRow(
                        label: 'Limit normatywny (TN-S)',
                        value: '${analysis.allowedResistance.toStringAsFixed(1)} Ω',
                      ),
                      const SizedBox(height: 8),
                      _AnalysisRow(
                        label: 'Procent limitu',
                        value:
                            '${analysis.getPercentageOfLimit().toStringAsFixed(0)}%',
                        highlight: analysis.getPercentageOfLimit() > 100,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Comparison with previous
              if (provider.comparison != null &&
                  provider.comparison!.previous != null)
                Card(
                  color: colors.surfaceVariant.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Porównanie z pomiar em poprzednim',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.comparison!.getComparison(),
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Impacting factors
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Czynniki mające wpływ na wynik',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...analysis.getImpactingFactors().map((factor) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• $factor',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Recommendations
              Card(
                color: colors.tertiaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendacje',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...analysis.getRecommendations().map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              rec,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Raport skopiowany do schowka'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text('Eksportuj raport'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(ColorScheme colors) {
    return Consumer<MeasurementAnalyzerProvider>(
      builder: (context, provider, _) {
        final history = provider.getHistory();

        if (history.isEmpty) {
          return Center(
            child: Text(
              'Brak historii pomiarów',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

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
                          Icon(Icons.trending_up, color: colors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trend pomiarów',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  provider.getTrend(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Średnia rezystancja: ${provider.getAverageResistance().toStringAsFixed(2)} Ω',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Historia pomiarów',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...history.map((measurement) {
                final analysis = MeasurementAnalysis(
                  measurement: measurement,
                  allowedResistance: 1.0,
                  systemType: 'TN-S',
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      measurement.location,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${measurement.date.day}.${measurement.date.month}.${measurement.date.year} - ${measurement.engineer}',
                    ),
                    trailing: Text(
                      '${measurement.measuredResistance.toStringAsFixed(2)} Ω',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Szczegóły pomiaru'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Zmierzona: ${measurement.measuredResistance.toStringAsFixed(3)} Ω',
                                ),
                                Text(
                                  'Skorygowana: ${analysis.correctedResistance.toStringAsFixed(3)} Ω',
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  measurement.notes,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text('Zamknij'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool boldValue;

  const _AnalysisRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.boldValue = false,
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
          padding: highlight
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : null,
          decoration: highlight
              ? BoxDecoration(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight:
               highlight || boldValue ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ),
      ],
    );
  }
}
