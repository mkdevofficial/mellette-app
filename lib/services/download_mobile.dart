import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> downloadPdfFile(
  Uint8List bytes,
  String fileName, {
  void Function(double progress)? onProgress,
}) async {
  Directory? downloadDir;

  if (Platform.isAndroid) {
    // 1. Primary target on Android: Public Downloads folder
    final publicDownload = Directory('/storage/emulated/0/Download');
    if (publicDownload.existsSync()) {
      downloadDir = publicDownload;
    }
  }

  // 2. Fallbacks
  try {
    downloadDir ??= await getDownloadsDirectory();
  } catch (_) {}

  try {
    downloadDir ??= await getExternalStorageDirectory();
  } catch (_) {}

  try {
    downloadDir ??= await getApplicationDocumentsDirectory();
  } catch (_) {}

  if (downloadDir == null) {
    throw Exception('تعذر الوصول إلى مجلد التنزيلات على هذا الجهاز');
  }

  final safeName = fileName.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
  final file = File('${downloadDir.path}/$safeName');

  final totalBytes = bytes.length;
  final raf = await file.open(mode: FileMode.write);
  const chunkSize = 64 * 1024; // 64 KB chunks
  int written = 0;

  for (int i = 0; i < totalBytes; i += chunkSize) {
    final end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
    await raf.writeFrom(bytes, i, end);
    written += (end - i);
    if (onProgress != null) {
      onProgress(written / totalBytes);
    }
    // Yield briefly so UI can render progress smoothly
    await Future.delayed(const Duration(milliseconds: 3));
  }

  await raf.close();

  if (onProgress != null) {
    onProgress(1.0);
  }

  return file.path;
}
