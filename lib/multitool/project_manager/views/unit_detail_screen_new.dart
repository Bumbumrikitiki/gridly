import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/services/karta_single_service.dart';

/// Ekran szczegółów jednostki/mieszkania z checklistą i galerią zdjęć
class UnitDetailScreen extends StatefulWidget {
  final ProjectUnit unit;

  const UnitDetailScreen({
    super.key,
    required this.unit,
  });

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
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Drukuj kartę lokalową',
                onPressed: () => _generateUnitCard(context, provider, currentUnit, project),
              ),
            ],
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
      if (task.id == kAlternateProjectTaskId && !unit.isAlternateUnit) {
        return false;
      }
      return task.unitIds == null || task.unitIds!.contains(unit.unitId);
    }).toList();

    if (allTasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Brak zadań przypisanych do tego lokalu.\nDodaj je w konfiguracji projektu.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Lokal zamienny'),
              subtitle: const Text('Włącza zadanie "Projekt zamienny" tylko dla tego lokalu'),
              value: unit.isAlternateUnit,
              onChanged: (value) {
                provider.updateUnitAlternateStatus(unit.unitId, value);
              },
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),

          // Lista zadań sekwencyjnie bez grupowania
          ...allTasks.map((task) {
            final status = task.status;
            return _buildTaskCard(context, provider, unit, task, status);
          }),
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
                      'Brak zdjęć.\nDodaj pierwsze zdjęcie przyciskiem powyżej.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
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
                      'Brak notatek.\nDodaj notatkę defektu przyciskiem powyżej.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
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
    var showError = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dodaj notatkę defektu'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: _inputDecoration(
              hintText: 'Opisz defekt lub dodaj notatkę...',
              helperText: 'Dodaj lokalizację i krótki opis problemu',
              errorText: showError ? 'Uzupełnij treść notatki' : null,
            ),
            onChanged: (_) {
              if (showError) {
                setDialogState(() => showError = false);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setDialogState(() => showError = true);
                  return;
                }
                provider.addUnitDefectNote(unit.unitId, text);
                Navigator.of(context).pop();
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERY
  // ═══════════════════════════════════════════════════════════════════════════

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

  InputDecoration _inputDecoration({
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENEROWANIE KARTY LOKALOWEJ (PDF)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _generateUnitCard(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectUnit unit,
    ConstructionProject project,
  ) async {
    try {
      // Pokaż loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generowanie Karty Lokalowej...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Pobierz nazwy budynków i dane projektu
      final buildingName = project.config.buildings.isNotEmpty 
          ? project.config.buildings[0].buildingName 
          : 'Budynek xx';
      
      final currentDate = DateTime.now().toString().split(' ')[0];

      // Zmapuj statusy zadań na mapę postepyPrac
      final postepyPrac = <String, String>{};
      
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
      
      String normalizeStageKey(String input) {
        final normalized = input
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9ąćęłńóśźż ]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        return normalized;
      }

      ChecklistTask? findTaskForStage(String stageName) {
        final stageKey = normalizeStageKey(stageName);
        final hasBalkonyKeyword = stageKey.contains('balkony');
        
        // Najpierw szukaj dokładnego dopasowania z context'em (balkony/balkon)
        for (final task in project.allTasks) {
          final titleKey = normalizeStageKey(task.title);
          
          // Jeśli stage jest o balkonie, szukaj tasku z balkonie w tytule
          if (hasBalkonyKeyword && titleKey.contains('balkon')) {
            return task;
          }
          
          // Jeśli stage nie ma balkony, sprawdzaj czy title nie zawiera balkon
          if (!hasBalkonyKeyword && !titleKey.contains('balkon') && titleKey.startsWith(stageKey)) {
            return task;
          }
        }
        // Fallback: zwykłe dopasowanie startsWith
        for (final task in project.allTasks) {
          final titleKey = normalizeStageKey(task.title);
          if (titleKey.startsWith(stageKey)) {
            return task;
          }
        }
        return null;
      }

      for (final stageName in stageNames) {
        final task = findTaskForStage(stageName);
        final status = task != null ? task.status : TaskStatus.pending;
        postepyPrac[stageName] = status == TaskStatus.completed ? 'true' : 'false';
      }

      // Wywołaj serwis generowania PDF
      await KartaSingleGenerator.generateSinglePdf(
        nazwaBudowy: project.name,
        data: currentDate,
        nrLokalu: unit.unitId,
        nrBudynku: buildingName,
        klatka: unit.stairCase,
        pietro: unit.floor.toString(),
        podwykonawca: '', // Możesz dodać pole w modelu jeśli chcesz
        postepyPrac: postepyPrac,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Karta lokalowa dla lokalu ${unit.unitId} została wygenerowana!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd generowania Karty Lokalowej: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
