import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/views/unit_detail_screen.dart';

class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({Key? key}) : super(key: key);

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectManagerProvider(),
      child: Consumer<ProjectManagerProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Asystent Budowy - Projekt'),
              centerTitle: true,
              elevation: 0,
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
                    ],
                  ),
          );
        },
      ),
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
      body: _ConfigurationWizard(
        onConfigComplete: (config) async {
          try {
            print('[ProjectManager] Tworzenie projektu: ${config.projectName}');
            print('[ProjectManager] Systemy: ${config.selectedSystems.length}');
            print('[ProjectManager] Mieszkań: ${config.estimatedUnits}');
            
            // Stwórz nowy projekt
            await provider.createNewProject(config);
            
            print('[ProjectManager] Projekt utworzony!');
            
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Projekt "${config.projectName}" utworzony!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            
            setState(() {}); // Trigger rebuild
          } catch (e, stackTrace) {
            print('[ProjectManager] Błąd tworzenia projektu: $e');
            print('[ProjectManager] Stack trace: $stackTrace');
            
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Błąd: Nie udało się utworzyć projektu'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
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
              .toList(),

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
              .toList(),
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
              .toList(),
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
                .toList(),
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
                .toList(),
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
            'Brak mieszkań/jednostek w projekcie',
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
          }).toList(),
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
              Text(
                unit.unitId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

// ═══════════════════════════════════════════════════════════════════════════
// WIZARD KONFIGURACJI
// ═══════════════════════════════════════════════════════════════════════════

class _ConfigurationWizard extends StatefulWidget {
  final Function(BuildingConfiguration) onConfigComplete;

  const _ConfigurationWizard({required this.onConfigComplete});

  @override
  State<_ConfigurationWizard> createState() => _ConfigurationWizardState();
}

class _ConfigurationWizardState extends State<_ConfigurationWizard> {
  int _currentStep = 0;

  // Step 1: Dane podstawowe
  late String _projectName;
  late BuildingType _buildingType;
  late String _address;

  // Step 2: Parametry
  late int _totalLevels;
  late int _basementLevels;
  late bool _hasParking;
  late bool _hasGarage;
  late int _numberOfStairCases;
  late int _unitsPerFloorPerStairCase;

  // Step 3: Zasilanie
  late PowerSupplyType _powerSupply;
  late ConnectionType _connectionType;

  // Step 4: Systemy
  late Set<ElectricalSystemType> _selectedSystems;

  @override
  void initState() {
    super.initState();
    _projectName = '';
    _buildingType = BuildingType.wielorodzinny;
    _address = '';
    _totalLevels = 3;
    _basementLevels = 0;
    _hasParking = false;
    _hasGarage = false;
    _numberOfStairCases = 2;
    _unitsPerFloorPerStairCase = 4;
    _powerSupply = PowerSupplyType.siecNiskiegoNapieciaBezposrednio;
    _connectionType = ConnectionType.zlaczeDynamiczne;
    _selectedSystems = {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nowy projekt budowy'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // PROGRESS STEPPER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                4,
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
                        ['Dane', 'Parametry', 'Zasilanie', 'Systemy'][index],
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
                if (_currentStep < 3)
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _currentStep++);
                    },
                    child: const Text('Dalej'),
                  )
                else
                  ElevatedButton(
                    onPressed: _createProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Stwórz projekt'),
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
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nazwa projektu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => _projectName = v,
            decoration: InputDecoration(
              hintText: 'np. Nowe Mieszkania ul. Główna',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Adres budowy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => _address = v,
            decoration: InputDecoration(
              hintText: 'np. ul. Główna 123, Warszawa',
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
              setState(() => _buildingType = value ?? BuildingType.wielorodzinny);
            },
            items: BuildingType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    ))
                .toList(),
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
          const Text('Piętra nadziemne', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Slider(
            value: _totalLevels.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            label: _totalLevels.toString(),
            onChanged: (v) {
              setState(() => _totalLevels = v.toInt());
            },
          ),
          Text('${_totalLevels} pięter nadziemnych'),
          const SizedBox(height: 24),
          const Text('Piętra podziemne', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Slider(
            value: _basementLevels.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: _basementLevels.toString(),
            onChanged: (v) {
              setState(() => _basementLevels = v.toInt());
            },
          ),
          Text('${_basementLevels} pięter podziemnych'),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Konfiguracja mieszkań',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Liczba klatek schodowych', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Slider(
            value: _numberOfStairCases.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: _numberOfStairCases.toString(),
            onChanged: (v) {
              setState(() => _numberOfStairCases = v.toInt());
            },
          ),
          Text('$_numberOfStairCases ${_numberOfStairCases == 1 ? "klatka" : "klatki"}'),
          const SizedBox(height: 24),
          const Text('Mieszkań na piętro (na klatkę)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Slider(
            value: _unitsPerFloorPerStairCase.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: _unitsPerFloorPerStairCase.toString(),
            onChanged: (v) {
              setState(() => _unitsPerFloorPerStairCase = v.toInt());
            },
          ),
          Text('$_unitsPerFloorPerStairCase mieszkań na piętro (na klatkę)'),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Podsumowanie',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Łączna liczba mieszkań: ${_totalLevels * _numberOfStairCases * _unitsPerFloorPerStairCase}'),
                  Text('Nazewnictwo: A101-A${_totalLevels}0$_unitsPerFloorPerStairCase${_numberOfStairCases > 1 ? ", B101-B${_totalLevels}0$_unitsPerFloorPerStairCase, ..." : ""}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
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
            title: Text(type.toString().split('.').last),
          )).toList(),
          const SizedBox(height: 24),
          const Text('Typ połączenia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...ConnectionType.values.map((type) => RadioListTile(
            value: type,
            groupValue: _connectionType,
            onChanged: (v) {
              setState(() => _connectionType = v ?? _connectionType);
            },
            title: Text(type.toString().split('.').last),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wybierz systemy elektryczne', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...[
            ElectricalSystemType.oswietlenie,
            ElectricalSystemType.zasilanie,
            ElectricalSystemType.domofonowa,
            ElectricalSystemType.odgromowa,
            ElectricalSystemType.panelePV,
            ElectricalSystemType.ladownarki,
            ElectricalSystemType.ppoz,
            ElectricalSystemType.cctv,
            ElectricalSystemType.internet,
            ElectricalSystemType.oddymianieKlatek,
          ].map((system) => CheckboxListTile(
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
          )).toList(),
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
        return '📞 Domofon';
      case ElectricalSystemType.odgromowa:
        return '⚡ Ochrona odgromowa';
      case ElectricalSystemType.panelePV:
        return '☀️ Panele słoneczne';
      case ElectricalSystemType.ladownarki:
        return '🔋 Ładowarki samochodowe';
      case ElectricalSystemType.ppoz:
        return '🚨 System ppoż';
      case ElectricalSystemType.cctv:
        return '📹 CCTV/Monitoring';
      case ElectricalSystemType.internet:
        return '🌐 Internet/LAN';
      case ElectricalSystemType.oddymianieKlatek:
        return '💨 Oddymianie klatek';
      default:
        return system.toString();
    }
  }

  void _createProject() {
    // Szczegółowa walidacja
    final errors = <String>[];
    
    if (_projectName.isEmpty) {
      errors.add('Brak nazwy projektu');
    }
    if (_address.isEmpty) {
      errors.add('Brak adresu budowy');
    }
    if (_selectedSystems.isEmpty) {
      errors.add('Nie wybrano żadnych systemów');
    }
    
    if (errors.isNotEmpty) {
      print('[Wizard] Błędy walidacji: $errors');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uzupełnij brakujące pola:\n${errors.join('\n')}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('[Wizard] Walidacja OK, tworzenie konfiguracji...');
    print('[Wizard] - Nazwa: $_projectName');
    print('[Wizard] - Adres: $_address');
    print('[Wizard] - Systemy: ${_selectedSystems.length}');
    print('[Wizard] - Pięter: $_totalLevels');
    print('[Wizard] - Klatek: $_numberOfStairCases');
    print('[Wizard] - Mieszkań/piętro: $_unitsPerFloorPerStairCase');

    final config = BuildingConfiguration(
      projectName: _projectName,
      buildingType: _buildingType,
      address: _address,
      projectStartDate: DateTime.now(),
      totalLevels: _totalLevels,
      basementLevels: _basementLevels,
      hasParking: _hasParking,
      hasGarage: _hasGarage,
      powerSupplyType: _powerSupply,
      connectionType: _connectionType,
      estimatedPowerDemand: 100.0,
      selectedSystems: _selectedSystems,
      estimatedUnits: _buildingType == BuildingType.domek 
        ? 1 
        : _totalLevels * _numberOfStairCases * _unitsPerFloorPerStairCase,
      estimatedStairCases: _numberOfStairCases,
      stageDurations: BuildingTimingTemplates.wielorodzinny34pietra(),
    );

    print('[Wizard] Konfiguracja utworzona, wywołanie callbacka...');
    
    // Wywołaj callback
    widget.onConfigComplete(config);
    
    print('[Wizard] Callback wywołany');
  }
}
