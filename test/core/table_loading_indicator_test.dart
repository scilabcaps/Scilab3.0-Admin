import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_scalib/core/utils/table_loading_indicator.dart';

void main() {
  testWidgets('shows a centered progress indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TableLoadingIndicator(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
  });

  testWidgets('overlay keeps table content visible while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TableLoadingOverlay(
            isLoading: true,
            child: Text('Table content'),
          ),
        ),
      ),
    );

    expect(find.text('Table content'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
