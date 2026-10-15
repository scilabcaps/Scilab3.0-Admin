import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/auth/pages/login_screen.dart';

void main() {
  testWidgets('pressing Enter in the password field submits the form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final passwordField = find.byType(TextFormField).last;
    await tester.enterText(find.byType(TextFormField).first, 'admin');
    await tester.tap(passwordField);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
