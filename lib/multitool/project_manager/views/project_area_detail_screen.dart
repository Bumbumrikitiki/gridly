import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/logic/project_area_catalog.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';

class ProjectAreaDetailScreen extends StatefulWidget {
  final String areaId;

  const ProjectAreaDetailScreen({
    super.key,
    required this.areaId,
  });

  @override
  State<ProjectAreaDetailScreen> createState() => _ProjectAreaDetailScreenState();
}

class _ProjectAreaDetailScreenState extends State<ProjectAreaDetailScreen>
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
            body: const Center(child: Text('Projekt nie jest dostępny.')),
          );
        }

        final definitions = ProjectAreaCatalog.buildDefinitions(project);
        final matches = definitions.where((item) => item.id == widget.areaId).toList();
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Brak strefy')),
            body: const Center(child: Text('Nie znaleziono tej strefy projektu.')),
          );
        }

        final area = matches.first;
        final progress = provider.getAreaProgress(widget.areaId) ??
            ProjectAreaProgress(areaId: widget.areaId, areaType: area.type);

        return Scaffold(
          appBar: AppBar(
            title: Text(area.title),
            centerTitle: true,
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
              _buildTasksTab(context, provider, area, progress),
              _buildPhotosTab(context, provider, area, progress),
              _buildNotesTab(context, provider, area, progress),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksTab(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectAreaDefinition area,
    ProjectAreaProgress progress,
  ) {
    final completed = progress.taskStatuses.values
        .where((status) => status == TaskStatus.completed)
        .length;
    final total = area.checklist.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Postęp zakresu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${progress.completionPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: total == 0 ? 0.0 : completed / total,
                    backgroundColor: Colors.grey.shade300,
                    color: progress.completionPercentage >= 100
                        ? Colors.green
                        : Colors.blue,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ukończonych pozycji: $completed/$total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Informacje',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: area.infoItems
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.value,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Checklista prac',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...area.checklist.map(
            (item) => _TaskCard(
              item: item,
              status: progress.taskStatuses[item.id] ?? TaskStatus.pending,
              onStatusSelected: (status) => provider.updateAreaTaskStatus(
                area.id,
                item.id,
                status,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectAreaDefinition area,
    ProjectAreaProgress progress,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _addPhoto(context, provider, area),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Dodaj zdjęcie'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
          if (progress.photoPaths.isEmpty)
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
              itemCount: progress.photoPaths.length,
              itemBuilder: (context, index) {
                final photoPath = progress.photoPaths[index];
                return _buildPhotoCard(
                  context,
                  provider,
                  area.id,
                  index,
                  photoPath,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    ProjectManagerProvider provider,
    String areaId,
    int index,
    String photoPath,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () =>
                _showPhotoDialog(context, provider, areaId, index, photoPath),
            child: Container(
              color: Colors.grey.shade200,
              width: double.infinity,
              height: double.infinity,
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
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _confirmDeletePhoto(
                context,
                provider,
                areaId,
                index,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.delete,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectAreaDefinition area,
    ProjectAreaProgress progress,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _addAreaNote(context, provider, area),
            icon: const Icon(Icons.add_comment),
            label: const Text('Dodaj notatkę'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          if (progress.notes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.note, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Brak notatek.\nDodaj pierwszą notatkę przyciskiem powyżej.',
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
                    Row(
                      children: [
                        const Icon(Icons.note_alt, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Notatki obszaru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Edytuj notatki',
                          onPressed: () => _editAreaNotes(
                              context, provider, area, progress),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      progress.notes,
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

  void _addPhoto(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectAreaDefinition area,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final photoPath =
        'area_${area.type.name}_${area.id.replaceAll(':', '_')}_$timestamp.jpg';

    provider.addAreaPhoto(area.id, photoPath);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zdjęcie dodane (symulacja)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPhotoDialog(
    BuildContext context,
    ProjectManagerProvider provider,
    String areaId,
    int index,
    String photoPath,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Zdjęcie'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _confirmDeletePhoto(context, provider, areaId, index);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Usuń zdjęcie',
                      style: TextStyle(color: Colors.red),
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

  void _confirmDeletePhoto(
    BuildContext context,
    ProjectManagerProvider provider,
    String areaId,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń zdjęcie'),
        content: const Text('Czy na pewno chcesz usunąć to zdjęcie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.removeAreaPhoto(areaId, index);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Zdjęcie usunięte'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Usuń',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editAreaNotes(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectAreaDefinition area,
    ProjectAreaProgress progress,
  ) {
    final controller = TextEditingController(text: progress.notes);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edytuj notatki'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: _inputDecoration(
            hintText: 'Treść notatek...',
            helperText: 'Edytuj lub usuń treść notatek tej strefy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              provider.updateAreaNotes(area.id, '');
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Wyczyść',
                style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateAreaNotes(area.id, controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _addAreaNote(
    BuildContext context,
    ProjectManagerProvider provider,
    ProjectAreaDefinition area,
  ) {
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
            decoration: _inputDecoration(
              hintText: 'Opisz ustalenia, defekty lub uwagi...',
              helperText: 'Notatka zostanie zapisana dla tej strefy projektu',
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
                provider.addAreaNote(area.id, text);
                Navigator.of(context).pop();
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
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
}

class _TaskCard extends StatelessWidget {
  final ProjectAreaChecklistTemplate item;
  final TaskStatus status;
  final ValueChanged<TaskStatus> onStatusSelected;

  const _TaskCard({
    required this.item,
    required this.status,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
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
      case TaskStatus.attention:
        statusColor = Colors.deepOrange;
        statusIcon = Icons.priority_high;
        break;
      case TaskStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(item.title),
        subtitle: Text(item.description),
        trailing: PopupMenuButton<TaskStatus>(
          onSelected: onStatusSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: TaskStatus.pending,
              child: Text('Oczekujące'),
            ),
            PopupMenuItem(
              value: TaskStatus.inProgress,
              child: Text('W trakcie'),
            ),
            PopupMenuItem(
              value: TaskStatus.attention,
              child: Text('Wymaga uwagi'),
            ),
            PopupMenuItem(
              value: TaskStatus.blocked,
              child: Text('Zablokowane'),
            ),
            PopupMenuItem(
              value: TaskStatus.completed,
              child: Text('Ukończone'),
            ),
          ],
        ),
      ),
    );
  }
}
