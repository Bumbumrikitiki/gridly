import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  final blob = html.Blob(<dynamic>[Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
