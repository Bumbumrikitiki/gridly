import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<String> exportProject({
    required String projectName,
    required Map<String, dynamic> auditData,
    required Map<String, dynamic> calculatorData,
    required Map<String, dynamic> labelData,
  }) async {
    try {
      // Get the documents directory
      final Directory appDocsDir = await getApplicationDocumentsDirectory();
      final String projectDir =
          '${appDocsDir.path}/Gridly_Electrical_Checker_Export/${projectName}_${DateTime.now().millisecondsSinceEpoch}';

      // Create project directory
      final Directory newDir = await Directory(projectDir).create(recursive: true);

      // Create project metadata
      final projectMetadata = {
        'projectName': projectName,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'appVersion': '1.0.0',
      };

      // Save metadata
      final metadataFile = File('${newDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(projectMetadata));

      // Save circuit assessment data
      if (auditData.isNotEmpty) {
        final circuitAssessmentFile =
            File('${newDir.path}/circuit_assessment_data.json');
        await circuitAssessmentFile.writeAsString(jsonEncode(auditData));

        // Legacy compatibility for older integrations
        final legacyAuditFile = File('${newDir.path}/audit_data.json');
        await legacyAuditFile.writeAsString(jsonEncode(auditData));
      }

      // Save calculator data
      if (calculatorData.isNotEmpty) {
        final calcFile = File('${newDir.path}/calculator_data.json');
        await calcFile.writeAsString(jsonEncode(calculatorData));
      }

      // Save label data
      if (labelData.isNotEmpty) {
        final labelFile = File('${newDir.path}/label_data.json');
        await labelFile.writeAsString(jsonEncode(labelData));
      }

      // Create summary report
      final summaryFile = File('${newDir.path}/summary.txt');
      final summary = _generateSummary(
        projectName,
        auditData,
        calculatorData,
        labelData,
      );
      await summaryFile.writeAsString(summary);

      return projectDir;
    } catch (e) {
      throw Exception('Błąd podczas eksportu: $e');
    }
  }

  static String _generateSummary(
    String projectName,
    Map<String, dynamic> auditData,
    Map<String, dynamic> calculatorData,
    Map<String, dynamic> labelData,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('RAPORT PROJEKTU GRIDLY ELECTRICAL CHECKER');
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('');

    buffer.writeln('NAZWA PROJEKTU: $projectName');
    buffer.writeln('DATA EKSPORTU: ${DateTime.now().toLocal()}');
    buffer.writeln('WERSJA: 1.0');
    buffer.writeln('');

    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('DANE AUDYTU');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    if (auditData.isNotEmpty) {
      auditData.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    } else {
      buffer.writeln('Brak danych audytu');
    }
    buffer.writeln('');

    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('DANE KALKULATORÓW');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    if (calculatorData.isNotEmpty) {
      calculatorData.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    } else {
      buffer.writeln('Brak danych kalkulatorów');
    }
    buffer.writeln('');

    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('DANE OPISÓWEK');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    if (labelData.isNotEmpty) {
      labelData.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    } else {
      buffer.writeln('Brak danych opisówek');
    }
    buffer.writeln('');

    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('Wygenerowano przez: Gridly Electrical Checker v1.0');
    buffer.writeln('═══════════════════════════════════════════════════════════════');

    return buffer.toString();
  }

  static Future<List<FileSystemEntity>> getExportedProjects() async {
    try {
      final Directory appDocsDir = await getApplicationDocumentsDirectory();
      final Directory exportDir =
          Directory('${appDocsDir.path}/Gridly_Electrical_Checker_Export');

      if (await exportDir.exists()) {
        return exportDir.listSync();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteProject(String projectPath) async {
    try {
      final projectDir = Directory(projectPath);
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
