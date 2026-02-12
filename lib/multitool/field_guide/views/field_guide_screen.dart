import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/theme/grid_theme.dart';
import 'package:gridly/multitool/field_guide/logic/field_guide_provider.dart';
import 'package:gridly/multitool/field_guide/models/field_guide_models.dart';
import 'package:gridly/multitool/field_guide/services/field_guide_database.dart';

class FieldGuideScreen extends StatefulWidget {
  const FieldGuideScreen({super.key});

  @override
  State<FieldGuideScreen> createState() => _FieldGuideScreenState();
}

class _FieldGuideScreenState extends State<FieldGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Przewodnik Pomiarów'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GridTheme.electricYellow,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pomiary', icon: Icon(Icons.assignment)),
            Tab(text: 'Uziemienia', icon: Icon(Icons.electric_bolt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeasurementsTab(),
          _buildGroundingTab(),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    return Consumer<FieldGuideProvider>(
      builder: (context, provider, _) {
        if (provider.currentScenario == null) {
          return _buildScenarioSelection(context);
        }
        return _buildMeasurementChecklist(context, provider);
      },
    );
  }

  Widget _buildScenarioSelection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wybierz scenariusz inspekcji',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          ...InspectionScenario.values.map((scenario) {
            final icons = {
              InspectionScenario.building: '🏢',
              InspectionScenario.flooding: '💧',
              InspectionScenario.modernization: '🔧',
              InspectionScenario.maintenance: '🔍',
            };
            final descriptions = {
              InspectionScenario.building: 'Pełna inspekcja nowego budynku',
              InspectionScenario.flooding: 'Inspekcja dopo zalania',
              InspectionScenario.modernization:
                  'Inspekcja prac modernizacyjnych',
              InspectionScenario.maintenance: 'Konserwacyjna weryfikacja',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildScenarioCard(
                context,
                scenario,
                icons[scenario] ?? '📋',
                descriptions[scenario] ?? '',
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context,
    InspectionScenario scenario,
    String icon,
    String description,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          context.read<FieldGuideProvider>().setScenario(scenario);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scenarioName(scenario),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: GridTheme.electricYellow,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementChecklist(
      BuildContext context, FieldGuideProvider provider) {
    final checklist = provider.currentMeasureChecklist;
    if (checklist == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with scenario and progress
          _buildMeasurementHeader(context, provider),
          const SizedBox(height: 24),

          // Measurements list
          ...checklist.measurements.asMap().entries.map((entry) {
            final index = entry.key;
            final measurement = entry.value;
            final result = provider.getMeasurementResult(measurement.id);
            final isPassed = result != null && result.passed;
            final isFailed = result != null && !result.passed;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMeasurementItem(
                context,
                measurement,
                result,
                isPassed,
                isFailed,
                index + 1,
              ),
            );
          }),
          const SizedBox(height: 24),

          // Complete button
          if (provider.allMeasurementsComplete)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Wszystkie pomiary ukończone',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showReport(context, provider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                    ),
                    child: const Text('Raport'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementHeader(
      BuildContext context, FieldGuideProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _scenarioName(provider.currentScenario!),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${provider.completedMeasurements}/${provider.totalMeasurements} pomiarów',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: provider.totalMeasurements > 0
                    ? provider.completedMeasurements /
                        provider.totalMeasurements
                    : 0,
                backgroundColor: Colors.grey[300],
                valueColor:
                    AlwaysStoppedAnimation<Color>(GridTheme.electricYellow),
                strokeWidth: 6,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(provider.completedMeasurements / (provider.totalMeasurements > 0 ? provider.totalMeasurements : 1) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementItem(
    BuildContext context,
    MeasurementType measurement,
    MeasurementResult? result,
    bool isPassed,
    bool isFailed,
    int index,
  ) {
    final controller = TextEditingController(text: result?.value ?? '');

    return Card(
      elevation: 1,
      color: isPassed
          ? Colors.green[50]
          : isFailed
              ? Colors.red[50]
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GridTheme.electricYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        measurement.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        measurement.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                if (isPassed)
                  Icon(Icons.check_circle, color: Colors.green[700], size: 28)
                else if (isFailed)
                  Icon(Icons.cancel, color: Colors.red[700], size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Wprowadź wartość',
                      suffixText: measurement.unit,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final updatedResult = MeasurementResult(
                          type: measurement,
                          value: value,
                          passed: _checkMeasurementPassed(measurement, value),
                          timestamp: result?.timestamp ?? DateTime.now(),
                          notes: result?.notes ?? '',
                        );
                        context
                            .read<FieldGuideProvider>()
                            .addMeasurementResult(updatedResult);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<FieldGuideProvider>()
                        .removeMeasurementResult(measurement.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Usuń'),
                ),
              ],
            ),
            if (measurement.minValue != null || measurement.maxValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _getLimitsText(measurement),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Required elements
          Text(
            'Elementy wymagające uziemienia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...FieldGuideDatabase.requiredGroundingElements
              .map((element) => _buildGroundingElement(element)),
          const SizedBox(height: 24),

          // Exceptions
          Text(
            'Wyjątki od obowiązku uziemienia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...FieldGuideDatabase.groundingExceptions
              .map((exception) => _buildGroundingException(exception)),
          const SizedBox(height: 24),

          // Cable sizes
          Text(
            'Minimalne przekroje przewodów',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...FieldGuideDatabase.cableSizeRequirements
              .map((requirement) => _buildCableSizeTable(requirement)),
        ],
      ),
    );
  }

  Widget _buildGroundingElement(GroundingElement element) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(element.icon ?? '📋', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    element.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    element.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DO WERYFIKACJI',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundingException(GroundingException exception) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exception.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exception.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '→ ${exception.reason}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber[700],
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCableSizeTable(CabelSizeRequirement requirement) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requirement.type,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              requirement.material,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
              },
              border: TableBorder.all(color: Colors.grey[300]!, width: 1),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: GridTheme.electricYellow.withValues(alpha: 0.2),
                  ),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Długość (m)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Min. rozmiar',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                ...requirement.crossSections.entries.map((entry) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${entry.key}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${entry.value} mm²',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: GridTheme.electricYellow,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _scenarioName(InspectionScenario scenario) {
    switch (scenario) {
      case InspectionScenario.building:
        return 'Odbiór budynku';
      case InspectionScenario.flooding:
        return 'Po zalaniu';
      case InspectionScenario.modernization:
        return 'Modernizacja';
      case InspectionScenario.maintenance:
        return 'Konserwacja';
    }
  }

  String _getLimitsText(MeasurementType measurement) {
    final parts = <String>[];
    if (measurement.minValue != null) {
      parts.add('min: ${measurement.minValue} ${measurement.unit}');
    }
    if (measurement.maxValue != null) {
      parts.add('max: ${measurement.maxValue} ${measurement.unit}');
    }
    return 'Norma: ${parts.join(', ')}';
  }

  bool _checkMeasurementPassed(MeasurementType measurement, String value) {
    try {
      final numValue = double.parse(value);

      if (measurement.maxValue != null) {
        final maxVal = double.parse(measurement.maxValue!);
        if (numValue > maxVal) return false;
      }

      if (measurement.minValue != null) {
        final minVal = double.parse(measurement.minValue!);
        if (numValue < minVal) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  void _showReport(BuildContext context, FieldGuideProvider provider) {
    final report = provider.getReport();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raport inspekcji'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scenariusz: ${_scenarioName(report.scenario!)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'Data: ${report.timestamp.toLocal().toString().split('.')[0]}'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: report.allPassed ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: report.allPassed ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      report.allPassed
                          ? 'W ZAKRESIE WSKAŹNIKA'
                          : 'POZA ZAKRESEM WSKAŹNIKA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: report.allPassed
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${report.passPercentage.toStringAsFixed(0)}% (${report.passedCount}/${report.totalCount})',
                      style: TextStyle(
                        color: report.allPassed
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}
