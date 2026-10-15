import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/auth/controllers/auth_controller.dart';

void main() {
  test('formats the successful login audit message with the email', () {
    expect(
      AuthAuditMessages.login('admin@example.com'),
      'User admin@example.com logged in successfully',
    );
  });

  test('formats the logout audit message with the email', () {
    expect(
      AuthAuditMessages.logout('admin@example.com'),
      'User admin@example.com logged out',
    );
  });

  test('uses a safe fallback when the logout email is unavailable', () {
    expect(AuthAuditMessages.logout(null), 'User unknown email logged out');
  });
}
