import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/project_manager/logic/project_manager_provider.dart';
import 'package:gridly/multitool/project_manager/views/project_manager_screen.dart';
import 'package:gridly/multitool/project_manager/views/configuration_wizard_screen.dart';

/// Ekran wyboru projektów - "Moja Budowa"
class ProjectSelectorScreen extends StatefulWidget {
  const ProjectSelectorScreen({super.key});

  @override
  State<ProjectSelectorScreen> createState() => _ProjectSelectorScreenState();
}

class _ProjectSelectorScreenState extends State<ProjectSelectorScreen> {
  @override
  void initState() {
    super.initState();
    // Załaduj zapisane projekty TYLKO jeśli jeszcze nie są załadowane
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProjectManagerProvider>();
      if (provider.allProjects.isEmpty) {
        provider.loadSavedProjects();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectManagerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Moja Budowa'),
            centerTitle: true,
            elevation: 0,
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.allProjects.isEmpty
                  ? _buildEmptyState(context, provider)
                  : _buildProjectList(context, provider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createNewProject(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Nowa Budowa'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ProjectManagerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Brak projektów',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stwórz swój pierwszy projekt budowy.\nKliknij zielony przycisk "Nowa Budowa" poniżej.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, ProjectManagerProvider provider) {
    final projects = provider.allProjects;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final progress = project.getProgress();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          child: InkWell(
            onTap: () => _openProject(context, provider, project.projectId),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              project.address.isEmpty ? 'Brak adresu' : project.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editProject(context, provider, project.projectId);
                          } else if (value == 'delete') {
                            _deleteProject(context, provider, project.projectId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edytuj parametry'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Usuń projekt', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.apartment, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${project.units.length} mieszkań',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${project.config.totalBuildingWeeks} tyg.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Postęp',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: progress > 0.7
                                  ? Colors.green
                                  : progress > 0.3
                                      ? Colors.orange
                                      : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(
                            progress > 0.7
                                ? Colors.green
                                : progress > 0.3
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Utworzono: ${_formatDate(project.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _createNewProject(BuildContext context, ProjectManagerProvider provider) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ConfigurationWizardScreen(editMode: false),
      ),
    );
    
    // Projekt już jest dodany i zapisany w providerze, nie trzeba ładować ponownie
    if (result == true && mounted) {
      setState(() {}); // Tylko odśwież UI
    }
  }

  Future<void> _openProject(BuildContext context, ProjectManagerProvider provider, String projectId) async {
    await provider.loadProject(projectId);
    
    if (!mounted) return;
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProjectManagerScreen(),
      ),
    );
    
    // Po powrocie odśwież listę
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editProject(BuildContext context, ProjectManagerProvider provider, String projectId) async {
    await provider.loadProject(projectId);
    
    if (!mounted) return;
    
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConfigurationWizardScreen(
          editMode: true,
          existingConfig: provider.currentProject?.config,
        ),
      ),
    );
    
    // Projekt już jest zaktualizowany w providerze
    if (result == true && mounted) {
      setState(() {}); // Tylko odśwież UI
    }
  }

  Future<void> _deleteProject(BuildContext context, ProjectManagerProvider provider, String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń projekt'),
        content: const Text('Czy na pewno chcesz usunąć ten projekt? Ta operacja jest nieodwracalna.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await provider.deleteProject(projectId);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projekt usunięty'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
