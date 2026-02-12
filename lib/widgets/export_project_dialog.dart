import 'package:flutter/material.dart';
import 'package:gridly/services/export_service.dart';
import 'package:gridly/services/permission_manager.dart';
import 'package:gridly/services/technical_label_guard.dart';
import 'package:gridly/theme/grid_theme.dart';

class ExportProjectDialog extends StatefulWidget {
  final Map<String, dynamic> auditData;
  final Map<String, dynamic> calculatorData;
  final Map<String, dynamic> labelData;

  const ExportProjectDialog({
    super.key,
    required this.auditData,
    required this.calculatorData,
    required this.labelData,
  });

  @override
  State<ExportProjectDialog> createState() => _ExportProjectDialogState();
}

class _ExportProjectDialogState extends State<ExportProjectDialog> {
  late TextEditingController _projectNameController;
  bool _exportAudit = true;
  bool _exportCalculator = true;
  bool _exportLabels = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController(
      text:
          'Projekt_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}',
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  Future<void> _performExport() async {
    final projectName = TechnicalLabelGuard.normalize(_projectNameController.text);
    final validationMessage =
        TechnicalLabelGuard.validateTechnicalLabel(projectName);

    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage)),
      );
      return;
    }

    final confirmed = await _confirmExportAction();
    if (!confirmed || !mounted) {
      return;
    }

    // Request storage permission
    final hasStoragePermission =
        await PermissionManager.requestStoragePermission();
    if (!hasStoragePermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Dostęp do pamięci nie został przyznany. Eksport nie został wykonany.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final exportPath = await ExportService.exportProject(
        projectName: projectName,
        auditData: _exportAudit ? widget.auditData : {},
        calculatorData: _exportCalculator ? widget.calculatorData : {},
        labelData: _exportLabels ? widget.labelData : {},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Projekt zapisany w: $exportPath'),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<bool> _confirmExportAction() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Potwierdzenie eksportu'),
          content: const Text(
            'Potwierdź eksport danych. Zawartość ma charakter informacyjny i orientacyjny.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Potwierdź'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Eksportuj Projekt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _projectNameController,
              inputFormatters: TechnicalLabelGuard.inputFormatters(),
              decoration: const InputDecoration(
                labelText: 'Nazwa projektu',
                hintText: 'np. Projekt_02_2026',
                border: OutlineInputBorder(),
              ),
              enabled: !_isExporting,
            ),
            const SizedBox(height: 16),
            Text(
              'Wybierz dane do eksportu:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Dane audytu'),
              subtitle: const Text('Parametry pomiarów i wyniki'),
              value: _exportAudit,
              onChanged: _isExporting
                  ? null
                  : (bool? value) {
                      setState(() => _exportAudit = value ?? false);
                    },
            ),
            CheckboxListTile(
              title: const Text('Dane kalkulatorów'),
              subtitle: const Text('Výsledky, napięcia, impedancje'),
              value: _exportCalculator,
              onChanged: _isExporting
                  ? null
                  : (bool? value) {
                      setState(() => _exportCalculator = value ?? false);
                    },
            ),
            CheckboxListTile(
              title: const Text('Dane opisówek'),
              subtitle: const Text('Konfiguracja etykiet'),
              value: _exportLabels,
              onChanged: _isExporting
                  ? null
                  : (bool? value) {
                      setState(() => _exportLabels = value ?? false);
                    },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Projekt zostanie zapisany w folderze dokumentów',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _performExport,
          style: ElevatedButton.styleFrom(
            backgroundColor: GridTheme.electricYellow,
            foregroundColor: GridTheme.deepNavy,
          ),
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eksportuj'),
        ),
      ],
    );
  }
}

void showExportProjectDialog(
  BuildContext context, {
  required Map<String, dynamic> auditData,
  required Map<String, dynamic> calculatorData,
  required Map<String, dynamic> labelData,
}) {
  showDialog(
    context: context,
    builder: (context) => ExportProjectDialog(
      auditData: auditData,
      calculatorData: calculatorData,
      labelData: labelData,
    ),
  );
}
