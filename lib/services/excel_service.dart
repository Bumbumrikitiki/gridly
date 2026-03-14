import 'package:flutter/foundation.dart';

class ExcelService {
  static Future<void> exportWykazExcel({
    String? nazwaBudowy,
    String? data,
    List<Map<String, dynamic>>? lokale,
    List<String>? stages,
  }) async {
    debugPrint(
      '[ExcelService] build=$nazwaBudowy date=$data rows=${lokale?.length ?? 0}',
    );
  }
}
