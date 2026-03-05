import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';

/// Ekran szczegółów jednostki/mieszkania z checklistą i galerią zdjęć
class UnitDetailScreen extends StatefulWidget {
  final ProjectUnit unit;

  const UnitDetailScreen({
    Key? key,
    required this.unit,
  }) : super(key: key);

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        final project = provider.currentProject;
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Brak projektu')),
            body: const Center(child: Text('Projekt nie znaleziony')),
          );
        }

        // Znajdź aktualną wersję jednostki z providera
        final currentUnit = project.units.firstWhere(
          (u) => u.unitId == widget.unit.unitId,
          orElse: () => widget.unit,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Lokal ${currentUnit.unitId}'),
            centerTitle: true,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.checklist), text: 'Zadania'),
                Tab(icon: Icon(Icons.photo_library), text: 'Zdjęcia'),
                Tab(icon: Icon(Icons.note), text: 'Notatki'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTasksTab(context, provider, currentUnit, project),
              _buildPhotosTab(context, provider, currentUnit),
              _buildNotesTab(context, provider, currentUnit),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: ZADANIA (CHECKLIST)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTasksTab(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
    ConstructionProject project,
  ) {
    // Pobierz wszystkie zadania dla tego lokalu
    final allTasks = project.allTasks.where((task) {
      // Zadania bez unitIds (ogólne) ORAZ zadania przypisane do tego mieszkania
      return task.unitIds == null || task.unitIds!.contains(unit.unitId);
    }).toList();

    if (allTasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Brak zadań przypisanych do tego lokalu',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Pogrupuj zadania po etapach
    final tasksByStage = <BuildingStage, List<ChecklistTask>>{};
    for (final task in allTasks) {
      tasksByStage.putIfAbsent(task.stage, () => []).add(task);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta z postępem
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Postęp realizacji',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${unit.completionPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: unit.completionPercentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: unit.completionPercentage >= 100
                        ? Colors.green
                        : Colors.blue,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ukończonych: ${unit.taskStatuses.values.where((s) => s == TaskStatus.completed).length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Wszystkich: ${allTasks.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Przełącznik lokalu zamiennego
          Card(
            color: unit.isAlternateUnit ? Colors.orange.shade50 : Colors.grey.shade50,
            child: SwitchListTile(
              title: const Text(
                'Lokal zamienny',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                unit.isAlternateUnit 
                  ? 'Ten lokal wymaga projektu zamiennego' 
                  : 'Standardowy lokal bez zmian',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              value: unit.isAlternateUnit,
              onChanged: (value) {
                provider.toggleUnitAlternateStatus(unit.unitId);
              },
              secondary: Icon(
                unit.isAlternateUnit ? Icons.swap_horiz : Icons.home,
                color: unit.isAlternateUnit ? Colors.orange : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lista zadań pogrupowanych po etapach
          ...tasksByStage.entries.map((entry) {
            final stage = entry.key;
            final tasks = entry.value;
            final stageName = _getStageName(stage);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    stageName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...tasks.map((task) {
                  final status = unit.taskStatuses[task.id] ?? TaskStatus.pending;
                  return _buildTaskCard(context, provider, unit, task, status);
                }).toList(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
    ChecklistTask task,
    TaskStatus status,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case TaskStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
      case TaskStatus.blocked:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      case TaskStatus.delayed:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case TaskStatus.pending:
      case TaskStatus.attention:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showStatusDialog(context, provider, unit, task, status),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
    ChecklistTask task,
    TaskStatus currentStatus,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmień status zadania'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) {
            return RadioListTile<TaskStatus>(
              title: Text(_getStatusLabel(status)),
              value: status,
              groupValue: currentStatus,
              onChanged: (newStatus) {
                if (newStatus != null) {
                  provider.updateUnitTaskStatus(
                    unit.unitId,
                    task.id,
                    newStatus,
                  );
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: ZDJĘCIA (GALERIA)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPhotosTab(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Przycisk dodawania zdjęcia
          ElevatedButton.icon(
            onPressed: () => _addPhoto(context, provider, unit),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Dodaj zdjęcie'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),

          // Galeria zdjęć
          if (unit.photoPaths.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.photo_library, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Brak zdjęć',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: unit.photoPaths.length,
              itemBuilder: (context, index) {
                final photoPath = unit.photoPaths[index];
                return _buildPhotoCard(context, photoPath);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, String photoPath) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPhotoDialog(context, photoPath),
        child: Container(
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  photoPath.split('/').last,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPhoto(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
  ) {
    // Symulacja dodawania zdjęcia (w produkcji: image_picker)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final photoPath = 'unit_${unit.unitId}_photo_$timestamp.jpg';
    
    provider.addUnitPhoto(unit.unitId, photoPath);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zdjęcie dodane (symulacja)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String photoPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Zdjęcie'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo, size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    photoPath,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: NOTATKI I DEFEKTY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNotesTab(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Przycisk dodawania notatki
          ElevatedButton.icon(
            onPressed: () => _addDefectNote(context, provider, unit),
            icon: const Icon(Icons.add_comment),
            label: const Text('Dodaj notatkę defektu'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),

          // Lista notatek
          if (unit.defectsNotes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.note, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Brak notatek',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Defekty i notatki',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      unit.defectsNotes,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addDefectNote(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj notatkę defektu'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Opisz defekt lub dodaj notatkę...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addUnitDefectNote(unit.unitId, controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERY
  // ═══════════════════════════════════════════════════════════════════════════

  String _getStageName(BuildingStage stage) {
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
        return '☀️ Instalacje OZE';
      case BuildingStage.evInfrastruktura:
        return '🔌 Infrastruktura EV';
    }
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Oczekujące';
      case TaskStatus.inProgress:
        return 'W trakcie';
      case TaskStatus.completed:
        return 'Ukończone';
      case TaskStatus.blocked:
        return 'Zablokowane';
      case TaskStatus.delayed:
        return 'Opóźnione';
      case TaskStatus.attention:
        return 'Wymaga uwagi';
    }
  }
}
