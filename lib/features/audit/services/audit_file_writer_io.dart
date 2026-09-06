import 'dart:io';
import 'dart:typed_data';

Future<void> writeAuditFile(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}
