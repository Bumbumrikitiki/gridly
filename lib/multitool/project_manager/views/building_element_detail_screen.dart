import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';

/// Ekran szczegółów obszaru budynku (pomieszczenie, klatka, winda, garaż, dach)
/// Struktura identyczna z UnitDetailScreen – 3 zakładki: Zadania, Zdjęcia, Notatki
class BuildingElementDetailScreen extends StatefulWidget {
  final String elementId;
  final String elementName;
  final BuildingAreaType areaType;

  const BuildingElementDetailScreen({
    super.key,
    required this.elementId,
    required this.elementName,
    required this.areaType,
  });

  @override
  State<BuildingElementDetailScreen> createState() =>
      _BuildingElementDetailScreenState();
}

class _BuildingElementDetailScreenState
    extends State<BuildingElementDetailScreen>
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
        final area =
            provider.getBuildingArea(widget.elementId, widget.areaType);
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.elementName),
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
              _buildTasksTab(context, provider, area),
              _buildPhotosTab(context, provider, area),
              _buildNotesTab(context, provider, area),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: ZADANIA / POSTĘP PRAC
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTasksTab(
    BuildContext context,
    ProjectManagerProvider provider,
    BuildingAreaProgress area,
  ) {
    final tasks = BuildingAreaProgress.defaultTasksFor(widget.areaType);
    final completion = area.completionPercent;
    final completedCount =
        tasks.where((t) => area.taskStatuses[t] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta postępu
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
                        '${completion.toStringAsFixed(0)}%',
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
                    value: completion / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: completion >= 100 ? Colors.green : Colors.blue,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ukończonych: $completedCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Wszystkich: ${tasks.length}',
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

          // Lista zadań z checkboxami
          ...tasks.map((taskName) {
            final isDone = area.taskStatuses[taskName] == true;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: CheckboxListTile(
                value: isDone,
                title: Text(
                  taskName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : null,
                  ),
                ),
                secondary: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone ? Colors.green : Colors.grey,
                ),
                onChanged: (value) {
                  provider.toggleBuildingAreaTask(
                    widget.elementId,
                    widget.areaType,
                    taskName,
                    value ?? false,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: ZDJĘCIA
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPhotosTab(
    BuildContext context,
    ProjectManagerProvider provider,
    BuildingAreaProgress area,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _addPhoto(context, provider),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Dodaj zdjęcie'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
          if (area.photoPaths.isEmpty)
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
              itemCount: area.photoPaths.length,
              itemBuilder: (context, index) {
                final photoPath = area.photoPaths[index];
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

  void _addPhoto(BuildContext context, ProjectManagerProvider provider) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final photoPath =
        '${widget.elementId}_photo_$timestamp.jpg';
    provider.addBuildingAreaPhoto(widget.elementId, widget.areaType, photoPath);
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

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: NOTATKI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNotesTab(
    BuildContext context,
    ProjectManagerProvider provider,
    BuildingAreaProgress area,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _addNote(context, provider),
            icon: const Icon(Icons.add_comment),
            label: const Text('Dodaj notatkę'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          if (area.notes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.note, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Brak notatek.\nDodaj notatkę przyciskiem powyżej.',
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
                        Icon(Icons.notes, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Notatki',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      area.notes,
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

  void _addNote(BuildContext context, ProjectManagerProvider provider) {
    final controller = TextEditingController();
    var showError = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dodaj notatkę'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Wpisz notatkę...',
              border: const OutlineInputBorder(),
              errorText: showError ? 'Uzupełnij treść notatki' : null,
            ),
            onChanged: (_) {
              if (showError) setDialogState(() => showError = false);
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
                provider.addBuildingAreaNote(
                    widget.elementId, widget.areaType, text);
                Navigator.of(context).pop();
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }
}
