import 'package:flutter/foundation.dart';

class WykazGenerator {
  static Future<void> generateWykazPdf({
    required String nazwaBudowy,
    required String data,
    required List<Map<String, dynamic>> lokale,
  }) async {
    // Lightweight compatibility implementation used by recovered backups.
    debugPrint(
      '[WykazGenerator] ${lokale.length} lokali, budowa: $nazwaBudowy, data: $data',
    );
  }
}
