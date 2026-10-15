import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/room_and_resources/inventory/models/inventory_model.dart';
import 'package:admin_scalib/features/room_and_resources/inventory/widgets/inventory_edit_dialog.dart';

void main() {
  final chemical = InventoryItem(
    itemId: '12',
    itemName: 'Hydrochloric Acid',
    category: 'Chemical',
    quantity: 2.5,
    status: 'Available',
    stockLevel: 'Low',
    formula: 'HCl',
    unit: 'mL',
    expiration: '2025-01-15',
  );
  final equipment = InventoryItem(
    itemId: '4',
    itemName: 'Microscope',
    category: 'Equipment',
    quantity: 5,
    status: 'Available',
    stockLevel: 'Medium',
    conditionNotes: 'Calibrated',
  );

  testWidgets('shows chemical expiration as locked read-only information', (
    tester,
  ) async {
    await _openDialog(tester, chemical, (_) async {});

    expect(find.text('Edit Chemical'), findsOneWidget);
    expect(find.text('Expiration'), findsOneWidget);
    expect(find.text('2025-01-15'), findsOneWidget);
    expect(find.text('Expiration cannot be edited'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today), findsNothing);
    expect(find.text('Select date'), findsNothing);
  });

  testWidgets('saves editable chemical fields without expiration input', (
    tester,
  ) async {
    String? savedName;
    num? savedQuantity;
    String? savedFormula;
    String? savedUnit;

    await _openDialog(tester, chemical, (values) async {
      savedName = values.itemName;
      savedQuantity = values.quantity;
      savedFormula = values.formula;
      savedUnit = values.unit;
    });

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Updated Acid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity'),
      '4.5',
    );
    await tester.tap(find.byKey(const Key('inventory-edit-save')));
    await tester.pumpAndSettle();

    expect(savedName, 'Updated Acid');
    expect(savedQuantity, 4.5);
    expect(savedFormula, 'HCl');
    expect(savedUnit, 'mL');
  });

  testWidgets('shows validation and save errors without closing', (
    tester,
  ) async {
    await _openDialog(
      tester,
      chemical,
      (_) async => throw Exception('offline'),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity'),
      '-1',
    );
    await tester.tap(find.byKey(const Key('inventory-edit-save')));
    await tester.pump();
    expect(find.text('Quantity cannot be negative'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '3');
    await tester.tap(find.byKey(const Key('inventory-edit-save')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Chemical'), findsOneWidget);
    expect(
      find.text(
        'Changes could not be saved. Check the connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps non-chemical fields focused on asset condition', (
    tester,
  ) async {
    await _openDialog(tester, equipment, (_) async {});

    expect(find.text('Edit Asset'), findsOneWidget);
    expect(find.text('Condition notes (optional)'), findsOneWidget);
    expect(find.text('Expiration'), findsNothing);
    expect(find.text('Formula (optional)'), findsNothing);
  });

  testWidgets('fits a narrow window with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await _openDialog(tester, chemical, (_) async {});

    expect(find.text('Edit Chemical'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SavedValues {
  const _SavedValues({
    required this.itemName,
    required this.quantity,
    this.formula,
    this.unit,
    this.conditionNotes,
  });

  final String itemName;
  final num quantity;
  final String? formula;
  final String? unit;
  final String? conditionNotes;
}

Future<void> _openDialog(
  WidgetTester tester,
  InventoryItem item,
  Future<void> Function(_SavedValues values) onSave,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => InventoryEditDialog(
                item: item,
                onSave:
                    ({
                      required itemName,
                      required quantity,
                      formula,
                      unit,
                      conditionNotes,
                    }) => onSave(
                      _SavedValues(
                        itemName: itemName,
                        quantity: quantity,
                        formula: formula,
                        unit: unit,
                        conditionNotes: conditionNotes,
                      ),
                    ),
              ),
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
