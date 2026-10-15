import 'package:admin_scalib/core/config/environment_loader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retries a transient missing asset', () async {
    var attempts = 0;
    await loadEnvironment(
      loadFile: () async {
        attempts++;
        if (attempts == 1) throw FileNotFoundError();
      },
      wait: (_) async {},
    );

    expect(attempts, 2);
  });

  test('fails after three missing asset attempts', () async {
    var attempts = 0;
    await expectLater(
      loadEnvironment(
        loadFile: () async {
          attempts++;
          throw FileNotFoundError();
        },
        wait: (_) async {},
      ),
      throwsA(isA<FileNotFoundError>()),
    );

    expect(attempts, 3);
  });

  test('does not retry unrelated errors', () async {
    var attempts = 0;
    await expectLater(
      loadEnvironment(
        loadFile: () async {
          attempts++;
          throw StateError('other failure');
        },
        wait: (_) async {},
      ),
      throwsStateError,
    );

    expect(attempts, 1);
  });
}
