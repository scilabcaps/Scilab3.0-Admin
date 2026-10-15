import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadEnvironment({
  Future<void> Function()? loadFile,
  Future<void> Function(Duration)? wait,
}) async {
  final load = loadFile ?? () => dotenv.load(fileName: '.env');
  final delay = wait ?? Future<void>.delayed;

  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      await load();
      return;
    } on FileNotFoundError {
      if (attempt == 3) rethrow;
      await delay(const Duration(milliseconds: 200));
    }
  }
}
