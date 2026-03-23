import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/views/unit_detail_screen.dart';
import 'package:gridly/multitool/project_manager/views/building_element_detail_screen.dart';
import 'package:gridly/multitool/project_manager/views/configuration_wizard_screen.dart';
import 'package:gridly/services/wykaz_zbiorczy_service.dart';
import 'package:gridly/services/excel_service.dart';

class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({super.key});

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectManagerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Asystent Budowy - Projekt'),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (provider.currentProject != null) ...[
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Zbiorczy Wykaz Lokali (PDF)',
                  onPressed: () => _generateWykazZbiorczy(context, provider),
                ),
                IconButton(
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  tooltip: 'Wykaz Lokali (Excel)',
                  onPressed: () => _generateWykazExcel(context, provider),
                ),
              ],
            ],
            bottom: provider.currentProject == null
                ? null
                : TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(icon: Icon(Icons.list), text: 'Lista'),
                      Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                      Tab(icon: Icon(Icons.notifications), text: 'Alerty'),
                      Tab(icon: Icon(Icons.apartment), text: 'Mieszkania'),
                      Tab(icon: Icon(Icons.meeting_room), text: 'Pomieszczenia'),
                      Tab(icon: Icon(Icons.stairs), text: 'Klatki'),
                      Tab(icon: Icon(Icons.elevator), text: 'Windy'),
                      Tab(icon: Icon(Icons.garage), text: 'Garaż'),
                      Tab(icon: Icon(Icons.roofing), text: 'Dach'),
                    ],
                  ),
          ),
          body: provider.currentProject == null
              ? _buildConfigurationScreen(context, provider)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChecklistTab(context, provider),
                    _buildTimelineTab(context, provider),
                    _buildAlertsTab(context, provider),
                    _buildUnitsTab(context, provider),
                    _buildPomieszczeniaTab(context, provider),
                    _buildKlatkiTab(context, provider),
                    _buildWindyTab(context, provider),
                    _buildGarazTab(context, provider),
                    _buildDachTab(context, provider),
                  ],
                ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EKRAN KONFIGURACJI (FIRST TIME)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConfigurationScreen(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Brak aktywnego projektu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stwórz nowy projekt budowlany aby rozpocząć.\nKliknij przycisk poniżej.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to configuration wizard
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfigurationWizardScreen(
                        editMode: false,
                        existingConfig: null,
                      ),
                    ),
                  );
                  
                  // If wizard completed successfully, reload provider
                  if (result == true && mounted) {
                    setState(() {}); // Trigger rebuild
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Projekt utworzony pomyślnie!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Stwórz nowy projekt'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: LISTA ZADAŃ (CHECKLIST)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChecklistTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROGRESS BAR
          _buildProgressCard(project),
          const SizedBox(height: 20),

          // AKTYWNA FAZA
          if (project.activePhase != null) ...[
            _buildActivePhaseCard(project.activePhase!),
            const SizedBox(height: 20),
          ],

          // TASKAMI DLA AKTUALNEJ FAZY
          const Text(
            'Zadania dla bieżącej fazy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...provider.tasksForCurrentPhase
              .map((task) => _buildTaskCard(context, task, provider))
              ,

          if (provider.tasksForCurrentPhase.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Brak zadań dla bieżącej fazy',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 32),

          // POZOSTAŁE FAZY
          const Text(
            'Przyszłe fazy',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...project.phases
              .where((p) => p.stage != project.activePhase?.stage)
              .map((phase) => _buildPhaseListItem(phase))
              ,
        ],
      ),
    );
  }

  Widget _buildProgressCard(ConstructionProject project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Postęp projektu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${project.overallProgress.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: project.overallProgress / 100,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '${project.allTasks.where((t) => t.status == TaskStatus.completed).length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Ukończone', style: TextStyle(fontSize: 11)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${project.allTasks.where((t) => t.status == TaskStatus.pending).length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Oczekujące', style: TextStyle(fontSize: 11)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${project.delayedTaskCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Text('Opóźnione', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePhaseCard(ProjectPhase phase) {
    final progress = phase.progress;
    final daysRemaining = phase.endDate.difference(DateTime.now()).inDays;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.construction, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '▶ Aktualnie: ${_getPhaseName(phase.stage)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dni pozostałe: $daysRemaining',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              'Postęp fazy: ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    ChecklistTask task,
    ProjectManagerProvider provider,
  ) {
    final isCompleted = task.status == TaskStatus.completed;
    final isDelayed = task.isDelayed;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDelayed ? Colors.red.shade50 : null,
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (value) {
                provider.updateTaskStatus(
                  task.id,
                  value ?? false ? TaskStatus.completed : TaskStatus.pending,
                );
              },
            ),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isDelayed ? Colors.red : null,
                ),
              ),
            ),
            if (isDelayed)
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 18),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                if (task.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Notatka: ${task.notes}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Otworz dialog na notatkę
                          _showAddNoteDialog(context, task, provider);
                        },
                        icon: const Icon(Icons.note_add, size: 16),
                        label: const Text('Dodaj notatkę'),
                        style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Fotografia
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zdjęcie dodane')),
                          );
                        },
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Zdjęcie'),
                        style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseListItem(ProjectPhase phase) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule,
                color: Colors.grey.shade600, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPhaseName(phase.stage),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${phase.duration.inDays} dni',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              phase.startDate.toString().split(' ')[0],
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: TIMELINE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTimelineTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harmonogram budowy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...project.phases
              .map((phase) => _buildTimelinePhase(phase))
              ,
          const SizedBox(height: 24),
          _buildProjectSummary(project),
        ],
      ),
    );
  }

  Widget _buildTimelinePhase(ProjectPhase phase) {
    final isActive = phase.isActive;
    final progress = phase.progress;
    final daysRemaining = phase.endDate.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isActive ? Colors.blue.shade50 : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.play_circle_filled : Icons.schedule,
                  color: isActive ? Colors.blue : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPhaseName(phase.stage),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.blue : Colors.black87,
                        ),
                      ),
                      Text(
                        '${phase.startDate.toString().split(' ')[0]} - ${phase.endDate.toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$daysRemaining dni',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: daysRemaining < 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Postęp: ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSummary(ConstructionProject project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Podsumowanie projektu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _summaryRow(
              'Projekt:',
              project.config.projectName,
            ),
            _summaryRow(
              'Adres:',
              project.config.address,
            ),
            _summaryRow(
              'Rozpoczęcie:',
              project.config.projectStartDate.toString().split(' ')[0],
            ),
            _summaryRow(
              'Planowe zakończenie:',
              project.config.estimatedEndDate.toString().split(' ')[0],
            ),
            _summaryRow(
              'Łącznie faz:',
              '${project.phases.length}',
            ),
            _summaryRow(
              'Łącznie zadań:',
              '${project.allTasks.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: ALERTY I POWIADOMIENIA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAlertsTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    final alerts = project.alerts;

    if (alerts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Brak alertów',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NIEPRZECZYTANE
          if (alerts.where((a) => !a.isRead).isNotEmpty) ...[
            const Text(
              'Nieprzeczytane alerty',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...alerts
                .where((a) => !a.isRead)
                .map((alert) => _buildAlertCard(context, alert, provider))
                ,
            const SizedBox(height: 24),
          ],

          // PRZECZYTANE
          if (alerts.where((a) => a.isRead).isNotEmpty) ...[
            const Text(
              'Archiwalne alerty',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...alerts
                .where((a) => a.isRead)
                .map((alert) => _buildAlertCard(context, alert, provider))
                ,
          ],
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    ProjectAlert alert,
    ProjectManagerProvider provider,
  ) {
    Color bgColor;
    Color borderColor;
    IconData icon;

    switch (alert.severity) {
      case AlertSeverity.critical:
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        icon = Icons.emergency;
        break;
      case AlertSeverity.urgent:
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.warning:
        bgColor = Colors.yellow.shade50;
        borderColor = Colors.yellow.shade700;
        icon = Icons.info;
        break;
      case AlertSeverity.info:
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue;
        icon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: borderColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!alert.isRead)
                  GestureDetector(
                    onTap: () => provider.markAlertAsRead(alert.id),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: borderColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
            if (alert.actionSuggestion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '💡 ${alert.actionSuggestion}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: MIESZKANIA / JEDNOSTKI
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUnitsTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null || project.units.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Brak mieszkań/jednostek w projekcie.\nDodaj je w kreatorze projektu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Grupowanie mieszkań po piętrach i klatkach
    final unitsByFloor = <int, List<ProjectUnit>>{};
    for (final unit in project.units) {
      unitsByFloor.putIfAbsent(unit.floor, () => []).add(unit);
    }
    
    final sortedFloors = unitsByFloor.keys.toList()..sort((a, b) => b.compareTo(a)); // Od najwyższego

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek z podsumowaniem
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.apartment, size: 40, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokale: ${project.units.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ukończonych: ${project.units.where((u) => u.completionPercentage >= 100).length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download),
                    tooltip: 'Pobierz Wykaz Lokali (PDF)',
                    onPressed: () => _generateWykazPdf(context, provider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tabela mieszkań pogrupowana po piętrach
          ...sortedFloors.map((floor) {
            final unitsOnFloor = unitsByFloor[floor]!;
            unitsOnFloor.sort((a, b) => a.unitId.compareTo(b.unitId));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Piętro ${floor == 0 ? "PARTER" : floor.toString()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: unitsOnFloor.length,
                  itemBuilder: (context, index) {
                    final unit = unitsOnFloor[index];
                    return _buildUnitCard(context, unit, provider);
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    ProjectUnit unit,
    ProjectManagerProvider provider,
  ) {
    final completion = unit.completionPercentage;
    final hasPhotos = unit.photoPaths.isNotEmpty;
    final hasDefects = unit.defectsNotes.isNotEmpty;

    Color cardColor;
    if (completion >= 100) {
      cardColor = Colors.green.shade50;
    } else if (completion >= 50) {
      cardColor = Colors.yellow.shade50;
    } else {
      cardColor = Colors.grey.shade50;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UnitDetailScreen(
              unit: unit,
            ),
          ),
        );
      },
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ID mieszkania
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    unit.unitId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isAlternateUnit)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Z',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Procent ukończenia
              Column(
                children: [
                  Text(
                    '${completion.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: completion >= 100 ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: completion / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: completion >= 100 ? Colors.green : Colors.blue,
                  ),
                ],
              ),
              
              // Ikony
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasPhotos)
                    Icon(Icons.camera_alt, size: 14, color: Colors.blue.shade700),
                  if (hasPhotos && hasDefects) const SizedBox(width: 4),
                  if (hasDefects)
                    Icon(Icons.warning, size: 14, color: Colors.orange.shade700),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5: POMIESZCZENIA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPomieszczeniaTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();
    final rooms = project.config.additionalRooms;

    if (rooms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.meeting_room, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Brak pomieszczeń dodatkowych w projekcie.\nDodaj je w konfiguracji projektu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (rooms.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openBuildingElement(
          context,
          elementId: 'room_${rooms.first.id}',
          elementName: rooms.first.name,
          areaType: BuildingAreaType.pomieszczenie,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    return _buildElementList(
      context: context,
      items: rooms
          .map((r) => _AreaItem(
                id: 'room_${r.id}',
                name: r.name,
                subtitle:
                    'Piętro ${r.floorNumber == 0 ? "Parter" : r.floorNumber}',
                icon: Icons.meeting_room,
                areaType: BuildingAreaType.pomieszczenie,
              ))
          .toList(),
      provider: provider,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 6: KLATKI SCHODOWE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKlatkiTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    final items = <_AreaItem>[];
    for (final building in project.config.buildings) {
      for (final sc in building.stairCases) {
        final id = 'staircase_${building.buildingName}_${sc.stairCaseName}';
        final name = project.config.buildings.length > 1
            ? 'Klatka ${sc.stairCaseName} – ${building.buildingName}'
            : 'Klatka ${sc.stairCaseName}';
        items.add(_AreaItem(
          id: id,
          name: name,
          subtitle: '${sc.numberOfLevels} pięter',
          icon: Icons.stairs,
          areaType: BuildingAreaType.klatka,
        ));
      }
    }

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stairs, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Brak klatek schodowych w projekcie.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (items.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openBuildingElement(
          context,
          elementId: items.first.id,
          elementName: items.first.name,
          areaType: BuildingAreaType.klatka,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    return _buildElementList(
        context: context, items: items, provider: provider);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 7: WINDY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWindyTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    final items = <_AreaItem>[];
    for (final building in project.config.buildings) {
      for (final sc in building.stairCases) {
        for (int i = 1; i <= sc.numberOfElevators; i++) {
          final id =
              'elevator_${building.buildingName}_${sc.stairCaseName}_$i';
          final name = sc.numberOfElevators > 1
              ? 'Winda $i – Klatka ${sc.stairCaseName}'
              : 'Winda – Klatka ${sc.stairCaseName}';
          items.add(_AreaItem(
            id: id,
            name: name,
            subtitle: building.buildingName,
            icon: Icons.elevator,
            areaType: BuildingAreaType.winda,
          ));
        }
      }
    }

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.elevator, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Brak wind w projekcie.\nSkonfiguruj windy w konfiguracji projektu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (items.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openBuildingElement(
          context,
          elementId: items.first.id,
          elementName: items.first.name,
          areaType: BuildingAreaType.winda,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    return _buildElementList(
        context: context, items: items, provider: provider);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 8: GARAŻ
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGarazTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    if (!project.config.hasGarage) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.garage, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Projekt nie posiada garażu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openBuildingElement(
        context,
        elementId: 'garaz_main',
        elementName: 'Garaż',
        areaType: BuildingAreaType.garaz,
      );
    });
    return const Center(child: CircularProgressIndicator());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 9: DACH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDachTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openBuildingElement(
        context,
        elementId: 'dach_main',
        elementName: 'Dach',
        areaType: BuildingAreaType.dach,
      );
    });
    return const Center(child: CircularProgressIndicator());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LISTY I NAWIGACJA (HELPER)
  // ─────────────────────────────────────────────────────────────────────────

  void _openBuildingElement(
    BuildContext context, {
    required String elementId,
    required String elementName,
    required BuildingAreaType areaType,
  }) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuildingElementDetailScreen(
          elementId: elementId,
          elementName: elementName,
          areaType: areaType,
        ),
      ),
    );
  }

  Widget _buildElementList({
    required BuildContext context,
    required List<_AreaItem> items,
    required ProjectManagerProvider provider,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final area =
            provider.getBuildingArea(item.id, item.areaType);
        final completion = area.completionPercent;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: completion >= 100
                  ? Colors.green.shade100
                  : Colors.blue.shade50,
              child: Icon(item.icon,
                  color: completion >= 100 ? Colors.green : Colors.blue),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.subtitle.isNotEmpty)
                  Text(item.subtitle,
                      style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: completion / 100,
                  backgroundColor: Colors.grey.shade300,
                  color: completion >= 100 ? Colors.green : Colors.blue,
                ),
                Text(
                  '${completion.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openBuildingElement(
              context,
              elementId: item.id,
              elementName: item.name,
              areaType: item.areaType,
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENEROWANIE WYKAZU ZBIORCZEGO (PDF)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _generateWykazZbiorczy(
    BuildContext context,
    ProjectManagerProvider provider,
  ) async {
    try {
      final project = provider.currentProject;
      if (project == null || project.units.isEmpty) {
        _showErrorSnackBar(context, 'Projekt nie ma żadnych lokali');
        return;
      }

      // Pokaż loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generowanie Wykazuo Zbiorczego...'),
          duration: Duration(seconds: 2),
        ),
      );

      final currentDate = DateTime.now().toString().split(' ')[0];

      // Definicje etapów prac
      final List<String> stageNames = [
        'Projekt zamienny',
        'Ścianki działowe',
        'Montaż okablowania',
        'Montaż okablowania - balkony',
        'Montaż puszek elektroinstalacyjnych',
        'Dokumentacja fotograficzna okablowania',
        'Doprowadzenie kabla WLZ',
        'Odbiory inspektora I',
        'Tynki',
        'Wykonanie pomiaru Riso',
        'Ułożenie rur osłonowych',
        'Dokumentacja fotograficzna rur',
        'Jastrych (wylewka)',
        'Doprowadzenie okablowania teletechnicznego',
        'Malowanie',
        'Montaż tablicy TM',
        'Podłączenie tablicy TM',
        'Montaż skrzynki TSM',
        'Montaż osprzętu',
        'Montaż unifonu',
        'Montaż czujnika dymu',
        'Montaż oprawek',
        'Uruchomienie domofonu',
        'Pomiary teletechniczne',
        'Pomiary elektryczne',
        'Odbiory inspektora II termin',
        'Odbiory inspektora III termin',
        'Odbiory inspektora końcowe',
      ];

      // Przygotuj dane dla wszystkich lokali
      final lokalEntries = <Map<String, dynamic>>[];
      
      for (final unit in project.units) {
        final entry = <String, dynamic>{
          'nrLokalu': unit.unitId,
        };

        // Zmapuj statusy zadań
        for (int i = 0; i < stageNames.length && i < project.allTasks.length; i++) {
          final task = project.allTasks[i];
          final status = unit.taskStatuses[task.id] ?? TaskStatus.pending;
          entry[stageNames[i]] = status == TaskStatus.completed ? 'true' : 'false';
        }

        lokalEntries.add(entry);
      }

      // Wywołaj serwis generowania PDF
      await WykazGenerator.generateWykazPdf(
        nazwaBudowy: project.name,
        data: currentDate,
        lokale: lokalEntries,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wykaz Zbiorczy dla projektu ${project.name} został wygenerowany!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Błąd generowania Wykazuo Zbiorczego: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _generateWykazPdf(
    BuildContext context,
    ProjectManagerProvider provider,
  ) async {
    try {
      final project = provider.currentProject;
      if (project == null || project.units.isEmpty) {
        _showErrorSnackBar(context, 'Projekt nie ma żadnych lokali');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generowanie Wykazu Lokali (PDF)...'),
          duration: Duration(seconds: 2),
        ),
      );

      final currentDate = DateTime.now().toString().split(' ')[0];

      final List<String> stageNames = [
        'Projekt zamienny',
        'Ścianki działowe',
        'Montaż okablowania',
        'Montaż okablowania - balkony',
        'Montaż puszek elektroinstalacyjnych',
        'Dokumentacja fotograficzna okablowania',
        'Doprowadzenie kabla WLZ',
        'Odbiory inspektora I',
        'Tynki',
        'Wykonanie pomiaru Riso',
        'Ułożenie rur osłonowych',
        'Dokumentacja fotograficzna rur',
        'Jastrych (wylewka)',
        'Doprowadzenie okablowania teletechnicznego',
        'Malowanie',
        'Montaż tablicy TM',
        'Podłączenie tablicy TM',
        'Montaż skrzynki TSM',
        'Montaż osprzętu',
        'Montaż unifonu',
        'Montaż czujnika dymu',
        'Montaż oprawek',
        'Uruchomienie domofonu',
        'Pomiary teletechniczne',
        'Pomiary elektryczne',
        'Odbiory inspektora II termin',
        'Odbiory inspektora III termin',
        'Odbiory inspektora końcowe',
      ];

      final lokalEntries = <Map<String, dynamic>>[];

      for (final unit in project.units) {
        final entry = <String, dynamic>{
          'nrLokalu': unit.unitId,
        };

        for (int i = 0; i < stageNames.length && i < project.allTasks.length; i++) {
          final task = project.allTasks[i];
          final status = task.status;
          entry[stageNames[i]] = status == TaskStatus.completed ? true : false;
        }

        lokalEntries.add(entry);
      }

      await WykazGenerator.generateWykazPdf(
        nazwaBudowy: project.name,
        data: currentDate,
        lokale: lokalEntries,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wykaz Lokali został wygenerowany.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Błąd generowania PDF: $e');
    }
  }

  Future<void> _generateWykazExcel(
    BuildContext context,
    ProjectManagerProvider provider,
  ) async {
    try {
      final project = provider.currentProject;
      if (project == null || project.units.isEmpty) {
        _showErrorSnackBar(context, 'Projekt nie ma żadnych lokali');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generowanie Wykazu Lokali (Excel)...'),
          duration: Duration(seconds: 2),
        ),
      );

      final currentDate = DateTime.now().toString().split(' ')[0];

      final List<String> stageNames = [
        'Projekt zamienny',
        'Ścianki działowe',
        'Montaż okablowania',
        'Montaż okablowania - balkony',
        'Montaż puszek elektroinstalacyjnych',
        'Dokumentacja fotograficzna okablowania',
        'Doprowadzenie kabla WLZ',
        'Odbiory inspektora I',
        'Tynki',
        'Wykonanie pomiaru Riso',
        'Ułożenie rur osłonowych',
        'Dokumentacja fotograficzna rur',
        'Jastrych (wylewka)',
        'Doprowadzenie okablowania teletechnicznego',
        'Malowanie',
        'Montaż tablicy TM',
        'Podłączenie tablicy TM',
        'Montaż skrzynki TSM',
        'Montaż osprzętu',
        'Montaż unifonu',
        'Montaż czujnika dymu',
        'Montaż oprawek',
        'Uruchomienie domofonu',
        'Pomiary teletechniczne',
        'Pomiary elektryczne',
        'Odbiory inspektora II termin',
        'Odbiory inspektora III termin',
        'Odbiory inspektora końcowe',
      ];

      final lokalEntries = <Map<String, dynamic>>[];

      for (final unit in project.units) {
        final entry = <String, dynamic>{
          'nrLokalu': unit.unitId,
        };

        for (int i = 0; i < stageNames.length && i < project.allTasks.length; i++) {
          final task = project.allTasks[i];
          final status = task.status;
          entry[stageNames[i]] = status == TaskStatus.completed ? 'true' : 'false';
        }

        lokalEntries.add(entry);
      }

      await ExcelService.exportWykazExcel(
        nazwaBudowy: project.name,
        data: currentDate,
        lokale: lokalEntries,
        stages: stageNames,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wykaz Lokali (Excel) został wygenerowany i pobrany!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Błąd generowania Excel: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERY
  // ═══════════════════════════════════════════════════════════════════════════

  String _getPhaseName(BuildingStage stage) {
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
        return '⚡ Osprzęt';
      case BuildingStage.malowanie:
        return '🎨 Malowanie';
      case BuildingStage.finalizacja:
        return '✅ Finalizacja';
      case BuildingStage.oddawanie:
        return '📋 Oddawanie';
      case BuildingStage.ozeInstalacje:
        return '☀️ OZE';
      case BuildingStage.evInfrastruktura:
        return '🔋 EV';
    }
  }

  void _showAddNoteDialog(
    BuildContext context,
    ChecklistTask task,
    ProjectManagerProvider provider,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj notatkę'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Wpisz notatkę...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.addTaskNote(task.id, controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notatka dodana')),
              );
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper data class for area list items
// ─────────────────────────────────────────────────────────────────────────────

class _AreaItem {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final BuildingAreaType areaType;

  const _AreaItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.areaType,
  });
}
