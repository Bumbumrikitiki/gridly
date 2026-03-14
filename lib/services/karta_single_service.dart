import 'package:flutter/foundation.dart';

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
    debugPrint(
      '[KartaSingleGenerator] build=$nazwaBudowy, date=$data, unit=$nrLokalu, building=$nrBudynku',
    );
  }
}
