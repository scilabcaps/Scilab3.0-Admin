import 'dart:io';

import 'package:admin_scalib/features/audit/models/audit_log_model.dart';
import 'package:admin_scalib/features/audit/services/audit_export_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final generatedAt = DateTime.utc(2026, 9, 5, 4, 30, 45);
  final logs = List.generate(65, (index) => AuditLog(
    id: 'log-$index', userId: 'user-$index', userName: 'José Peña $index',
    actionType: 'REJECT', entityType: 'reservation',
    description: index == 0
        ? '=SUM(A1:A2) ${'Long audit description. ' * 100}END_OF_LONG_DESCRIPTION'
        : 'Rejected reservation $index',
    createdAt: generatedAt.subtract(Duration(minutes: index)),
  ));

  test('full timestamps retain seconds and an explicit UTC offset', () {
    final value = formatAuditTimestamp(generatedAt);
    expect(value, matches(RegExp(r'^2026-09-05 \d{2}:\d{2}:45 UTC[+-]\d{2}:\d{2}$')));
    expect(value, isNot(contains('ago')));
  });

  test('Excel retains every row, full text and safe text cells', () async {
    final bytes = AuditExportService().generateExcel(logs: logs, action: 'REJECT',
        entity: 'reservation', days: 30, generatedAt: generatedAt);
    final sheet = Excel.decodeBytes(bytes).tables['Audit Logs']!;
    expect(sheet.maxRows, 71);
    expect(sheet.rows[1][0]!.value.toString(), contains('REJECT'));
    expect(sheet.rows[6][0]!.value.toString(), formatAuditTimestamp(logs[0].createdAt));
    expect(sheet.rows[6][4]!.value, isA<TextCellValue>());
    expect(sheet.rows[6][4]!.value.toString(), logs[0].description);
    expect(sheet.rows.last[4]!.value.toString(), 'Rejected reservation 64');
    final output = Platform.environment['AUDIT_EXPORT_QA_DIR'];
    if (output != null) {
      await Directory(output).create(recursive: true);
      await File('$output/audit.xlsx').writeAsBytes(bytes);
    }
  });

  test('PDF generates multiple pages with long descriptions and accented names', () async {
    final bytes = await AuditExportService().generatePdf(logs: logs, action: 'REJECT',
        entity: 'reservation', days: 30, generatedAt: generatedAt);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final output = Platform.environment['AUDIT_EXPORT_QA_DIR'];
    if (output != null) {
      await Directory(output).create(recursive: true);
      await File('$output/audit.pdf').writeAsBytes(bytes);
    }
  });
}
