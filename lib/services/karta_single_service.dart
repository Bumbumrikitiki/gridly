import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final symbolsFont = await PdfGoogleFonts.notoSansSymbols2Regular();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );

    final progressEntries = (postepyPrac ?? <String, dynamic>{})
        .entries
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final completed = progressEntries.where((e) => _asBool(e.value)).length;
    final total = progressEntries.length;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();
    final progressColumns = _splitEntries(progressEntries, 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 18),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    height: 52,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('102A43'),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'GRIDLY',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('F7B500'),
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'KARTA LOKALOWA',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          _v(nazwaBudowy),
                          style: const pw.TextStyle(fontSize: 8.5),
                          textAlign: pw.TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Container(
                    width: 86,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      border: pw.Border.all(color: PdfColors.grey500),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Numer lokalu',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _v(nrLokalu),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2),
                  1: const pw.FlexColumnWidth(2.2),
                  2: const pw.FlexColumnWidth(1.1),
                  3: const pw.FlexColumnWidth(1.7),
                },
                children: [
                  _detailsRow(
                      'Nazwa budowy', _v(nazwaBudowy), 'Data', _v(data)),
                  _detailsRow('Lokal', _v(nrLokalu), 'Budynek', _v(nrBudynku)),
                  _detailsRow('Klatka', _v(klatka), 'Piętro', _v(pietro)),
                  _detailsRow(
                    'Podwykonawca',
                    _v(podwykonawca),
                    'Postęp',
                    '$percent% ($completed/$total)',
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  'Postępy prac',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              if (progressEntries.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Text(
                    'Brak danych etapów prac dla tego lokalu.',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                )
              else
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (var index = 0;
                        index < progressColumns.length;
                        index++) ...[
                      pw.Expanded(
                        child: _progressTable(progressColumns[index], symbolsFont),
                      ),
                      if (index < progressColumns.length - 1)
                        pw.SizedBox(width: 8),
                    ],
                  ],
                ),
              pw.Spacer(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Uwagi',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                height: 92,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    _notesLine(),
                    pw.SizedBox(height: 12),
                    _notesLine(),
                    pw.SizedBox(height: 12),
                    _notesLine(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = _buildFileName(nazwaBudowy, nrLokalu, data);

    try {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

  static String _v(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }
    return value.trim();
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

  static String _buildFileName(String? budowa, String? lokal, String? data) {
    final safeBuild = _slugify(budowa, fallback: 'budowa');
    final safeUnit = _slugify(lokal, fallback: 'lokal');
    final safeDate = (data ?? '').replaceAll(RegExp(r'[^0-9-]'), '-');
    final suffix = safeDate.isEmpty ? 'data' : safeDate;
    return 'karta_lokalowa_${safeBuild}_${safeUnit}_$suffix.pdf';
  }

  static String _slugify(String? value, {required String fallback}) {
    final cleaned = (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  static pw.TableRow _tableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  static pw.TableRow _detailsRow(
    String labelLeft,
    String valueLeft,
    String labelRight,
    String valueRight,
  ) {
    return pw.TableRow(
      children: [
        _detailLabelCell(labelLeft),
        _detailValueCell(valueLeft),
        _detailLabelCell(labelRight),
        _detailValueCell(valueRight),
      ],
    );
  }

  static pw.Widget _detailLabelCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
      ),
    );
  }

  static pw.Widget _detailValueCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8.5)),
    );
  }

  static pw.Widget _progressTable(
      List<MapEntry<String, dynamic>> entries, pw.Font symbolsFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _compactHeaderCell('Etap'),
            _compactHeaderCell('Status'),
          ],
        ),
        for (final entry in entries)
          pw.TableRow(
            children: [
              _compactBodyCell(entry.key),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 3, vertical: 3),
                child: pw.Text(
                  _asBool(entry.value) ? '✓' : 'X',
                  style: pw.TextStyle(
                    fontSize: 7.3,
                    fontFallback: [symbolsFont],
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
      ],
    );
  }

  static List<List<MapEntry<String, dynamic>>> _splitEntries(
    List<MapEntry<String, dynamic>> entries,
    int columns,
  ) {
    if (entries.isEmpty) {
      return [<MapEntry<String, dynamic>>[]];
    }

    final normalizedColumns = columns < 1 ? 1 : columns;
    final chunkSize = (entries.length / normalizedColumns).ceil();

    return [
      for (var index = 0; index < entries.length; index += chunkSize)
        entries.sublist(
          index,
          index + chunkSize > entries.length
              ? entries.length
              : index + chunkSize,
        ),
    ];
  }

  static pw.Widget _compactHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _compactBodyCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7.3),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _notesLine() {
    return pw.Container(
      height: 1,
      color: PdfColors.grey400,
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _bodyCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
