import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/models/building_hierarchy.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/views/unit_detail_screen.dart';
import 'package:gridly/multitool/project_manager/views/advanced_configuration_wizard.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'dart:html' as html;
import 'dart:typed_data';

class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({Key? key}) : super(key: key);

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filtry dla zakładki mieszkań
  Set<String> _selectedStairCases = {};
  String _unitTypeFilter = 'all'; // 'all', 'alternate', 'standard'
  bool _onlyWithNotes = false;
  String? _taskFilter; // ID zadania do filtrowania

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
                        Tab(icon: Icon(Icons.calendar_month), text: 'Harmonogram'),
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
                      _buildScheduleChecklistTab(context, provider),
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
    return AdvancedConfigurationWizard(
      onComplete: (config) async {
        try {
          print('[ProjectManager] Tworzenie projektu: ${config.projectName}');
          print('[ProjectManager] Systemy: ${config.selectedSystems.length}');
          print('[ProjectManager] Mieszkań: ${config.totalUnits}');
          
          // Stwórz nowy projekt
          await provider.createNewProjectAdvanced(config);
          
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: HARMONOGRAM BUDOWY (CHECKLIST ETAPÓW)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScheduleChecklistTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    // Dane harmonogramu budowy z dokumentu Word
    final schedulePhases = [
      {'name': 'Przygotowanie', 'percent': 5, 'weeks': '3-4', 'description': 'Projekty, harmonogram, zamówienia materiałów, pozwolenia'},
      {'name': 'Fundamenty', 'percent': 15, 'weeks': '9-12', 'description': 'Wykopy, dreny, stopy fundamentowe, pasy, izolacje'},
      {'name': 'Konstrukcja', 'percent': 20, 'weeks': '12-16', 'description': 'Słupy, belki, stropy żelbetowe, wznoszenie szkieletu budynku'},
      {'name': 'Przegrody', 'percent': 10, 'weeks': '6-8', 'description': 'Ścianki działowe, przebicia, kanały instalacyjne, okablowanie'},
      {'name': 'Tynki', 'percent': 10, 'weeks': '6-8', 'description': 'Tynki zewnętrzne i wewnętrzne, elewacja, ocieplenie'},
      {'name': 'Posadzki', 'percent': 10, 'weeks': '6-8', 'description': 'Wylewki, jastrych, izolacje, ogrzewanie podłogowe'},
      {'name': 'Osprzęt', 'percent': 15, 'weeks': '9-12', 'description': 'Gniazdka, włączniki, oprawy, tablice, okablowanie teletechniczne'},
      {'name': 'Malowanie', 'percent': 5, 'weeks': '3-4', 'description': 'Malowanie ścian i sufitów, lakierowanie'},
      {'name': 'Finalizacja', 'percent': 5, 'weeks': '3-4', 'description': 'Drzwi, parapety, montaż sanitariatów, meblościanki'},
      {'name': 'Oddawanie', 'percent': 5, 'weeks': '3-4', 'description': 'Pomiary, dokumentacja, odbiory, protokoły, przekazanie kluczy'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta z podsumowaniem
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 32, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harmonogram budowy',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Przewidywany czas: ${_calculateTotalWeeks(project.config)} tygodni',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar ogólny
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _calculateScheduleProgress(project),
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Postęp: ${(_calculateScheduleProgress(project) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Informacje o modyfikatorach czasu
          if (project.config.basementLevels > 0 || project.config.hasGarage) ...[
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getTimeModifierInfo(project.config),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Checklist etapów
          const Text(
            'Etapy budowy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...schedulePhases.asMap().entries.map((entry) {
            final index = entry.key;
            final phase = entry.value;
            final stageName = phase['name'] as String;
            final BuildingStage? stage = _mapNameToStage(stageName);
            
            // Sprawdź czy etap jest ukończony (szukamy w fazach projektu)
            final isCompleted = stage != null && 
              project.phases.any((p) => p.stage == stage && p.progress >= 1.0);
            
            final isCurrent = stage != null && project.activePhase?.stage == stage;

            return _buildSchedulePhaseCard(
              stageName: stageName,
              description: phase['description'] as String,
              percent: phase['percent'] as int,
              weeks: phase['weeks'] as String,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              phaseNumber: index + 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSchedulePhaseCard({
    required String stageName,
    required String description,
    required int percent,
    required String weeks,
    required bool isCompleted,
    required bool isCurrent,
    required int phaseNumber,
  }) {
    Color cardColor;
    IconData icon;
    
    if (isCompleted) {
      cardColor = Colors.green.shade50;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      cardColor = Colors.blue.shade50;
      icon = Icons.play_circle;
    } else {
      cardColor = Colors.grey.shade50;
      icon = Icons.circle_outlined;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isCompleted 
                    ? Colors.green 
                    : (isCurrent ? Colors.blue : Colors.grey),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$phaseNumber. $stageName',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCompleted || isCurrent 
                                ? Colors.black 
                                : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'W TRAKCIE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '$weeks tygodni',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percent% czasu',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BuildingStage? _mapNameToStage(String name) {
    switch (name) {
      case 'Przygotowanie': return BuildingStage.przygotowanie;
      case 'Fundamenty': return BuildingStage.fundamenty;
      case 'Konstrukcja': return BuildingStage.konstrukcja;
      case 'Przegrody': return BuildingStage.przegrody;
      case 'Tynki': return BuildingStage.tynki;
      case 'Posadzki': return BuildingStage.posadzki;
      case 'Osprzęt': return BuildingStage.osprzet;
      case 'Malowanie': return BuildingStage.malowanie;
      case 'Finalizacja': return BuildingStage.finalizacja;
      case 'Oddawanie': return BuildingStage.oddawanie;
      default: return null;
    }
  }

  int _calculateTotalWeeks(BuildingConfiguration config) {
    // Bazowy czas dla b udynków 5-8 kondygnacji: 18-24 miesiące
    int baseWeeks = 90; // ~21 miesięcy (średnia)
    
    // Dodatkowe tygodnie za każdą kondygnację powyżej 5
    if (config.totalLevels > 5) {
      baseWeeks += (config.totalLevels - 5) * 3;
    }
    
    // Dodatkowy czas za garaż podziemny
    if (config.basementLevels == 1 || config.hasGarage) {
      baseWeeks += 6; // +1.5 miesiąca
    } else if (config.basementLevels >= 2) {
      baseWeeks += 16; // +4 miesiące
    }
    
    return baseWeeks;
  }

  double _calculateScheduleProgress(ConstructionProject project) {
    final totalPhases = project.phases.length;
    if (totalPhases == 0) return 0.0;
    
    int completedPhases = project.phases.where((p) => p.progress >= 1.0).length;
    double currentPhaseProgress = project.activePhase?.progress ?? 0.0;
    
    return (completedPhases + currentPhaseProgress) / totalPhases;
  }

  String _getTimeModifierInfo(BuildingConfiguration config) {
    final modifiers = <String>[];
    
    if (config.totalLevels > 5) {
      modifiers.add('${config.totalLevels} kondygnacji (+${(config.totalLevels - 5) * 3} tyg.)');
    }
    
    if (config.basementLevels == 1 || config.hasGarage) {
      modifiers.add('Gara\u017c/piwnica 1-poz. (+6 tyg.)');
    } else if (config.basementLevels >= 2) {
      modifiers.add('Gara\u017c/piwnica 2-poz. (+16 tyg.)');
    }
    
    if (modifiers.isEmpty) {
      return 'Standardowy czas budowy bez modyfikatorów';
    }
    
    return 'Modyfikatory czasu: ${modifiers.join(", ")}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 (STARA): LISTA ZADAŃ (CHECKLIST) - ZACHOWANE DLA KOMPATYBILNOŚCI
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
  // TAB 4: MIESZKANIA / JEDNOSTKI - Z FILTROWANIEM I EKSPORTEM
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

    // Pobierz wszystkie unikalne klatki schodowe
    final allStairCases = project.units.map((u) => u.stairCase).toSet().toList()..sort();
    
    // Jeśli nie wybrano żadnych filtrów klatki, pokaż wszystkie
    if (_selectedStairCases.isEmpty) {
      _selectedStairCases = Set.from(allStairCases);
    }

    // Filtrowanie jednostek
    var filteredUnits = project.units.where((unit) {
      // Filtr po klatce
      if (!_selectedStairCases.contains(unit.stairCase)) return false;
      
      // Filtr po typie lokalu
      if (_unitTypeFilter == 'alternate' && !unit.isAlternateUnit) return false;
      if (_unitTypeFilter == 'standard' && unit.isAlternateUnit) return false;
      
      // Filtr po uwagach
      if (_onlyWithNotes && unit.defectsNotes.isEmpty) return false;
      
      // Filtr po zadaniu
      if (_taskFilter != null) {
        final taskStatus = unit.taskStatuses[_taskFilter];
        if (taskStatus != TaskStatus.completed) return false;
      }
      
      return true;
    }).toList();

    // Grupowanie po piętrach
    final unitsByFloor = <int, List<ProjectUnit>>{};
    for (final unit in filteredUnits) {
      unitsByFloor.putIfAbsent(unit.floor, () => []).add(unit);
    }
    final sortedFloors = unitsByFloor.keys.toList()..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel podsumowania + eksport
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.apartment, size: 40, color: Colors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wyświetlane: ${filteredUnits. length}/${project.units.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ukończonych: ${filteredUnits.where((u) => u.completionPercentage >= 100).length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Przyciski eksportu
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () => _showExportMenu(context, project, filteredUnits),
                        tooltip: 'Eksport wykazu mieszkań',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Panel filtrów
          Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Filtr klatek schodowych
                  const Text('Klatka schodowa:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: allStairCases.map((stairCase) {
                      final isSelected = _selectedStairCases.contains(stairCase);
                      return FilterChip(
                        label: Text('Klatka $stairCase'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStairCases.add(stairCase);
                            } else {
                              _selectedStairCases.remove(stairCase);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Filtr typu lokalu
                  const Text('Typ lokalu:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Wszystkie'),
                        selected: _unitTypeFilter == 'all',
                        onSelected: (_) => setState(() => _unitTypeFilter = 'all'),
                      ),
                      ChoiceChip(
                        label: const Text('Lokale zamienne'),
                        selected: _unitTypeFilter == 'alternate',
                        onSelected: (_) => setState(() => _unitTypeFilter = 'alternate'),
                      ),
                      ChoiceChip(
                        label: const Text('Lokale bez zmian'),
                        selected: _unitTypeFilter == 'standard',
                        onSelected: (_) => setState(() => _unitTypeFilter = 'standard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filtr uwag
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tylko lokale z uwagami'),
                    value: _onlyWithNotes,
                    onChanged: (value) => setState(() => _onlyWithNotes = value ?? false),
                  ),
                  const SizedBox(height: 8),

                  // Filtr zadania
                  Row(
                    children: [
                      const Text('Zadanie ukończone:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String?>(
                          value: _taskFilter,
                          isExpanded: true,
                          hint: const Text('Wszystkie'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Wszystkie'),
                            ),
                            ...project.allTasks.take(10).map((task) {
                              return DropdownMenuItem<String>(
                                value: task.id,
                                child: Text(task.title, overflow: TextOverflow.ellipsis),
                              );
                            }),
                          ],
                          onChanged: (value) => setState(() => _taskFilter = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Przycisk czyszczenia filtrów
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Wyczyść filtry'),
                      onPressed: () {
                        setState(() {
                          _selectedStairCases = Set.from(allStairCases);
                          _unitTypeFilter = 'all';
                          _onlyWithNotes = false;
                          _taskFilter = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lista mieszkań
          if (filteredUnits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Brak lokali spełniających kryteria',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  void _showExportMenu(BuildContext context, ConstructionProject project, List<ProjectUnit> filteredUnits) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Pobierz Excel'),
            subtitle: Text('${filteredUnits.length} lokali'),
            onTap: () {
              Navigator.pop(context);
              _generateExcelReport(project, filteredUnits);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Pobierz PDF'),
            subtitle: const Text('W przygotowaniu'),
            enabled: false,
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement PDF export
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateExcelReport(ConstructionProject project, List<ProjectUnit> units) async {
    try {
      // Stwórz workbook
      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel['Wykaz lokali mieszkalnych'];
      
      // Usuń domyślny worksheet
      excel.delete('Sheet1');

      // Nagłówek - wiersz 1
      sheet.merge(excel_pkg.CellIndex.indexByString('A1'), excel_pkg.CellIndex.indexByString('AD1'));
      final titleCell = sheet.cell(excel_pkg.CellIndex.indexByString('A1'));
      titleCell.value = excel_pkg.TextCellValue('Wykaz lokali mieszkalnych');
      titleCell.cellStyle = excel_pkg.CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
      );

      // Nazwa budowy - wiersz 3
      final projectNameCell = sheet.cell(excel_pkg.CellIndex.indexByString('A3'));
      projectNameCell.value = excel_pkg.TextCellValue('Nazwa budowy: ${project.config.projectName}');
      projectNameCell.cellStyle = excel_pkg.CellStyle(bold: true);

      // Data - wiersz 4
      final dateCell = sheet.cell(excel_pkg.CellIndex.indexByString('A4'));
      dateCell.value = excel_pkg.TextCellValue('Data: ${DateTime.now().toString().split(' ')[0]}');
      dateCell.cellStyle = excel_pkg.CellStyle(italic: true);

      // Metadane - wiersz 6
      sheet.merge(excel_pkg.CellIndex.indexByString('A6'), excel_pkg.CellIndex.indexByString('AD6'));
      final metaCell = sheet.cell(excel_pkg.CellIndex.indexByString('A6'));
      metaCell.value = excel_pkg.TextCellValue('Nr budynku / klatka / piętro');
      metaCell.cellStyle = excel_pkg.CellStyle(
        italic: true,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
      );

      // Nagłówki kolumn - wiersz 7
      final headerStyle = excel_pkg.CellStyle(
        bold: true,
        backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#D3D3D3'),
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      // Kolumna A: Nr lokalu
      final colA = sheet.cell(excel_pkg.CellIndex.indexByString('A7'));
      colA.value = excel_pkg.TextCellValue('Nr lokalu');
      colA.cellStyle = headerStyle;

      // Kolumna B: Lokal zamienny
      final colB = sheet.cell(excel_pkg.CellIndex.indexByString('B7'));
      colB.value = excel_pkg.TextCellValue('Lokal zamienny');
      colB.cellStyle = headerStyle;

      // Kolumny C-AD: 28 zadań (bez "Projekt zamienny" - to jest warunkowe)
      final taskTitles = [
        'Ścianki działowe:',
        'Montaż okablowania:',
        'Montaż okablowania na balkonie, loggy, ogródku:',
        'Montaż puszek elektroinstalacyjnych:',
        'Dokumentacja fotograficzna okablowania:',
        'Doprowadzenie kabla WLZ:',
        'Odbiory inspektora nadzoru inwestorskiego:',
        'Tynki:',
        'Wykonanie pomiaru Riso:',
        'Ułożenie rur osłonowych pod instalacje teletechniczną:',
        'Dokumentacja fotograficzna rur osłonowych:',
        'Jastrych (wylewka):',
        'Doprowadzenie okablowania teletechnicznego w rurach:',
        'Malowanie:',
        'Montaż tablicy mieszkaniowej elektrycznej - TM:',
        'Podłączenie tablicy mieszkaniowej:',
        'Montaż teletechnicznej skrzynki mieszkaniowej - TSM:',
        'Montaż osprzętu:',
        'Montaż unifonu, wideodomofonu:',
        'Montaż czujnika dymu:',
        'Montaż oprawek oświetleniowych:',
        'Uruchomienie instalacji domofonowej:',
        'Pomiary teletechniczne:',
        'Pomiary elektryczne:',
        'Odbiory inspektora nadzoru inwestorskiego I termin:',
        'Odbiory inspektora nadzoru inwestorskiego II termin:',
        'Odbiory inspektora nadzoru inwestorskiego końcowe:',
      ];

      for (int i = 0; i < taskTitles.length; i++) {
        final colIndex = String.fromCharCode(67 + i); // C=67, D=68, etc.
        final cell = sheet.cell(excel_pkg.CellIndex.indexByString('$colIndex'  + '7'));
        cell.value = excel_pkg.TextCellValue(taskTitles[i]);
        cell.cellStyle = headerStyle;
      }

      // Dane mieszkań - zaczynając od wiersza 8
      for (int i = 0; i < units.length; i++) {
        final unit = units[i];
        final rowIndex = 8 + i;

        // Nr lokalu
        sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = excel_pkg.TextCellValue(unit.unitId);

        // Lokal zamienny (0/1)
        sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = excel_pkg.IntCellValue(unit.isAlternateUnit ? 1 : 0);

        // Zadania (0/1)
        final unitTasks = project.allTasks.where((t) => 
          t.unitIds != null && t.unitIds!.contains(unit.unitId)
        ).toList();

        for (int j = 0; j < taskTitles.length && j < unitTasks.length; j++) {
          final task = unitTasks[j];
          final status = unit.taskStatuses[task.id] ?? TaskStatus.pending;
          final isCompleted = status == TaskStatus.completed ? 1 : 0;
          
          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 2 + j, rowIndex: rowIndex))
            .value = excel_pkg.IntCellValue(isCompleted);
        }
      }

      // Szerokości kolumn są ustawiane automatycznie przez pakiet excel
      // W przyszłości można dodać ręczne ustawienie jeśli pakiet to wspiera

      // Zapisz plik
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Nie udało się wygenerować pliku Excel');
      }

      // Pobierz plik (Web)
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Wykaz_lokali_mieszkalnych.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plik Excel został pobrany'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd generowania pliku: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              // ID mieszkania + badge zamienny
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
                  if (unit.isAlternateUnit) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Z',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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

