import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:gridly/services/file_download_service.dart';

class KartaSingleGenerator {
  static Future<void> generateSinglePdf({
    String? nazwaBudowy,
    String? data,
    String? nrLokalu,
    String? nrBudynku,
    String? klatka,
    String? pietro,
    String? podwykonawca,
    Map<String, dynamic>? postepyPrac,
    Map<String, dynamic>? lokal,
  }) async {
    final safeNazwaBudowy = (nazwaBudowy == null || nazwaBudowy.trim().isEmpty)
        ? 'budowa'
        : nazwaBudowy.trim();
    final safeNrLokalu = (nrLokalu == null || nrLokalu.trim().isEmpty)
        ? 'lokal'
        : nrLokalu.trim();
    final normalizedData = _normalizeData(data);

    final progress = postepyPrac ?? <String, dynamic>{};
    final sortedStages = progress.keys.toList()..sort();

    final regularFont = pw.Font.ttf(
      await rootBundle.load('fonts/roboto-regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('fonts/roboto-bold.ttf'),
    );
    final bodyStyle = pw.TextStyle(font: regularFont, fontSize: 10);
    final pdf = pw.Document();

    final stageRows = sortedStages
        .map((stage) => <String>[stage, _statusLabel(progress[stage])])
        .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // NAGŁÓWEK trzech kolumn: GRIDLY | Karta lokalowa | Numery lokalu
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'GRIDLY',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'KARTA LOKALOWA',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Budowlany: ${_sanitizePolish(safeNrLokalu)}',
                        style: pw.TextStyle(font: regularFont, fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Docelowy: -',
                        style: pw.TextStyle(font: regularFont, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
              
              // RUBRYKI - dane lokalu
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Budowa: ${_sanitizePolish(safeNazwaBudowy)}', style: bodyStyle),
                      pw.SizedBox(height: 3),
                      pw.Text('Data: $normalizedData', style: bodyStyle),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Budynek: ${_sanitizePolish(nrBudynku ?? '-')}', style: bodyStyle),
                      pw.SizedBox(height: 3),
                      pw.Text('Klatka: ${_sanitizePolish(klatka ?? '-')}', style: bodyStyle),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Piętro: ${_sanitizePolish((pietro ?? '-').toString())}', style: bodyStyle),
                      pw.SizedBox(height: 3),
                      pw.Text('Podwykonawca: ${_sanitizePolish(podwykonawca ?? '-')}', style: bodyStyle),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              
              // TABELA - Etapy i statusy
              pw.Text(
                'Etapy i statusy prac:',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              if (stageRows.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Text(
                    'Brak danych o postępach prac.',
                    style: bodyStyle,
                  ),
                )
              else
                pw.Table.fromTextArray(
                  headers: const <String>['Etap', 'Status'],
                  data: stageRows.map((row) => [_sanitizePolish(row[0]), row[1]]).toList(),
                  headerStyle: pw.TextStyle(
                    font: boldFont,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey100,
                  ),
                  cellStyle: pw.TextStyle(font: regularFont, fontSize: 9),
                  cellHeight: 14,
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  cellAlignments: const {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                  },
                  columnWidths: const {
                    0: pw.FlexColumnWidth(5),
                    1: pw.FlexColumnWidth(1.2),
                  },
                ),
              pw.SizedBox(height: 12),
              
              // SEKCJA - UWAGI na dole strony
              pw.Text(
                'Uwagi:',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                height: 100,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600, width: 1),
                ),
                child: pw.Column(
                  children: [
                    pw.Expanded(
                      child: pw.Container(),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'karta_lokalowa_${_safeFileFragment(safeNazwaBudowy)}_${_safeFileFragment(safeNrLokalu)}_$normalizedData.pdf';
    await FileDownloadService.saveGeneratedFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
    );

    debugPrint('[KartaSingleGenerator] PDF gotowy: $fileName');
  }

  static String _statusLabel(dynamic value) {
    if (value is bool) {
      return value ? '✓' : 'x';
    }
    final normalized = value.toString().trim().toLowerCase();
    return (normalized == 'true' || normalized == 'tak' || normalized == '1')
        ? '✓'
        : 'x';
  }

  static String _normalizeData(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      return rawDate.replaceAll('/', '-');
    }
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  static String _sanitizePolish(String input) {
    const Map<String, String> replacements = {
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ź': 'z',
      'ż': 'z',
      'Ą': 'A',
      'Ć': 'C',
      'Ę': 'E',
      'Ł': 'L',
      'Ń': 'N',
      'Ó': 'O',
      'Ś': 'S',
      'Ź': 'Z',
      'Ż': 'Z',
    };
    String result = input;
    replacements.forEach((polish, ascii) {
      result = result.replaceAll(polish, ascii);
    });
    return result;
  }

  static String _safeFileFragment(String value) {
    final sanitized = _sanitizePolish(value);
    return sanitized
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
