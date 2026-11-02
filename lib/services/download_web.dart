import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> downloadPdfFile(
  Uint8List bytes,
  String fileName, {
  void Function(double progress)? onProgress,
}) async {
  if (onProgress != null) {
    onProgress(0.3);
    await Future.delayed(const Duration(milliseconds: 80));
    onProgress(0.7);
    await Future.delayed(const Duration(milliseconds: 80));
  }

  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);

  if (onProgress != null) {
    onProgress(1.0);
  }

  return fileName;
}
