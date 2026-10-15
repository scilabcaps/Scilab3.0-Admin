import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/room_and_resources/inventory/models/inventory_model.dart';
import 'package:admin_scalib/features/room_and_resources/inventory/widgets/inventory_stock_dialog.dart';

void main() {
  final equipment = InventoryItem(
    itemId: '4',
    itemName: 'Wire gauze',
    category: 'Equipment',
    quantity: 493,
    status: 'Available',
    stockLevel: 'High',
  );
  final chemical = InventoryItem(
    itemId: '12',
    itemName: 'Hydrochloric Acid',
    category: 'Chemical',
    quantity: 2.5,
    status: 'Available',
    stockLevel: 'Low',
    unit: 'mL',
  );

  testWidgets('uses the reservation-style stock update structure', (
    tester,
  ) async {
    await _openDialog(tester, equipment, (_) async {});

    expect(find.text('Update Stock'), findsOneWidget);
    expect(find.text('Asset'), findsOneWidget);
    expect(find.text('Wire gauze'), findsOneWidget);
    expect(find.text('Current quantity'), findsOneWidget);
    expect(find.text('Stock details'), findsOneWidget);
    expect(find.text('Update stock'), findsOneWidget);
  });

  testWidgets('uses decimal amount and unit for chemicals', (tester) async {
    await _openDialog(tester, chemical, (_) async {});

    expect(find.text('Amount (mL)'), findsOneWidget);
    expect(find.text('2.5 mL'), findsOneWidget);
    expect(find.text('Quantity (pieces)'), findsNothing);
  });

  testWidgets('validates quantity before saving', (tester) async {
    var saveCalled = false;
    await _openDialog(tester, equipment, (_) async => saveCalled = true);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity (pieces)'),
      '-1',
    );
    await tester.tap(find.byKey(const Key('inventory-stock-save')));
    await tester.pump();

    expect(find.text('Quantity cannot be negative'), findsOneWidget);
    expect(saveCalled, isFalse);
  });

  testWidgets('keeps the dialog open when saving fails', (tester) async {
    await _openDialog(
      tester,
      equipment,
      (_) async => throw Exception('offline'),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity (pieces)'),
      '500',
    );
    await tester.tap(find.byKey(const Key('inventory-stock-save')));
    await tester.pumpAndSettle();

    expect(find.text('Update Stock'), findsOneWidget);
    expect(
      find.text(
        'Stock could not be updated. Check the connection and try again.',
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

    await _openDialog(tester, equipment, (_) async {});

    expect(find.text('Update Stock'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openDialog(
  WidgetTester tester,
  InventoryItem item,
  Future<void> Function(num quantity) onSave,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (context) =>
                  InventoryStockDialog(item: item, onSave: onSave),
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
