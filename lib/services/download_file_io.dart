import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<void> saveBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  await Printing.sharePdf(
    bytes: Uint8List.fromList(bytes),
    filename: fileName,
  );
}
