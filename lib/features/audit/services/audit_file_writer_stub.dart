import 'dart:typed_data';

Future<void> writeAuditFile(String path, Uint8List bytes) async {
  throw UnsupportedError('Direct file writing is unavailable on this platform.');
}
