import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/views/unit_detail_screen.dart';
import 'package:gridly/services/wykaz_zbiorczy_service.dart';
import 'package:gridly/services/excel_service.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:typed_data' show Uint8List;
import 'dart:html' as html;

/// Główny ekran szczegółów projektu z zakładkami
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtry dla mieszkań
  Set<String> selectedStairCases = {};
  bool showAlternateOnly = false;
  bool showNonAlternateOnly = false;
  bool showWithNotesOnly = false;
  String? selectedTaskFilter; // Filtr po konkretnym zadaniu

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

  /// Zwraca przefiltrowaną listę jednostek na podstawie aktywnych filtrów
  List<ProjectUnit> _getFilteredUnits(List<ProjectUnit> units) {
    List<ProjectUnit> filtered = units;

    // Filtr lokalizacji (klatka schodowa)
    if (selectedStairCases.isNotEmpty) {
      filtered = filtered.where((u) => selectedStairCases.contains(u.stairCase)).toList();
    }

    // Filtr lokali zamiennych
    if (showAlternateOnly) {
      filtered = filtered.where((u) => u.isAlternateUnit).toList();
    }

    // Filtr lokali bez zmian (non-alternate)
    if (showNonAlternateOnly) {
      filtered = filtered.where((u) => !u.isAlternateUnit).toList();
    }

    // Filtr z uwagami
    if (showWithNotesOnly) {
      filtered = filtered.where((u) => u.defectsNotes.isNotEmpty).toList();
    }

    // Filtr po konkretnym zadaniu
    if (selectedTaskFilter != null && selectedTaskFilter!.isNotEmpty) {
      filtered = filtered.where((u) {
        final taskStatus = u.taskStatuses[selectedTaskFilter];
        return taskStatus != null && taskStatus == TaskStatus.completed;
      }).toList();
    }

    return filtered;
  }

  /// Zwraca dostępne klaki schodowe z projektu
  List<String> _getAvailableStairCases(ConstructionProject project) {
    final stairCases = <String>{};
    for (final unit in project.units) {
      stairCases.add(unit.stairCase);
    }
    return stairCases.toList()..sort();
  }

  String _displayBuildingName(String rawName, {int? fallbackIndex}) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) {
      return fallbackIndex != null ? 'Budynek ${fallbackIndex + 1}' : 'Budynek';
    }

    final numeric = int.tryParse(trimmed);
    if (numeric != null) {
      return 'Budynek $numeric';
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectManagerProvider>(
      builder: (context, provider, _) {
        final project = provider.currentProject;
        
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Błąd')),
            body: const Center(child: Text('Brak załadowanego projektu')),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Zbiorczy Wykaz Lokali (PDF)',
                onPressed: () => _generateWykazZbiorczy(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.table_chart),
                tooltip: 'Zbiorczy Wykaz Lokali (Excel)',
                onPressed: () => _generateWykazExcel(context, provider),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.timeline), text: 'Harmonogram'),
                Tab(icon: Icon(Icons.list), text: 'Zadania'),
                Tab(icon: Icon(Icons.notifications), text: 'Alerty'),
                Tab(icon: Icon(Icons.apartment), text: 'Mieszkania'),
                Tab(icon: Icon(Icons.meeting_room), text: 'Pomieszczenia'),
                Tab(icon: Icon(Icons.apartment_outlined), text: 'Klatki'),
                Tab(icon: Icon(Icons.elevator), text: 'Dźwigi'),
                Tab(icon: Icon(Icons.local_parking), text: 'Garaż'),
                Tab(icon: Icon(Icons.home), text: 'Dach'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTimelineTab(context, provider),
              _buildChecklistTab(context, provider),
              _buildAlertsTab(context, provider),
              _buildUnitsTab(context, provider),
              _buildAdditionalRoomsTab(context, provider),
              _buildStaircasesTab(context, provider),
              _buildElevatorsTab(context, provider),
              _buildGarageTab(context, provider),
              _buildRoofTab(context, provider),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: LISTA ZADAŃ (CHECKLIST)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChecklistTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject!;

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

          // ZADANIA DLA AKTUALNEJ FAZY
          const Text(
            'Zadania dla bieżącej fazy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...project.allTasks
              .where((t) => t.status != TaskStatus.completed)
              .take(10)
              .map((task) => _buildTaskCard(context, provider, task))
              ,
        ],
      ),
    );
  }

  Widget _buildProgressCard(ConstructionProject project) {
    final progress = project.getProgress();
    final completed = project.allTasks.where((t) => t.status == TaskStatus.completed).length;
    final total = project.allTasks.length;

    return Card(
      elevation: 2,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ukończono $completed z $total zadań',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePhaseCard(ProjectPhase phase) {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phase.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              phase.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Tydzień ${phase.weekNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, ProjectManagerProvider provider, ChecklistTask task) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
      case TaskStatus.blocked:
        statusColor = Colors.orange;
        statusIcon = Icons.block;
        break;
      case TaskStatus.delayed:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(task.title),
        subtitle: Text(task.description),
        trailing: PopupMenuButton<TaskStatus>(
          icon: const Icon(Icons.more_vert),
          onSelected: (status) {
            provider.updateTaskStatus(task.id, status);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: TaskStatus.pending,
              child: Text('Oczekujące'),
            ),
            const PopupMenuItem(
              value: TaskStatus.inProgress,
              child: Text('W trakcie'),
            ),
            const PopupMenuItem(
              value: TaskStatus.completed,
              child: Text('Ukończone'),
            ),
            const PopupMenuItem(
              value: TaskStatus.blocked,
              child: Text('Zablokowane'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: HARMONOGRAM (CHECKLIST ETAPÓW)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTimelineTab(BuildContext context, ProjectManagerProvider provider) {
    final project = provider.currentProject!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harmonogram budowy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Checklist etapów
          ...project.phases.map((phase) {
            final isCompleted = phase.progress >= 1.0;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: isCompleted,
                onChanged: (value) {
                  // W przyszłości: zmienić status etapu
                },
                title: Text(
                  phase.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                            'Tydzień ${phase.weekNumber}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Podsumowanie postępu
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Postęp realizacji etapów',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Progress bar
                  LinearProgressIndicator(
                    value: project.getProgress(),
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blue,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  
                  // Tekst
                  Text(
                    '${(project.getProgress() * 100).toStringAsFixed(0)}% ukończone',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: ALERTY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAlertsTab(BuildContext context, ProjectManagerProvider provider) {
    final project = provider.currentProject!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Powiadomienia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (project.alerts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Brak alertów',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...project.alerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(ProjectAlert alert) {
    Color alertColor;
    IconData alertIcon;

    switch (alert.severity) {
      case AlertSeverity.critical:
      case AlertSeverity.urgent:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case AlertSeverity.warning:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(alertIcon, color: alertColor),
        title: Text(alert.title),
        subtitle: Text(alert.message),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: MIESZKANIA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUnitsTab(BuildContext context, ProjectManagerProvider provider) {
    final project = provider.currentProject!;
    final filteredUnits = _getFilteredUnits(project.units);
    final availableStairCases = _getAvailableStairCases(project);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lista mieszkań',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Pobierz raport Excel',
                    onPressed: () {
                      _generateUnitExcelReport(context, provider, project);
                    },
                  ),
                  IconButton(
                    tooltip: 'Szukaj mieszkania',
                    icon: const Icon(Icons.search),
                    onPressed: () => _showUnitSearchDialog(context, provider),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Panel filtrów
          _buildFiltersPanel(context, project, availableStairCases),
          const SizedBox(height: 16),
          // Informacja o liczbie wyfiltrowanych mieszkań
          Text(
            'Wyświetlane: ${filteredUnits.length}/${project.units.length} lokali',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          // Lista mieszkań
          if (filteredUnits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Brak lokali spełniających kryteria filtrów.\nWyczyść filtry lub zmień kryteria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...filteredUnits
                .map((unit) => _buildUnitRow(context, provider, unit))
                ,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Panel filtrów mieszkań
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFiltersPanel(
    BuildContext context,
    ConstructionProject project,
    List<String> availableStairCases,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (selectedStairCases.isNotEmpty ||
                  showAlternateOnly ||
                  showNonAlternateOnly ||
                  showWithNotesOnly ||
                  selectedTaskFilter != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedStairCases.clear();
                      showAlternateOnly = false;
                      showNonAlternateOnly = false;
                      showWithNotesOnly = false;
                      selectedTaskFilter = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Wyczyść filtry'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Filtr lokalizacji
          _buildLocationFilter(availableStairCases),
          const SizedBox(height: 12),
          // Filtr typu lokalu
          _buildUnitTypeFilter(),
          const SizedBox(height: 12),
          // Filtr z uwagami
          _buildNotesFilter(),
          const SizedBox(height: 12),
          // Filtr po zadaniu
          _buildTaskFilter(project),
        ],
      ),
    );
  }

  Widget _buildLocationFilter(List<String> stairCases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokalizacja (Klatka schodowa)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Opcja "Wszystkie"
            FilterChip(
              label: const Text('Wszystkie'),
              selected: selectedStairCases.isEmpty,
              onSelected: (selected) {
                setState(() {
                  if (selected) selectedStairCases.clear();
                });
              },
            ),
            // Poszczególne klaki
            ...stairCases.map((stairCase) {
              return FilterChip(
                label: Text(stairCase),
                selected: selectedStairCases.contains(stairCase),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedStairCases.add(stairCase);
                    } else {
                      selectedStairCases.remove(stairCase);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Typ lokalu',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Wszystkie'),
              selected: !showAlternateOnly && !showNonAlternateOnly,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    showAlternateOnly = false;
                    showNonAlternateOnly = false;
                  }
                });
              },
            ),
            FilterChip(
              label: const Text('Lokale zamienne'),
              selected: showAlternateOnly,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    showAlternateOnly = true;
                    showNonAlternateOnly = false;
                  } else {
                    showAlternateOnly = false;
                  }
                });
              },
            ),
            FilterChip(
              label: const Text('Lokale bez zmian'),
              selected: showNonAlternateOnly,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    showNonAlternateOnly = true;
                    showAlternateOnly = false;
                  } else {
                    showNonAlternateOnly = false;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesFilter() {
    return Row(
      children: [
        Checkbox(
          value: showWithNotesOnly,
          onChanged: (value) {
            setState(() {
              showWithNotesOnly = value ?? false;
            });
          },
        ),
        const Text('Tylko lokale z uwagami'),
      ],
    );
  }

  Widget _buildTaskFilter(ConstructionProject project) {
    // Filtruj zadania które są powiązane z mieszkaniami (unitIds != null)
    final taskList = project.allTasks
        .where((task) => task.unitIds != null && task.unitIds!.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtr po zadaniu',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButton<String?>(
          isExpanded: true,
          value: selectedTaskFilter,
          hint: const Text('Wybierz zadanie...'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Wszystkie (bez filtrowania po zadaniach)'),
            ),
            ...taskList.map((task) {
              return DropdownMenuItem<String>(
                value: task.id,
                child: Text(task.title),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              selectedTaskFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalRoomsTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject!;
    final rooms = project.config.additionalRooms;

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                tooltip: 'Szukaj pomieszczenia',
                icon: const Icon(Icons.search),
                onPressed: () => _showAdditionalRoomSearchDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rooms.isEmpty)
            Text(
              'Brak pomieszczeń dodatkowych.\nDodaj je w konfiguracji projektu.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...rooms.map((room) {
              final systemsCount = room.specificSystems.length;
              return _buildProgressRow(
                title: room.name,
                progress: systemsCount > 0 ? 1.0 : 0.0,
                subtitle: systemsCount == 0
                    ? _formatAdditionalRoomLocation(project, room)
                    : '${_formatAdditionalRoomLocation(project, room)} · Systemy: $systemsCount',
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAdditionalRoomSearchDialog(
    BuildContext context,
    ProjectManagerProvider provider,
  ) async {
    final rooms = provider.currentProject?.config.additionalRooms ?? [];
    final controller = TextEditingController();
    var results = rooms;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void updateResults(String value) {
              final query = value.trim().toLowerCase();
              setDialogState(() {
                if (query.isEmpty) {
                  results = rooms;
                } else {
                  results = rooms
                      .where(
                        (room) =>
                            room.name.toLowerCase().contains(query) ||
                            room.roomNumber.toLowerCase().contains(query),
                      )
                      .toList();
                }
              });
            }

            return AlertDialog(
              title: const Text('Wyszukaj pomieszczenie'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Wpisz nazwę pomieszczenia',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: updateResults,
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: results.isEmpty
                          ? const Center(child: Text('Brak wyników'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final room = results[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(room.name),
                                  subtitle: Text(
                                    _formatAdditionalRoomLocation(
                                      provider.currentProject!,
                                      room,
                                    ),
                                  ),
                                );
                              },
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
            );
          },
        );
      },
    );
  }

  String _formatAdditionalRoomLocation(
    ConstructionProject project,
    AdditionalRoom room,
  ) {
    final rawBuildingName = (room.buildingIndex >= 0 &&
            room.buildingIndex < project.config.buildings.length)
        ? project.config.buildings[room.buildingIndex].buildingName
        : '${room.buildingIndex + 1}';
    final buildingName = _displayBuildingName(
      rawBuildingName,
      fallbackIndex: room.buildingIndex,
    );
    final levelLabel = room.levelType == AdditionalRoomLevelType.nadziemna
        ? 'Nadziemna'
        : 'Podziemna';
    final stair = room.stairCaseName == null
        ? ''
        : ' · Klatka ${room.stairCaseName}';
    final number = room.roomNumber.trim().isEmpty
      ? ''
      : ' · Pom. ${room.roomNumber.trim()}';
    return '$buildingName$stair · $levelLabel ${room.floorNumber}$number';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5: KLATKI SCHODOWE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStaircasesTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject!;
    final stairCaseEntries = <Map<String, dynamic>>[];

    for (var buildingIndex = 0;
        buildingIndex < project.config.buildings.length;
        buildingIndex++) {
      final building = project.config.buildings[buildingIndex];
      for (final stairCase in building.stairCases) {
        final units = project.units
            .where((u) => u.stairCase == stairCase.stairCaseName)
            .toList();
        final labelPrefix = project.config.buildings.length > 1
          ? '${_displayBuildingName(building.buildingName, fallbackIndex: buildingIndex)} · '
            : '';
        stairCaseEntries.add({
          'label': '${labelPrefix}Klatka ${stairCase.stairCaseName}',
          'units': units,
          'elevators': stairCase.numberOfElevators,
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Klatki schodowe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (stairCaseEntries.isEmpty)
            Text(
              'Brak klatek schodowych.\nDodaj je w konfiguracji projektu.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...stairCaseEntries.map((entry) {
              final units = entry['units'] as List<ProjectUnit>;
              final progress = _calculateProgressForUnits(
                units,
                fallbackProgress: project.getProgress(),
              );
              final completed = _calculateCompletedForUnits(units);
              final total = _calculateTotalForUnits(units);
              return _buildProgressRow(
                title: entry['label'] as String,
                progress: progress,
                subtitle:
                    'Mieszkań: ${units.length} · Dźwigów: ${entry['elevators']} · $completed/$total',
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 6: DŹWIGI OSOBOWE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildElevatorsTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject!;
    final elevatorEntries = <String>[];

    for (final building in project.config.buildings) {
      for (final stairCase in building.stairCases) {
        for (var i = 0; i < stairCase.numberOfElevators; i++) {
          elevatorEntries.add('Klatka ${stairCase.stairCaseName} · Dźwig ${i + 1}');
        }
      }
    }

    final progress = project.getProgress();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dźwigi osobowe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (elevatorEntries.isEmpty)
            Text(
              'Brak dźwigów w projekcie.\nDodaj je w konfiguracji projektu.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...elevatorEntries.map((label) {
              return _buildProgressRow(
                title: label,
                progress: progress,
                subtitle: '${(progress * 100).toStringAsFixed(0)}% ukończenia',
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 7: GARAŻ
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGarageTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject!;
    final hasGarage = project.config.hasGarage || project.config.hasParking;

    final garageTasks = project.allTasks
        .where((task) => task.system == ElectricalSystemType.ladownarki)
        .toList();
    final progress = _calculateProgressForTasks(garageTasks);
    final completed =
        garageTasks.where((t) => t.status == TaskStatus.completed).length;
    final total = garageTasks.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Garaż',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (!hasGarage)
            Text(
              'Brak garażu w projekcie',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            _buildProgressRow(
              title: 'Garaż i parking',
              progress: progress,
              subtitle: total == 0
                  ? 'Brak zadań'
                  : 'Zadania: $completed/$total',
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 8: DACH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRoofTab(
    BuildContext context,
    ProjectManagerProvider provider,
  ) {
    final project = provider.currentProject!;
    final roofTasks = project.allTasks
        .where((task) =>
            task.system == ElectricalSystemType.panelePV ||
            task.system == ElectricalSystemType.odgromowa)
        .toList();
    final progress = _calculateProgressForTasks(roofTasks);
    final completed =
        roofTasks.where((t) => t.status == TaskStatus.completed).length;
    final total = roofTasks.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dach',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProgressRow(
            title: 'Prace dachowe',
            progress: progress,
            subtitle:
                total == 0 ? 'Brak zadań' : 'Zadania: $completed/$total',
          ),
        ],
      ),
    );
  }

  double _calculateProgressForTasks(List<ChecklistTask> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    return completed / tasks.length;
  }

  double _calculateProgressForUnits(
    List<ProjectUnit> units, {
    required double fallbackProgress,
  }) {
    final total = _calculateTotalForUnits(units);
    if (total == 0) return fallbackProgress;
    final completed = _calculateCompletedForUnits(units);
    return completed / total;
  }

  int _calculateTotalForUnits(List<ProjectUnit> units) {
    return units.fold<int>(0, (sum, unit) => sum + unit.taskStatuses.length);
  }

  int _calculateCompletedForUnits(List<ProjectUnit> units) {
    return units.fold<int>(
      0,
      (sum, unit) => sum +
          unit.taskStatuses.values
              .where((s) => s == TaskStatus.completed)
              .length,
    );
  }

  Widget _buildProgressRow({
    required String title,
    required double progress,
    required String subtitle,
  }) {
    final progressColor = progress >= 0.85
        ? Colors.green
        : progress >= 0.5
            ? Colors.orange
            : Colors.red;

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
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%'
                      .replaceAll('-0%', '0%'),
                  style: TextStyle(
                    fontSize: 12,
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitRow(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
  ) {
    final completedTasks = unit.taskStatuses.values
        .where((status) => status == TaskStatus.completed)
        .length;
    final totalTasks = unit.taskStatuses.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final progressColor = progress >= 0.85
        ? Colors.green
        : progress >= 0.5
            ? Colors.orange
            : Colors.red;

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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UnitDetailScreen(unit: unit),
            ),
          );
        },
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                unit.unitName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (unit.isAlternateUnit)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Zamienny',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'M. ${project.displayUnitId(unit)} · Piętro ${unit.floor} · Klatka ${unit.stairCase}',
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
                      if (value == 'rename') {
                        _showRenameUnitDialog(context, provider, unit);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'rename',
                        child: Text('Edytuj nazwę'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% ukończenia',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '$completedTasks/$totalTasks',
                    style: TextStyle(
                      fontSize: 12,
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameUnitDialog(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
  ) async {
    final controller = TextEditingController(text: unit.unitName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Zmień nazwę lokalu'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Wpisz nazwę lokalu',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    provider.updateUnitName(unit.unitId, newName.trim());
  }

  Future<void> _showUnitSearchDialog(
    BuildContext context,
    ProjectManagerProvider provider,
  ) async {
    final units = provider.currentProject?.units ?? [];
    final controller = TextEditingController();
    var results = units;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void updateResults(String value) {
              final query = value.trim().toLowerCase();
              setDialogState(() {
                if (query.isEmpty) {
                  results = units;
                } else {
                  results = units
                      .where(
                        (unit) => unit.matchesSearchQuery(query),
                      )
                      .toList();
                }
              });
            }

            return AlertDialog(
              title: const Text('Wyszukaj mieszkanie'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Wpisz nazwę lub numer lokalu',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: updateResults,
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: results.isEmpty
                          ? const Center(child: Text('Brak wyników'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final unit = results[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(unit.unitName),
                                  subtitle: Text(
                                    'M. ${project.displayUnitId(unit)} · Piętro ${unit.floor} · Klatka ${unit.stairCase}',
                                  ),
                                  trailing: unit.isAlternateUnit
                                      ? Icon(
                                          Icons.swap_horiz,
                                          size: 18,
                                          color: Colors.orange.shade700,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UnitDetailScreen(unit: unit),
                                      ),
                                    );
                                  },
                                );
                              },
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
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT: EXCEL I PDF
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _generateUnitExcelReport(
    BuildContext context,
    ProjectManagerProvider provider,
    ConstructionProject project,
  ) async {
    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Mieszkania'];
      
      // Przefiltrowani jednostki
      final filteredUnits = _getFilteredUnits(project.units);
      
      // Style dla komórek
      final borderAll = excel.Border(
        borderStyle: excel.BorderStyle.Medium,
        borderColorHex: '#000000',
      );
      
      final headerStyle = excel.CellStyle(
        backgroundColorHex: '#D3D3D3',
        fontColorHex: '#000000',
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
        textWrapping: excel.TextWrapping.WrapText,
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      
      final rotatedHeaderStyle = excel.CellStyle(
        backgroundColorHex: '#D3D3D3',
        fontColorHex: '#000000',
        bold: true,
        rotation: 90,
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Bottom,
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      
      final dataStyle = excel.CellStyle(
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      
      final titlesMetaStyle = excel.CellStyle(
        bold: true,
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      
      final metaValueStyle = excel.CellStyle(
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      
      final titleStyle = excel.CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: excel.HorizontalAlign.Center,
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      
      final logoStyle = excel.CellStyle(
        bold: true,
        fontSize: 24,
        fontColorHex: '#0066CC',
        horizontalAlign: excel.HorizontalAlign.Left,
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      
      int currentRow = 0;
      
      // Wiersz 1: Logo GRIDLY + Nagłówek główny
      var cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cell.value = 'GRIDLY';
      cell.cellStyle = logoStyle;
      
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
      cell.value = 'Wykaz lokali mieszkalnych';
      cell.cellStyle = titleStyle;
      currentRow++;
      
      // Wiersz 2: pusty
      currentRow++;
      
      // Wiersz 3: Nazwa budowy
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cell.value = 'Nazwa budowy:';
      cell.cellStyle = titlesMetaStyle;
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      cell.value = project.name;
      cell.cellStyle = metaValueStyle;
      currentRow++;
      
      // Wiersz 4: Data
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cell.value = 'Data:';
      cell.cellStyle = titlesMetaStyle;
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      cell.value = DateTime.now().toString().split(' ')[0];
      cell.cellStyle = metaValueStyle;
      currentRow++;
      
      // Wiersz 5: pusty
      currentRow++;
      
      // Wiersz 6: Metadane
      final metaInfo = filteredUnits.isNotEmpty
          ? 'Nr budynku:${project.config.buildings.isNotEmpty ? _displayBuildingName(project.config.buildings[0].buildingName, fallbackIndex: 0) : "xx"} / Nr klatki schodowej:${filteredUnits.first.stairCase} / Nr piętra:${filteredUnits.first.floor}'
          : 'Nr budynku:xx / Nr klatki schodowej:xx / Nr piętra:xx';
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cell.value = metaInfo;
      cell.cellStyle = excel.CellStyle(
        italic: true,
        fontSize: 10,
        leftBorder: borderAll,
        rightBorder: borderAll,
        topBorder: borderAll,
        bottomBorder: borderAll,
      );
      currentRow++;
      
      // Wiersz 7: Nagłówki kolumn
      final taskNames = [
        'Projekt zamienny',
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
      
      // Nagłówek "Nr lokalu"
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cell.value = 'Nr lokalu';
      cell.cellStyle = headerStyle;
      sheet.setColWidth(0, 15); // Szeroka kolumna dla nr lokalu
      
      // Nagłówek "Lokal zamienny"
      cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      cell.value = 'Lokal zamienny';
      cell.cellStyle = headerStyle;
      sheet.setColWidth(1, 10); // Średnia szerokość
      
      // Nagłówki zadań (obrócone o 90 stopni)
      for (int i = 0; i < taskNames.length; i++) {
        cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: currentRow));
        cell.value = taskNames[i];
        cell.cellStyle = rotatedHeaderStyle;
        sheet.setColWidth(i + 2, 5); // Wąskie kolumny dla obróconego tekstu
      }
      
      currentRow++;
      
      // Wiersze 8+: Dane jednostek
      for (final unit in filteredUnits) {
        // Nr lokalu
        cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        cell.value = project.displayUnitId(unit);
        cell.cellStyle = dataStyle;
        
        // Lokal zamienny
        cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
        cell.value = unit.isAlternateUnit ? 1 : 0;
        cell.cellStyle = dataStyle;
        
        // Status zadań (0 lub 1)
        int colIndex = 2;
        for (final task in project.allTasks) {
          final status = unit.taskStatuses[task.id] ?? TaskStatus.pending;
          cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRow));
          cell.value = status == TaskStatus.completed ? 1 : 0;
          cell.cellStyle = dataStyle;
          colIndex++;
        }
        
        currentRow++;
      }
      
      // Zapisz plik
      final bytes = excelFile.encode();
      if (bytes != null) {
        final fileName = 'Wykaz_lokali_${project.name}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        _saveAndOpenFile(context, Uint8List.fromList(bytes), fileName, 'Excel');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Błąd generowania Excel: $e');
    }
  }

  Future<void> _saveAndOpenFile(
    BuildContext context,
    dynamic bytes,
    String fileName,
    String fileType,
  ) async {
    try {
      // Konwertuj bytes do Uint8List jeśli potrzeba
      final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes as List<int>);
      
      // W wersji web, pobieramy plik
      _downloadFileWeb(uint8Bytes, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plik $fileType pobierany: $fileName'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Błąd przy pobieraniu pliku: $e');
    }
  }

  void _downloadFileWeb(Uint8List bytes, String fileName) {
    // Pobieranie pliku w wersji web
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = fileName;
      html.document.body?.append(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Błąd pobierania pliku: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENEROWANIE RAPORTÓW: PDF - WYKAZ ZBIORCZY
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generowanie Wykazuu Zbiorczego...'),
          duration: Duration(seconds: 2),
        ),
      );

      final currentDate = DateTime.now().toString().split(' ')[0];

      // Definicje etapów prac - IDENTYCZNE JAK W EXCEL
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
        'Sprzątanie',
        'Weryfikacja',
        'Odbiór końcowy',
      ];

      // Przygotuj dane do PDF
      final lokalEntries = <Map<String, dynamic>>[];

      // Zbuduj mapę: stage name -> task ID
      final stageNameToTaskId = <String, String>{};
      for (final task in project.allTasks) {
        for (final stageName in stageNames) {
          if (task.title.trim() == stageName.trim() || 
              task.title.contains(stageName.trim())) {
            stageNameToTaskId[stageName] = task.id;
            break;
          }
        }
      }

      for (final unit in project.units) {
        final entry = <String, dynamic>{'nrLokalu': project.displayUnitId(unit)};

        for (final stageName in stageNames) {
          // Znajdź ID tasku dla tego etapu
          final taskId = stageNameToTaskId[stageName];
          
          // Pobierz status z unit.taskStatuses
          final status = taskId != null && unit.taskStatuses.containsKey(taskId)
              ? (unit.taskStatuses[taskId] == TaskStatus.completed ? 'true' : 'false')
              : 'false';
          
          entry[stageName] = status;
        }

        lokalEntries.add(entry);
      }

      await WykazGenerator.generateWykazPdf(
        nazwaBudowy: project.name,
        data: currentDate,
        lokale: lokalEntries,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF Wykazuu Zbiorczego wygenerowany!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Błąd generowania PDF: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENEROWANIE RAPORTÓW: EXCEL - WYKAZ ZBIORCZY
  // ═══════════════════════════════════════════════════════════════════════════

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
          content: Text('Generowanie Wykazuu Zbiorczego (Excel)...'),
          duration: Duration(seconds: 2),
        ),
      );

      final currentDate = DateTime.now().toString().split(' ')[0];

      // Definicje etapów prac - IDENTYCZNE JAK W PDF
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
        'Sprzątanie',
        'Weryfikacja',
        'Odbiór końcowy',
      ];

      // Przygotuj dane do Excel
      final lokalEntries = <Map<String, dynamic>>[];

      // Zbuduj mapę: stage name -> task ID
      final stageNameToTaskId = <String, String>{};
      for (final task in project.allTasks) {
        for (final stageName in stageNames) {
          if (task.title.trim() == stageName.trim() || 
              task.title.contains(stageName.trim())) {
            stageNameToTaskId[stageName] = task.id;
            break;
          }
        }
      }

      for (final unit in project.units) {
        final entry = <String, dynamic>{'nrLokalu': project.displayUnitId(unit)};

        for (final stageName in stageNames) {
          // Znajdź ID tasku dla tego etapu
          final taskId = stageNameToTaskId[stageName];
          
          // Pobierz status z unit.taskStatuses
          final status = taskId != null && unit.taskStatuses.containsKey(taskId)
              ? (unit.taskStatuses[taskId] == TaskStatus.completed ? 'true' : 'false')
              : 'false';
          
          entry[stageName] = status;
        }

        lokalEntries.add(entry);
      }

      await ExcelService.exportWykazExcel(
        nazwaBudowy: project.name,
        data: currentDate,
        lokale: lokalEntries,
        stages: stageNames,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel Wykazuu Zbiorczego wygenerowany!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Błąd generowania Excel: $e');
    }
  }
}
