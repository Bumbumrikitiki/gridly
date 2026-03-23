import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WykazGenerator {
  static Future<void> generateWykazPdf({
    required String nazwaBudowy,
    required String data,
    required List<Map<String, dynamic>> lokale,
  }) async {
    final pdf = pw.Document();

    final stageNames = <String>{};
    for (final lokal in lokale) {
      for (final key in lokal.keys) {
        if (key != 'nrLokalu') {
          stageNames.add(key);
        }
      }
    }

    final orderedStages = stageNames.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Text(
            'WYKAZ ZBIORCZY - POSTEP PRAC',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Budowa: $nazwaBudowy'),
          pw.Text('Data: $data'),
          pw.Text('Liczba lokali: ${lokale.length}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Podsumowanie lokali',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.4),
              1: const pw.FlexColumnWidth(1.1),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _headerCell('Lokal'),
                  _headerCell('Wykonane'),
                  _headerCell('Wszystkie'),
                  _headerCell('Postep'),
                ],
              ),
              for (final lokal in lokale)
                () {
                  final total = orderedStages.length;
                  final done = orderedStages
                      .where((stage) => _asBool(lokal[stage]))
                      .length;
                  final progress =
                      total == 0 ? 0 : ((done / total) * 100).round();

                  return pw.TableRow(
                    children: [
                      _bodyCell('${lokal['nrLokalu'] ?? '-'}'),
                      _bodyCell('$done'),
                      _bodyCell('$total'),
                      _bodyCell('$progress%'),
                    ],
                  );
                }(),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Szczegoly etapow',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          for (final lokal in lokale) ...[
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(
                'Lokal ${lokal['nrLokalu'] ?? '-'}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _headerCell('Etap'),
                    _headerCell('Status'),
                  ],
                ),
                for (final stage in orderedStages)
                  pw.TableRow(
                    children: [
                      _bodyCell(stage),
                      _bodyCell(_asBool(lokal[stage]) ? 'TAK' : 'NIE'),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
          ],
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName = _buildFileName(nazwaBudowy, data);

    try {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value == null) {
      return false;
    }
    return value.toString().toLowerCase() == 'true';
  }

  static String _buildFileName(String nazwaBudowy, String data) {
    final sanitized = nazwaBudowy
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final safeProject = sanitized.isEmpty ? 'budowa' : sanitized;
    final safeDate = data.replaceAll(RegExp(r'[^0-9-]'), '-');
    return 'wykaz_zbiorczy_${safeProject}_$safeDate.pdf';
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _bodyCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8.5),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
