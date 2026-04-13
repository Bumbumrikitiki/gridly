import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_area_catalog.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/views/unit_detail_screen.dart';
import 'package:gridly/multitool/project_manager/views/project_area_detail_screen.dart';
import 'package:gridly/multitool/project_manager/views/configuration_wizard_screen.dart';
import 'package:gridly/services/wykaz_zbiorczy_service.dart';
import 'package:gridly/services/excel_service.dart';
import 'package:gridly/services/local_notifications_service.dart';

class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({super.key});

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const String _customRecurringAlertKey = '__custom__';
  static const List<int> _reminderOptionsMinutes = [0, 15, 30, 60, 120, 1440];

  static const Map<String, String> _recurringAlertTemplates = {
    'sporządzenie protokołu przerobowego': 'Sporządzenie protokołu przerobowego',
    'sporządzenie protokołu czystości': 'Sporządzenie protokołu czystości',
    'przejście kontrolne bhp': 'Przejście kontrolne BHP',
    'przejście kontrolne czystości': 'Przejście kontrolne czystości',
    'narada koordynacyjna': 'Narada koordynacyjna',
    'raport stanu osobowego': 'Raport stanu osobowego',
    'kontrola trzeźwości': 'Kontrola trzeźwości',
    'pomiary okresowe instalacji zasilania budowlanego':
        'Pomiary okresowe instalacji zasilania budowlanego',
    'pomiary okresowe urządzeń elektrycznych':
        'Pomiary okresowe urządzeń elektrycznych',
    _customRecurringAlertKey: 'Własny',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        context.read<ProjectManagerProvider>().syncRecurringAlerts();
      }
    });
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
                      Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                      Tab(icon: Icon(Icons.groups_2), text: 'Podwykonawcy'),
                      Tab(icon: Icon(Icons.apartment), text: 'Mieszkania'),
                      Tab(icon: Icon(Icons.meeting_room), text: 'Pomieszczenia'),
                      Tab(icon: Icon(Icons.apartment_outlined), text: 'Klatki'),
                      Tab(icon: Icon(Icons.elevator), text: 'Windy'),
                      Tab(icon: Icon(Icons.local_parking), text: 'Garaż'),
                      Tab(icon: Icon(Icons.roofing), text: 'Dach'),
                      Tab(icon: Icon(Icons.park), text: 'Teren zewn.'),
                      Tab(icon: Icon(Icons.notifications), text: 'Alerty'),
                    ],
                  ),
          ),
          body: provider.currentProject == null
              ? _buildConfigurationScreen(context, provider)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimelineTab(context, provider),
                    _buildSubcontractorsTab(context, provider),
                    _buildUnitsTab(context, provider),
                    _buildProjectAreaTab(
                      context,
                      provider,
                      title: 'Pomieszczenia',
                      emptyMessage: 'Brak pomieszczeń dodatkowych w projekcie.',
                      types: const {ProjectAreaType.room},
                    ),
                    _buildProjectAreaTab(
                      context,
                      provider,
                      title: 'Klatki schodowe',
                      emptyMessage: 'Brak klatek schodowych w projekcie.',
                      types: const {ProjectAreaType.stairCase},
                    ),
                    _buildProjectAreaTab(
                      context,
                      provider,
                      title: 'Windy',
                      emptyMessage: 'Brak wind w projekcie.',
                      types: const {ProjectAreaType.elevator},
                    ),
                    _buildProjectAreaTab(
                      context,
                      provider,
                      title: 'Garaż',
                      emptyMessage: 'Brak garażu lub parkingu w projekcie.',
                      types: const {ProjectAreaType.garage},
                    ),
                    _buildProjectAreaTab(
                      context,
                      provider,
                      title: 'Dach',
                      emptyMessage: 'Brak zakresów dachowych w projekcie.',
                      types: const {ProjectAreaType.roof},
                    ),
                    _buildProjectAreaTab(
                      context,
                      provider,
                      title: 'Teren zewnętrzny',
                      emptyMessage: 'Brak zewnętrznych stref robót w projekcie.',
                      types: const {ProjectAreaType.externalArea},
                    ),
                    _buildAlertsTab(context, provider),
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

          _buildDailyPrioritiesCard(context, provider),
          const SizedBox(height: 20),

          _buildWeeklyExecutionCard(context, provider),
          const SizedBox(height: 20),

          // TASKAMI DLA AKTUALNEJ FAZY
          const Text(
            'Zadania dla bieżącej fazy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...provider.tasksForCurrentPhase
              .map((task) => _buildTaskCard(context, task, provider)),

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
              .map((phase) => _buildPhaseListItem(phase)),
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
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
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
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
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
                if (task.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.isDelayed
                        ? 'Termin: ${_formatDate(task.dueDate!)} (opóźnione)'
                        : 'Termin: ${_formatDate(task.dueDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: task.isDelayed ? Colors.red.shade700 : Colors.grey,
                    ),
                  ),
                ],
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
                        style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact),
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
                        style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact),
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

  Widget _buildDailyPrioritiesCard(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final dueToday = provider.tasksDueToday;
    final delayed = provider.delayedTasks;
    final upcoming = provider.getUpcomingTasks(withinDays: 3);

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priorytety na dziś',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityChip(
                  label: 'Dziś: ${dueToday.length}',
                  color: Colors.blue.shade100,
                ),
                _buildPriorityChip(
                  label: 'Opóźnione: ${delayed.length}',
                  color: delayed.isEmpty
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                ),
                _buildPriorityChip(
                  label: 'Następne 3 dni: ${upcoming.length}',
                  color: Colors.amber.shade100,
                ),
              ],
            ),
            if (dueToday.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...dueToday.take(3).map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_checked,
                              size: 10, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _shiftScheduleFromMobile(
                    context,
                    provider,
                    days: 3,
                    label: 'Przesuń +3 dni',
                  ),
                  icon: const Icon(Icons.event, size: 16),
                  label: const Text('Przesuń +3 dni'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _shiftScheduleFromMobile(
                    context,
                    provider,
                    days: 7,
                    label: 'Przesuń +7 dni',
                  ),
                  icon: const Icon(Icons.event_repeat, size: 16),
                  label: const Text('Przesuń +7 dni'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _shiftScheduleFromMobile(
                    context,
                    provider,
                    days: -3,
                    label: 'Cofnij -3 dni',
                  ),
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Cofnij -3 dni'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shiftScheduleFromMobile(
    BuildContext context,
    ProjectManagerProvider provider, {
    required int days,
    required String label,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Szybkie replanowanie'),
        content: Text(
          'Czy chcesz wykonać: $label?\n\nZmiana obejmie aktywną fazę i kolejne etapy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Potwierdź'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await provider.shiftSchedule(
      days: days,
      reason: 'Szybki replan mobilny',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Harmonogram zaktualizowany: $label'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPriorityChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildWeeklyExecutionCard(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final snapshot = provider.getWeeklyExecutionSnapshot();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tydzień: Plan vs Wykonanie',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_formatDate(snapshot.weekStart)} - ${_formatDate(snapshot.weekEnd)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityChip(
                  label: 'Plan: ${snapshot.plannedCount}',
                  color: Colors.blue.shade50,
                ),
                _buildPriorityChip(
                  label: 'Wykonane: ${snapshot.completedCount}',
                  color: Colors.green.shade50,
                ),
                _buildPriorityChip(
                  label: 'Odchyłka: ${snapshot.varianceLabel}',
                  color: snapshot.varianceCount >= 0
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                ),
                _buildPriorityChip(
                  label: 'Przeniesione: ${snapshot.carryOverCount}',
                  color: Colors.amber.shade50,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: snapshot.planCompletionRate,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Realizacja planu tygodnia: ${(snapshot.planCompletionRate * 100).toStringAsFixed(0)}% • Otwarte w planie: ${snapshot.plannedOpenCount}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showWeeklyExecutionDetails(context, snapshot),
                icon: const Icon(Icons.insights, size: 16),
                label: const Text('Szczegóły tygodnia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWeeklyExecutionDetails(
    BuildContext context,
    WeeklyExecutionSnapshot snapshot,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Odchyłki tygodnia'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan zadań: ${snapshot.plannedCount}'),
              Text('Wykonane zadania: ${snapshot.completedCount}'),
              Text('Wykonane z planu: ${snapshot.plannedCompletedCount}'),
              Text('Otwarte z planu: ${snapshot.plannedOpenCount}'),
              Text('Przeterminowane: ${snapshot.overdueOpenCount}'),
              const SizedBox(height: 10),
              const Text(
                'Najbardziej przeterminowane:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (snapshot.topOverdueTasks.isEmpty)
                const Text('Brak przeterminowanych zadań.')
              else
                ...snapshot.topOverdueTasks.take(5).map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '- ${task.title} (${task.dueDate != null ? _formatDate(task.dueDate!) : 'brak terminu'})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'poniedziałek';
      case DateTime.tuesday:
        return 'wtorek';
      case DateTime.wednesday:
        return 'środa';
      case DateTime.thursday:
        return 'czwartek';
      case DateTime.friday:
        return 'piątek';
      case DateTime.saturday:
        return 'sobota';
      case DateTime.sunday:
        return 'niedziela';
      default:
        return 'dzień tygodnia';
    }
  }

  String _remindBeforeLabel(int minutes) {
    if (minutes <= 0) return 'dokładnie o terminie';
    if (minutes < 60) return '$minutes min wcześniej';
    if (minutes < 1440) return '${minutes ~/ 60} godz wcześniej';
    return '${minutes ~/ 1440} dzień wcześniej';
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  DateTime _alignDateToWeekday(DateTime date, int weekday) {
    final delta = (weekday - date.weekday + 7) % 7;
    return DateTime(date.year, date.month, date.day + delta);
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
            Icon(Icons.schedule, color: Colors.grey.shade600, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPhaseName(phase.stage),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 8),
          Text(
            'Wybierz etap jako aktualny bez utrzymywania osobnej checklisty harmonogramowej.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ...project.phases
              .map((phase) => _buildTimelinePhase(context, phase, provider)),
          const SizedBox(height: 24),
          _buildProjectSummary(project),
        ],
      ),
    );
  }

  Widget _buildTimelinePhase(
    BuildContext context,
    ProjectPhase phase,
    ProjectManagerProvider provider,
  ) {
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: isActive
                    ? null
                    : () async {
                        await provider.alignScheduleToStage(
                          phase.stage,
                          reason: 'Ręczne ustawienie etapu z timeline',
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ustawiono etap: ${_getPhaseName(phase.stage)}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                icon: const Icon(Icons.flag, size: 16),
                label: Text(isActive ? 'Etap aktualny' : 'Ustaw jako aktualny'),
              ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Alerty cykliczne',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddRecurringAlertDialog(context, provider),
                        icon: const Icon(Icons.add_alert, size: 16),
                        label: const Text('Dodaj cykliczny'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (project.recurringAlerts.isEmpty)
                    Text(
                      'Brak zdefiniowanych przypomnień cyklicznych.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    )
                  else
                    ...project.recurringAlerts.map(
                      (recurring) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        isThreeLine: true,
                        title: Text(recurring.title),
                        subtitle: Text(
                          'Co ${_recurrenceLabel(recurring.intervalDays)} • termin: ${_formatDateTime(recurring.nextOccurrenceAt)}${recurring.preferredWeekday != null ? ' • ${_weekdayLabel(recurring.preferredWeekday!)}' : ''}\nPrzypomnienie: ${_remindBeforeLabel(recurring.remindBeforeMinutes)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Usuń przypomnienie',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              provider.removeRecurringAlert(recurring.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Text(
              'Brak alertów jednorazowych',
              style: TextStyle(color: Colors.grey.shade600),
            ),

          // NIEPRZECZYTANE
          if (alerts.where((a) => !a.isRead).isNotEmpty) ...[
            const Text(
              'Nieprzeczytane alerty',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...alerts
                .where((a) => !a.isRead)
                .map((alert) => _buildAlertCard(context, alert, provider)),
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
                .map((alert) => _buildAlertCard(context, alert, provider)),
          ],
        ],
      ),
    );
  }

  String _recurrenceLabel(int days) {
    if (days == 1) return '1 dzień';
    if (days == 7) return '7 dni';
    if (days == 14) return '14 dni';
    if (days == 30) return '30 dni';
    return '$days dni';
  }

  Future<void> _showAddRecurringAlertDialog(
    BuildContext context,
    ProjectManagerProvider provider,
  ) async {
    String selectedTemplateKey = _recurringAlertTemplates.keys.first;
    String customTitle = '';
    int intervalDays = 7;
    final now = DateTime.now();
    DateTime selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    int remindBeforeMinutes = 0;
    int? preferredWeekday = DateTime.now().add(const Duration(days: 7)).weekday;
    String? scheduleError;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final needsCustom = selectedTemplateKey == _customRecurringAlertKey;
            final isCustomValid = !needsCustom || customTitle.trim().isNotEmpty;
            final supportsWeekday = intervalDays % 7 == 0;
            final occurrenceAt = _combineDateAndTime(selectedDate, selectedTime);

            return AlertDialog(
              title: const Text('Nowy alert cykliczny'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Typ przypomnienia'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTemplateKey,
                        items: _recurringAlertTemplates.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedTemplateKey = value;
                            scheduleError = null;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      if (needsCustom) ...[
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (value) {
                            setDialogState(() {
                              customTitle = value;
                              scheduleError = null;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Własna nazwa alertu',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            errorText: isCustomValid
                                ? null
                                : 'Podaj nazwę własnego alertu',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text('Cykliczność'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: intervalDays,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Codziennie')),
                          DropdownMenuItem(value: 7, child: Text('Co tydzień')),
                          DropdownMenuItem(value: 14, child: Text('Co 2 tygodnie')),
                          DropdownMenuItem(value: 30, child: Text('Co miesiąc (30 dni)')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            intervalDays = value;
                            if (intervalDays % 7 != 0) {
                              preferredWeekday = null;
                            } else {
                              preferredWeekday ??= selectedDate.weekday;
                              selectedDate =
                                  _alignDateToWeekday(selectedDate, preferredWeekday!);
                            }
                            scheduleError = null;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      if (supportsWeekday) ...[
                        const SizedBox(height: 12),
                        const Text('Dzień tygodnia'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: preferredWeekday,
                          items: List.generate(
                            7,
                            (index) => DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(_weekdayLabel(index + 1)),
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              preferredWeekday = value;
                              selectedDate =
                                  _alignDateToWeekday(selectedDate, value);
                              scheduleError = null;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text('Data pierwszego terminu'),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 10),
                            selectableDayPredicate: supportsWeekday &&
                                    preferredWeekday != null
                                ? (day) => day.weekday == preferredWeekday
                                : null,
                          );
                          if (pickedDate == null) return;
                          setDialogState(() {
                            selectedDate = supportsWeekday && preferredWeekday != null
                                ? _alignDateToWeekday(pickedDate, preferredWeekday!)
                                : pickedDate;
                            scheduleError = null;
                          });
                        },
                        icon: const Icon(Icons.event),
                        label: Text(_formatDate(selectedDate)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Godzina terminu'),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: dialogContext,
                            initialTime: selectedTime,
                          );
                          if (pickedTime == null) return;
                          setDialogState(() {
                            selectedTime = pickedTime;
                            scheduleError = null;
                          });
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(_formatTimeOfDay(selectedTime)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Przypomnij wcześniej'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: remindBeforeMinutes,
                        items: _reminderOptionsMinutes
                            .map(
                              (minutes) => DropdownMenuItem<int>(
                                value: minutes,
                                child: Text(_remindBeforeLabel(minutes)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            remindBeforeMinutes = value;
                            scheduleError = null;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pierwszy termin: ${_formatDateTime(occurrenceAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (scheduleError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          scheduleError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                  onPressed: isCustomValid
                      ? () {
                          final firstOccurrenceAt =
                              _combineDateAndTime(selectedDate, selectedTime);
                          final reminderAt = firstOccurrenceAt.subtract(
                            Duration(minutes: remindBeforeMinutes),
                          );
                          if (!firstOccurrenceAt.isAfter(now)) {
                            setDialogState(() {
                              scheduleError =
                                  'Ustaw przyszłą datę i godzinę pierwszego terminu.';
                            });
                            return;
                          }
                          if (!reminderAt.isAfter(now)) {
                            setDialogState(() {
                              scheduleError =
                                  'Przypomnienie wypada w przeszłości. Zmień datę, godzinę lub offset.';
                            });
                            return;
                          }
                          if (intervalDays % 7 == 0 &&
                              preferredWeekday != null &&
                              selectedDate.weekday != preferredWeekday) {
                            setDialogState(() {
                              scheduleError =
                                  'Data musi odpowiadać wybranemu dniu tygodnia.';
                            });
                            return;
                          }
                          Navigator.of(dialogContext).pop(true);
                        }
                      : null,
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true) return;

    final title = selectedTemplateKey == _customRecurringAlertKey
        ? customTitle.trim()
        : (_recurringAlertTemplates[selectedTemplateKey] ?? '').trim();
    if (title.isEmpty) return;

    provider.addRecurringAlert(
      title: title,
      message: 'Przypomnienie cykliczne: $title',
      intervalDays: intervalDays,
      severity: AlertSeverity.warning,
      actionSuggestion: 'Wykonaj czynność i potwierdź realizację.',
      firstOccurrenceAt: _combineDateAndTime(selectedDate, selectedTime),
      remindBeforeMinutes: remindBeforeMinutes,
      preferredWeekday: intervalDays % 7 == 0 ? preferredWeekday : null,
    );

    final permissionGranted =
        await LocalNotificationsService.instance.requestPermissions();
    if (!mounted || permissionGranted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Alert zapisany, ale powiadomienia systemowe sa wylaczone. Wlacz je w ustawieniach telefonu.',
        ),
        duration: Duration(seconds: 5),
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

    final sortedFloors = unitsByFloor.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Od najwyższego

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 480 ? 2 : screenWidth < 900 ? 3 : 4;
    final childAspectRatio = screenWidth < 480 ? 1.0 : screenWidth < 900 ? 1.08 : 1.2;

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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
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
    final project = provider.currentProject;
    final assignedSubcontractors = project == null
        ? const <SubcontractorAssignment>[]
        : _subcontractorsForTarget(
            project,
            targetType: SubcontractorTargetType.unit,
            targetId: _unitTargetId(project, unit),
          );
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 480;

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
          padding: EdgeInsets.all(isCompact ? 8 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // ID mieszkania
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      provider.currentProject?.displayUnitId(unit) ?? unit.unitId,
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              if (assignedSubcontractors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: assignedSubcontractors
                        .map(
                          (subcontractor) => Chip(
                            label: Text(
                              subcontractor.companyName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: TextStyle(fontSize: isCompact ? 10 : 12),
                          ),
                        )
                        .toList(),
                  ),
                ),

              // Procent ukończenia
              Column(
                children: [
                  Text(
                    '${completion.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: completion >= 100 ? Colors.green : Colors.orange,
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 4),
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
                    Icon(Icons.camera_alt,
                        size: 14, color: Colors.blue.shade700),
                  if (hasPhotos && hasDefects) const SizedBox(width: 4),
                  if (hasDefects)
                    Icon(Icons.warning,
                        size: 14, color: Colors.orange.shade700),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectAreaTab(
    BuildContext context,
    ProjectManagerProvider provider, {
    required String title,
    required String emptyMessage,
    required Set<ProjectAreaType> types,
  }) {
    final project = provider.currentProject;
    if (project == null) {
      return const SizedBox.shrink();
    }

    final definitions = ProjectAreaCatalog.buildDefinitions(project)
        .where((item) => types.contains(item.type))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in,
                      size: 40, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title: ${definitions.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Każda pozycja ma zestaw informacji z generatora i osobną checklistę wykonania.',
                          style: TextStyle(
                            fontSize: 13,
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
          const SizedBox(height: 16),
          if (definitions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ...definitions.map(
              (definition) => _buildProjectAreaCard(
                context,
                provider,
                definition,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectAreaCard(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectAreaDefinition definition,
  ) {
    final progress = provider.getAreaProgress(definition.id);
    final completion = progress?.completionPercentage ?? 0.0;
    final completed = progress?.taskStatuses.values
            .where((status) => status == TaskStatus.completed)
            .length ??
        0;
    final total = definition.checklist.length;
    final hasPhotos = progress != null && progress.photoPaths.isNotEmpty;
    final hasNotes = progress != null && progress.notes.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectAreaDetailScreen(areaId: definition.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      definition.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (hasPhotos)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.camera_alt,
                          size: 16, color: Colors.blue.shade700),
                    ),
                  if (hasNotes)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.note_alt,
                          size: 16, color: Colors.orange.shade700),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                definition.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: total == 0 ? 0.0 : completed / total,
                backgroundColor: Colors.grey.shade300,
                color: completion >= 100 ? Colors.green : Colors.blue,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                'Checklista: $completed/$total · ${completion.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubcontractorsTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) {
      return const SizedBox.shrink();
    }

    final subcontractors = project.config.subcontractors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.groups_2, size: 40, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Podwykonawcy: ${subcontractors.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zakładka zbiera firmy oraz ich przypisania do budynków, klatek, pięter, lokali, pomieszczeń, systemów i OZE/EV.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openSubcontractorEditor(context, provider),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edytuj'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (subcontractors.isEmpty)
            const Text(
              'Brak podwykonawców w projekcie. Dodaj ich w konfiguracji projektu.',
            )
          else ...[
            ...subcontractors.map((subcontractor) {
              final linkLabels = project.config.subcontractorLinks
                  .where((link) => link.subcontractorId == subcontractor.id)
                  .map((link) => _resolveSubcontractorLinkLabel(project, link))
                  .where((label) => label.trim().isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subcontractor.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatSubcontractorAreas(subcontractor.areas),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (subcontractor.responsibilities.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Zakres: ${subcontractor.responsibilities}'),
                      ],
                      if (subcontractor.details.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subcontractor.details,
                          style: TextStyle(color: Colors.grey.shade800),
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
            const SizedBox(height: 12),
            _buildAssignmentOverviewSection(
              title: 'Budynki',
              onEdit: () => _openSubcontractorEditor(
                context,
                provider,
                initialStep: 5,
              ),
              entries: [
                for (var index = 0;
                    index < project.config.buildings.length;
                    index++)
                  (
                    label: project.config.buildings[index].buildingName,
                    subcontractors: _subcontractorsForTarget(
                      project,
                      targetType: SubcontractorTargetType.building,
                      targetId: 'building:$index',
                    ),
                  ),
              ],
            ),
            _buildAssignmentOverviewSection(
              title: 'Klatki',
              onEdit: () => _openSubcontractorEditor(
                context,
                provider,
                initialStep: 5,
              ),
              entries: [
                for (var buildingIndex = 0;
                    buildingIndex < project.config.buildings.length;
                    buildingIndex++)
                  for (final stairCase
                      in project.config.buildings[buildingIndex].stairCases)
                    if (_subcontractorsForTarget(
                      project,
                      targetType: SubcontractorTargetType.stairCase,
                      targetId:
                          'staircase:$buildingIndex:${stairCase.stairCaseName}',
                    ).isNotEmpty)
                      (
                        label:
                            '${project.config.buildings[buildingIndex].buildingName} • Klatka ${stairCase.stairCaseName}',
                        subcontractors: _subcontractorsForTarget(
                          project,
                          targetType: SubcontractorTargetType.stairCase,
                          targetId:
                              'staircase:$buildingIndex:${stairCase.stairCaseName}',
                        ),
                      ),
              ],
            ),
            _buildAssignmentOverviewSection(
              title: 'Piętra',
              onEdit: () => _openSubcontractorEditor(
                context,
                provider,
                initialStep: 5,
              ),
              entries: [
                for (var buildingIndex = 0;
                    buildingIndex < project.config.buildings.length;
                    buildingIndex++)
                  for (final stairCase
                      in project.config.buildings[buildingIndex].stairCases)
                    for (var floor = 1;
                        floor <= stairCase.numberOfLevels;
                        floor++)
                      if (_subcontractorsForTarget(
                        project,
                        targetType: SubcontractorTargetType.floor,
                        targetId:
                            'floor:$buildingIndex:${stairCase.stairCaseName}:$floor',
                      ).isNotEmpty)
                        (
                          label:
                              '${project.config.buildings[buildingIndex].buildingName} • Klatka ${stairCase.stairCaseName} • ${stairCase.getFloorName(floor)}',
                          subcontractors: _subcontractorsForTarget(
                            project,
                            targetType: SubcontractorTargetType.floor,
                            targetId:
                                'floor:$buildingIndex:${stairCase.stairCaseName}:$floor',
                          ),
                        ),
              ],
            ),
            _buildAssignmentOverviewSection(
              title: 'Lokale',
              onEdit: () => _openSubcontractorEditor(
                context,
                provider,
                initialStep: 5,
              ),
              entries: [
                for (final unit in project.units)
                  if (_subcontractorsForTarget(
                    project,
                    targetType: SubcontractorTargetType.unit,
                    targetId: _unitTargetId(project, unit),
                  ).isNotEmpty)
                    (
                      label:
                          'Lokal ${project.displayUnitId(unit)} • Klatka ${unit.stairCase} • Piętro ${unit.floor}',
                      subcontractors: _subcontractorsForTarget(
                        project,
                        targetType: SubcontractorTargetType.unit,
                        targetId: _unitTargetId(project, unit),
                      ),
                    ),
              ],
            ),
            _buildAssignmentOverviewSection(
              title: 'Pomieszczenia',
              onEdit: () => _openSubcontractorEditor(
                context,
                provider,
                initialStep: 6,
              ),
              entries: [
                for (final room in project.config.additionalRooms)
                  (
                    label: room.name,
                    subcontractors: _subcontractorsForTarget(
                      project,
                      targetType: SubcontractorTargetType.additionalRoom,
                      targetId: 'room:${room.id}',
                    ),
                  ),
              ],
            ),
            _buildAssignmentOverviewSection(
              title: 'Systemy',
              entries: [
                for (final system
                    in project.config.selectedSystems.toList()
                      ..sort((a, b) => a.name.compareTo(b.name)))
                  (
                    label: _subcontractorSystemLabel(system),
                    subcontractors: _subcontractorsForTarget(
                      project,
                      targetType: SubcontractorTargetType.system,
                      targetId: 'system:${system.name}',
                    ),
                  ),
              ],
            ),
            _buildAssignmentOverviewSection(
              title: 'OZE i EV',
              entries: [
                if (project
                        .config.renewableEnergyConfig?.photovoltaic.isEnabled ??
                    false)
                  (
                    label: 'Fotowoltaika (PV)',
                    subcontractors: _subcontractorsForTarget(
                      project,
                      targetType: SubcontractorTargetType.renewable,
                      targetId: 'renewable:pv',
                    ),
                  ),
                if (project.config.renewableEnergyConfig?.batteryStorage
                        .isEnabled ??
                    false)
                  (
                    label: 'Magazyn energii (BESS)',
                    subcontractors: _subcontractorsForTarget(
                      project,
                      targetType: SubcontractorTargetType.renewable,
                      targetId: 'renewable:bess',
                    ),
                  ),
                if (project.config.renewableEnergyConfig?.electricMobility
                        .isEnabled ??
                    false)
                  (
                    label: 'Ładowarki EV',
                    subcontractors: _subcontractorsForTarget(
                      project,
                      targetType: SubcontractorTargetType.ev,
                      targetId: 'ev:charging',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<SubcontractorAssignment> _directSubcontractorsForTarget(
    ConstructionProject project, {
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    final assignedIds = project.config.subcontractorLinks
        .where(
          (link) =>
              !link.blockInheritance &&
              link.targetType == targetType &&
              link.targetId == targetId,
        )
        .map((link) => link.subcontractorId)
        .toSet();

    return project.config.subcontractors
        .where((subcontractor) => assignedIds.contains(subcontractor.id))
        .toList()
      ..sort((a, b) => a.companyName.compareTo(b.companyName));
  }

  bool _isInheritanceBlockedForTarget(
    ConstructionProject project, {
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    return project.config.subcontractorLinks.any(
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
            targetId: 'building:$buildingIndex',
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
            targetId: 'staircase:$buildingIndex:$stairCaseName',
          ),
          (
            targetType: SubcontractorTargetType.building,
            targetId: 'building:$buildingIndex',
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
            targetId: 'floor:$buildingIndex:$stairCaseName:$floor',
          ),
          (
            targetType: SubcontractorTargetType.stairCase,
            targetId: 'staircase:$buildingIndex:$stairCaseName',
          ),
          (
            targetType: SubcontractorTargetType.building,
            targetId: 'building:$buildingIndex',
          ),
        ];
    }
  }

  List<SubcontractorAssignment> _subcontractorsForTarget(
    ConstructionProject project, {
    required SubcontractorTargetType targetType,
    required String targetId,
  }) {
    final chain = _subcontractorTargetFallbackChain(
      targetType: targetType,
      targetId: targetId,
    );
    for (final candidate in chain) {
      if (_isInheritanceBlockedForTarget(
        project,
        targetType: candidate.targetType,
        targetId: candidate.targetId,
      )) {
        return const <SubcontractorAssignment>[];
      }

      final subcontractors = _directSubcontractorsForTarget(
        project,
        targetType: candidate.targetType,
        targetId: candidate.targetId,
      );
      if (subcontractors.isNotEmpty) {
        return subcontractors;
      }
    }
    return const <SubcontractorAssignment>[];
  }

  String _unitTargetId(ConstructionProject project, ProjectUnit unit) {
    final match = RegExp(r'^B(\d+)-').firstMatch(unit.unitId);
    final buildingIndex = match == null
        ? 0
        : ((int.tryParse(match.group(1)!) ?? 1) - 1).clamp(0, 9999);

    if (buildingIndex >= 0 && buildingIndex < project.config.buildings.length) {
      final building = project.config.buildings[buildingIndex];
      for (final stairCase in building.stairCases) {
        for (var floor = 1; floor <= stairCase.numberOfLevels; floor++) {
          final constructionLabels = stairCase.getFloorUnitLabels(
              floor, UnitNamingScheme.construction);
          final targetLabels =
              stairCase.getFloorUnitLabels(floor, UnitNamingScheme.target);

          final constructionIndex =
              constructionLabels.indexOf(unit.constructionUnitId);
          if (constructionIndex >= 0) {
            return 'unit:$buildingIndex:${stairCase.stairCaseName}:$floor:$constructionIndex';
          }

          final targetIndex = targetLabels.indexOf(unit.targetUnitId);
          if (targetIndex >= 0) {
            return 'unit:$buildingIndex:${stairCase.stairCaseName}:$floor:$targetIndex';
          }
        }
      }
    }

    final unitPosition = _unitPositionFromUnitId(unit.unitId);
    return 'unit:$buildingIndex:${unit.stairCase}:${unit.floor}:$unitPosition';
  }

  int _unitPositionFromUnitId(String unitId) {
    final parts = unitId.split('-');
    final core = parts.length > 1 ? parts.last : unitId;
    if (core.length < 2) {
      return 0;
    }
    final numericPart = int.tryParse(core.substring(1));
    if (numericPart == null) {
      return 0;
    }
    final unitNumber = numericPart % 100;
    return unitNumber > 0 ? unitNumber - 1 : 0;
  }

  Widget _buildAssignmentOverviewSection({
    required String title,
    required List<
            ({String label, List<SubcontractorAssignment> subcontractors})>
        entries,
    VoidCallback? onEdit,
  }) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edytuj przypisania'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (entry.subcontractors.isEmpty)
                      Text(
                        'Brak przypisanych podwykonawców',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.subcontractors
                            .map(
                              (subcontractor) => Chip(
                                label: Text(subcontractor.companyName),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
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

  Future<void> _openSubcontractorEditor(
    BuildContext context,
    ProjectManagerProvider provider, {
    int initialStep = 2,
  }) async {
    if (provider.currentProject == null) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConfigurationWizardScreen(
          editMode: true,
          existingConfig: provider.currentProject?.config,
          initialStep: initialStep,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  String _formatSubcontractorAreas(Set<SubcontractorArea> areas) {
    if (areas.isEmpty) {
      return 'Brak przypisanych obszarów ogólnych';
    }

    final labels = areas.map((area) {
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
    }).toList()
      ..sort();

    return labels.join(' • ');
  }

  String _resolveSubcontractorLinkLabel(
    ConstructionProject project,
    SubcontractorLink link,
  ) {
    switch (link.targetType) {
      case SubcontractorTargetType.building:
        final index = int.tryParse(link.targetId.split(':').last);
        if (index == null ||
            index < 0 ||
            index >= project.config.buildings.length) {
          return 'Budynek';
        }
        return project.config.buildings[index].buildingName;
      case SubcontractorTargetType.stairCase:
        final stairCaseParts = link.targetId.split(':');
        if (stairCaseParts.length < 3) {
          return 'Klatka';
        }
        final buildingIndex = int.tryParse(stairCaseParts[1]);
        final stairCaseName = stairCaseParts[2];
        if (buildingIndex == null ||
            buildingIndex < 0 ||
            buildingIndex >= project.config.buildings.length) {
          return 'Klatka $stairCaseName';
        }
        return '${project.config.buildings[buildingIndex].buildingName} • Klatka $stairCaseName';
      case SubcontractorTargetType.floor:
        final floorParts = link.targetId.split(':');
        if (floorParts.length < 4) {
          return 'Piętro';
        }
        final buildingIndex = int.tryParse(floorParts[1]);
        final stairCaseName = floorParts[2];
        final floor = int.tryParse(floorParts[3]);
        if (buildingIndex == null ||
            floor == null ||
            buildingIndex < 0 ||
            buildingIndex >= project.config.buildings.length) {
          return 'Piętro';
        }
        final stairCase =
            project.config.buildings[buildingIndex].stairCases.where(
          (item) => item.stairCaseName == stairCaseName,
        );
        final floorLabel = stairCase.isEmpty
            ? 'Piętro $floor'
            : stairCase.first.getFloorName(floor);
        return '${project.config.buildings[buildingIndex].buildingName} • Klatka $stairCaseName • $floorLabel';
      case SubcontractorTargetType.unit:
        final matchedUnit = project.units.where(
          (unit) => _unitTargetId(project, unit) == link.targetId,
        );
        if (matchedUnit.isNotEmpty) {
          final unit = matchedUnit.first;
          return 'Lokal ${project.displayUnitId(unit)}';
        }
        return 'Lokal';
      case SubcontractorTargetType.additionalRoom:
        final roomId = link.targetId.split(':').last;
        final room =
            project.config.additionalRooms.where((item) => item.id == roomId);
        return room.isEmpty ? 'Pomieszczenie' : room.first.name;
      case SubcontractorTargetType.system:
        final systemName = link.targetId.split(':').last;
        final system = ElectricalSystemType.values.where(
          (item) => item.name == systemName,
        );
        return system.isEmpty
            ? 'System'
            : _subcontractorSystemLabel(system.first);
      case SubcontractorTargetType.renewable:
        final key = link.targetId.split(':').last;
        switch (key) {
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

  String _subcontractorSystemLabel(ElectricalSystemType system) {
    return system.displayName;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENEROWANIE WYKAZUO ZBIORCZEGO (PDF)
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
        final subcontractors = _subcontractorsForTarget(
          project,
          targetType: SubcontractorTargetType.unit,
          targetId: _unitTargetId(project, unit),
        );
        final subcontractorLabel = subcontractors.isEmpty
            ? '-'
            : subcontractors.map((s) => s.companyName).join(', ');

        final entry = <String, dynamic>{
          'nrLokalu': project.displayUnitId(unit),
          'podwykonawca': subcontractorLabel,
        };

        // Zmapuj statusy zadań
        for (int i = 0;
            i < stageNames.length && i < project.allTasks.length;
            i++) {
          final task = project.allTasks[i];
          final status = unit.taskStatuses[task.id] ?? TaskStatus.pending;
          entry[stageNames[i]] =
              status == TaskStatus.completed ? 'true' : 'false';
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
            content: Text(
                'Wykaz Zbiorczy dla projektu ${project.name} został wygenerowany!'),
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
        final subcontractors = _subcontractorsForTarget(
          project,
          targetType: SubcontractorTargetType.unit,
          targetId: _unitTargetId(project, unit),
        );
        final subcontractorLabel = subcontractors.isEmpty
            ? '-'
            : subcontractors.map((s) => s.companyName).join(', ');

        final entry = <String, dynamic>{
          'nrLokalu': project.displayUnitId(unit),
          'podwykonawca': subcontractorLabel,
        };

        for (int i = 0;
            i < stageNames.length && i < project.allTasks.length;
            i++) {
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
        final subcontractors = _subcontractorsForTarget(
          project,
          targetType: SubcontractorTargetType.unit,
          targetId: _unitTargetId(project, unit),
        );
        final subcontractorLabel = subcontractors.isEmpty
            ? '-'
            : subcontractors.map((s) => s.companyName).join(', ');

        final entry = <String, dynamic>{
          'nrLokalu': project.displayUnitId(unit),
          'podwykonawca': subcontractorLabel,
        };

        for (int i = 0;
            i < stageNames.length && i < project.allTasks.length;
            i++) {
          final task = project.allTasks[i];
          final status = task.status;
          entry[stageNames[i]] =
              status == TaskStatus.completed ? 'true' : 'false';
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
            content:
                Text('Wykaz Lokali (Excel) został wygenerowany i pobrany!'),
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
