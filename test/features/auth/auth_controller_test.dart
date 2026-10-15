import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/auth/controllers/auth_controller.dart';

void main() {
  test('turns invalid credential details into friendly sign-in guidance', () {
    final message = LoginErrorMessages.from(
      'AuthApiException(message: Invalid login credentials, statusCode: 400, code: invalid_credentials)',
    );

    expect(message, LoginErrorMessages.invalidCredentials);
    expect(message, isNot(contains('AuthApiException')));
    expect(message, isNot(contains('400')));
    expect(message, isNot(contains('invalid_credentials')));
  });

  test('hides unexpected authentication details behind a safe message', () {
    final message = LoginErrorMessages.from(
      'AuthApiException(message: internal database detail, statusCode: 500)',
    );

    expect(message, LoginErrorMessages.generic);
    expect(message, isNot(contains('database')));
    expect(message, isNot(contains('500')));
  });
}
