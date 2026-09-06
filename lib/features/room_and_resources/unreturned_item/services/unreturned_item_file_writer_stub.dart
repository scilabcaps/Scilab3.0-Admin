import 'dart:typed_data';

Future<void> writeUnreturnedItemFile(String path, Uint8List bytes) async {
  throw UnsupportedError('Direct file writing is unavailable on this platform.');
}
