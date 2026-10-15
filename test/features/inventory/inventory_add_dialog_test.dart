import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/room_and_resources/inventory/widgets/inventory_add_dialog.dart';

void main() {
  testWidgets('uses the reservation-style structure for adding an asset', (
    tester,
  ) async {
    await _openDialog(tester, _noopSave);

    expect(find.text('Add New Asset'), findsOneWidget);
    expect(find.text('Asset type'), findsOneWidget);
    expect(find.text('New inventory item'), findsOneWidget);
    expect(find.text('Asset details'), findsOneWidget);
    expect(find.text('Add asset'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('switches between chemical and non-chemical fields', (
    tester,
  ) async {
    await _openDialog(tester, _noopSave);

    expect(find.text('Formula (optional)'), findsOneWidget);
    expect(find.text('Expiration (optional)'), findsOneWidget);
    expect(find.text('Condition notes (optional)'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equipment').last);
    await tester.pumpAndSettle();

    expect(find.text('Condition notes (optional)'), findsOneWidget);
    expect(find.text('Formula (optional)'), findsNothing);
    expect(find.text('Expiration (optional)'), findsNothing);
  });

  testWidgets('validates required fields before saving', (tester) async {
    var saveCalled = false;
    await _openDialog(
      tester,
      ({
        required itemName,
        required category,
        required quantity,
        formula,
        unit,
        expiration,
        conditionNotes,
      }) async => saveCalled = true,
    );

    await tester.tap(find.byKey(const Key('inventory-add-save')));
    await tester.pump();

    expect(find.text('Enter an item name'), findsOneWidget);
    expect(find.text('Enter a valid quantity'), findsOneWidget);
    expect(saveCalled, isFalse);
  });

  testWidgets('keeps the dialog open when saving fails', (tester) async {
    await _openDialog(
      tester,
      ({
        required itemName,
        required category,
        required quantity,
        formula,
        unit,
        expiration,
        conditionNotes,
      }) async => throw Exception('offline'),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Test tube',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '4');
    await tester.tap(find.byKey(const Key('inventory-add-save')));
    await tester.pumpAndSettle();

    expect(find.text('Add New Asset'), findsOneWidget);
    expect(
      find.text(
        'This asset could not be added. Check the connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('supports a narrow window with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await _openDialog(tester, _noopSave);

    expect(find.text('Add New Asset'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openDialog(WidgetTester tester, InventoryAddSave onSave) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (context) => InventoryAddDialog(onSave: onSave),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _noopSave({
  required String itemName,
  required String category,
  required num quantity,
  String? formula,
  String? unit,
  String? expiration,
  String? conditionNotes,
}) async {}
