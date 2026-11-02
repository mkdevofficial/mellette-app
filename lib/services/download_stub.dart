import 'dart:typed_data';

Future<String> downloadPdfFile(
  Uint8List bytes,
  String fileName, {
  void Function(double progress)? onProgress,
}) async {
  throw UnsupportedError('Platform not supported for file download');
}
