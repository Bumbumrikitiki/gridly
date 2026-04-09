import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:excel/excel.dart';

import 'package:gridly/services/file_download_service.dart';

class ExcelService {
  static Future<void> exportWykazExcel({
    String? nazwaBudowy,
    String? data,
    List<Map<String, dynamic>>? lokale,
    List<String>? stages,
  }) async {
    final safeNazwaBudowy = (nazwaBudowy == null || nazwaBudowy.trim().isEmpty)
        ? 'budowa'
        : nazwaBudowy.trim();
    final normalizedData = _normalizeData(data);
    final workbook = Excel.createExcel();
    final sheet = workbook['Wykaz Lokali'];

    final stageNames = stages == null || stages.isEmpty
        ? _collectStageNames(lokale ?? const <Map<String, dynamic>>[])
        : stages;

    final headers = <String>['Nr lokalu', 'Podwykonawca', ...stageNames];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    final rows = lokale ?? const <Map<String, dynamic>>[];
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex + 1))
          .value = TextCellValue(_sanitizePolish(row['nrLokalu']?.toString() ?? '-'));

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex + 1))
          .value = TextCellValue(
            _sanitizePolish(row['podwykonawca']?.toString() ?? '-'),
          );

      for (var stageIndex = 0; stageIndex < stageNames.length; stageIndex++) {
        final stageName = stageNames[stageIndex];
        final value = _statusLabel(row[stageName]);
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: stageIndex + 2,
                rowIndex: rowIndex + 1,
              ),
            )
            .value = TextCellValue(value);
      }
    }

    final bytes = workbook.encode();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Nie udało się zbudować pliku Excel.');
    }

    final fileName =
        'wykaz_lokali_${_safeFileFragment(safeNazwaBudowy)}_$normalizedData.xlsx';
    await FileDownloadService.saveGeneratedFile(
      fileName: fileName,
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    debugPrint('[ExcelService] Excel gotowy: $fileName (${rows.length} lokali)');
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
