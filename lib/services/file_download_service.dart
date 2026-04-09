import 'download_file_io.dart'
    if (dart.library.html) 'download_file_web.dart' as downloader;

class FileDownloadService {
  static Future<void> saveGeneratedFile({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) {
    return downloader.saveBytes(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
