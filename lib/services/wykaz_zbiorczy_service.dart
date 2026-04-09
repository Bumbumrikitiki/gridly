import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:gridly/services/file_download_service.dart';

class WykazGenerator {
  static Future<void> generateWykazPdf({
    required String nazwaBudowy,
    required String data,
    required List<Map<String, dynamic>> lokale,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('fonts/roboto-regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('fonts/roboto-bold.ttf'),
    );

    final baseStyle = pw.TextStyle(font: regularFont, fontSize: 8);
    final boldStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
    );
    final headingStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );
    final pageNumStyle = pw.TextStyle(font: regularFont, fontSize: 7);

    final normalizedData = _normalizeData(data);
    final pdf = pw.Document();

    if (lokale.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Center(
            child: pw.Text(
              'Brak danych lokali do wygenerowania wykazu.',
              style: baseStyle,
            ),
          ),
        ),
      );
    } else {
      final stageNames = _collectStageNames(lokale);

      // A4 landscape usable width: 841.89 – 2×16 margins
      const double usableWidth = 841.89 - 32.0;
      const double lokalColW = 46.0;
      const double podwykonawcaColW = 120.0;
      const double headerRowH = 145.0;
      const double dataRowH = 15.0;

        final double stageColW = stageNames.isEmpty
          ? 50.0
          : ((usableWidth - lokalColW - podwykonawcaColW) / stageNames.length)
              .clamp(14.0, 60.0);

      // ── single bordered cell ─────────────────────────────────────────────
      pw.Widget cell(
        pw.Widget child,
        double w, {
        double? h,
        PdfColor? bg,
        pw.Alignment innerAlign = pw.Alignment.centerLeft,
      }) {
        return pw.Container(
          width: w,
          height: h,
          alignment: innerAlign,
          padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          decoration: pw.BoxDecoration(
            color: bg,
            border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
          ),
          child: child,
        );
      }

      // ── header row with rotated stage names ──────────────────────────────
      // The trick: draw cell backgrounds via a plain Row (no text constraints),
      // then overlay rotated labels via Stack+Positioned so they inherit the
      // Stack's (loose) constraints and are NOT clipped to stageColW.
      pw.Widget buildHeaderRow() {
        final totalW = lokalColW + podwykonawcaColW + stageColW * stageNames.length;

        // Layer 1 – coloured cell backgrounds + borders, no labels
        final bgRow = pw.Row(
          children: [
            pw.Container(
              width: lokalColW,
              height: headerRowH,
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey100,
                border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text('Lokal', style: boldStyle),
            ),
            pw.Container(
              width: podwykonawcaColW,
              height: headerRowH,
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey100,
                border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text('Podwykonawca', style: boldStyle),
            ),
            ...stageNames.map(
              (_) => pw.Container(
                width: stageColW,
                height: headerRowH,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                  border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                ),
              ),
            ),
          ],
        );

        // Layer 2 – rotated text, positioned via Stack so no outer clip
        // Pre-rotation dimensions: width=textBoxW becomes visual HEIGHT after
        // 90° rotation; height=textBoxH becomes visual WIDTH after rotation.
        final double textBoxW = headerRowH - 12; // visual height ≈ cell height
        final double textBoxH = stageColW - 4;   // visual width ≈ column width

        final overlays = List<pw.Widget>.generate(stageNames.length, (i) {
          // Column centre in Stack coordinates
          final cx = lokalColW + podwykonawcaColW + (i + 0.5) * stageColW;
          // Place the pre-rotation SizedBox so its centre is at (cx, headerRowH/2)
          final left = cx - textBoxW / 2;
          final top  = headerRowH / 2 - textBoxH / 2;

          return pw.Positioned(
            left: left,
            top: top,
            child: pw.Transform.rotate(
              angle: math.pi / 2,
              // pw.Transform.rotate rotates around the child's centre,
              // so the visual centre stays at (cx, headerRowH/2). ✓
              child: pw.SizedBox(
                width: textBoxW,
                height: textBoxH,
                child: pw.Center(
                  child: pw.Text(
                    _sanitizePolish(_splitToTwoLines(stageNames[i])),
                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
          );
        });

        return pw.SizedBox(
          width: totalW,
          height: headerRowH,
          child: pw.Stack(
            overflow: pw.Overflow.visible,
            children: [
              pw.Positioned(left: 0, top: 0, child: bgRow),
              ...overlays,
            ],
          ),
        );
      }

      // ── single data row ──────────────────────────────────────────────────
      pw.Widget buildDataRow(Map<String, dynamic> lokal, bool alt) {
        final rowBg = alt ? const PdfColor(0.95, 0.95, 0.97) : null;
        return pw.Row(
          children: [
            cell(
              pw.Text(
                _sanitizePolish(_stringValue(lokal['nrLokalu'])),
                style: baseStyle,
              ),
              lokalColW,
              h: dataRowH,
              bg: rowBg,
            ),
            cell(
              pw.Text(
                _sanitizePolish(_stringValue(lokal['podwykonawca'])),
                style: baseStyle,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
              podwykonawcaColW,
              h: dataRowH,
              bg: rowBg,
            ),
            ...stageNames.map((stage) {
              final status = _statusLabel(lokal[stage]);
              final ok = status == '✓';
              return cell(
                pw.Text(
                  status,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: ok ? PdfColors.green800 : PdfColors.red700,
                  ),
                ),
                stageColW,
                h: dataRowH,
                bg: rowBg,
                innerAlign: pw.Alignment.center,
              );
            }),
          ],
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(16, 16, 16, 30),
          // ── repeated on every page ───────────────────────────────────────
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (ctx.pageNumber == 1) ...[
                pw.Text('Wykaz Zbiorczy Lokali', style: headingStyle),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Budowa: ${_sanitizePolish(nazwaBudowy)}',
                  style: baseStyle,
                ),
                pw.Text('Data: $normalizedData', style: baseStyle),
                pw.SizedBox(height: 8),
              ],
              buildHeaderRow(),
            ],
          ),
          // ── page number at the bottom ────────────────────────────────────
          footer: (ctx) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              'Strona ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pageNumStyle,
            ),
          ),
          // ── data rows ────────────────────────────────────────────────────
          build: (ctx) => [
            for (int i = 0; i < lokale.length; i++)
              buildDataRow(lokale[i], i.isOdd),
          ],
        ),
      );
    }

    final bytes = await pdf.save();
    final fileName =
        'wykaz_lokali_${_safeFileFragment(nazwaBudowy)}_$normalizedData.pdf';
    await FileDownloadService.saveGeneratedFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
    );

    debugPrint('[WykazGenerator] PDF gotowy: $fileName (${lokale.length} lokali)');
  }

  static List<String> _collectStageNames(List<Map<String, dynamic>> lokale) {
    final order = <String>[];
    for (final lokal in lokale) {
      for (final key in lokal.keys) {
        if (key != 'nrLokalu' && key != 'podwykonawca' && !order.contains(key)) {
          order.add(key);
        }
      }
    }
    return order;
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

  static String _stringValue(dynamic value) => value?.toString() ?? '-';

  static String _normalizeData(String rawDate) {
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

  static String _splitToTwoLines(String input) {
    final s = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length <= 10) return s;
    final mid = s.length ~/ 2;
    // search for the nearest space around the midpoint
    int best = -1;
    int bestDist = s.length;
    for (int i = 0; i < s.length; i++) {
      if (s[i] == ' ') {
        final dist = (i - mid).abs();
        if (dist < bestDist) {
          bestDist = dist;
          best = i;
        }
      }
    }
    if (best == -1) return s;
    return '${s.substring(0, best)}\n${s.substring(best + 1)}';
  }
}
