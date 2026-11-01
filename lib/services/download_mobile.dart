import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadPdfFile(Uint8List bytes, String fileName) async {
  final tempDir = await getTemporaryDirectory();
  // Sanitize filename for local storage
  final safeName = fileName.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
  final file = File('${tempDir.path}/$safeName');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf', name: safeName)],
    text: fileName,
  );
}
