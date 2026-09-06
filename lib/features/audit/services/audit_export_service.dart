import 'package:excel/excel.dart' as excel;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/audit_log_model.dart';

/// Full local date/time, including the offset to make exported times unambiguous.
String formatAuditTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  final offset = local.timeZoneOffset;
  final minutes = offset.inMinutes.abs();
  final sign = offset.isNegative ? '-' : '+';
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)} '
      'UTC$sign${two(minutes ~/ 60)}:${two(minutes % 60)}';
}

class AuditExportService {
  static const _headers = ['Timestamp', 'Action', 'Entity', 'User', 'Description'];

  List<List<String>> _rows(List<AuditLog> logs) => logs.map((log) => [
    formatAuditTimestamp(log.createdAt),
    log.actionType,
    log.entityType,
    log.userName ?? 'Unknown',
    log.description ?? 'N/A',
  ]).toList();

  List<String> _summary({
    required int count,
    required String action,
    required String entity,
    required int days,
    required DateTime generatedAt,
  }) => [
    'Action: ${action == 'all' ? 'All Actions' : action} | '
        'Entity: ${entity == 'all' ? 'All Entities' : entity}',
    'Period: ${formatAuditTimestamp(generatedAt.subtract(Duration(days: days)))} '
        'to ${formatAuditTimestamp(generatedAt)}',
    'Generated: ${formatAuditTimestamp(generatedAt)} | Records: $count',
  ];

  Uint8List generateExcel({
    required List<AuditLog> logs,
    required String action,
    required String entity,
    required int days,
    required DateTime generatedAt,
  }) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Audit Logs'];
    workbook.setDefaultSheet('Audit Logs');
    workbook.delete('Sheet1');
    sheet.appendRow([excel.TextCellValue('Scilab Audit Report')]);
    for (final line in _summary(count: logs.length, action: action,
        entity: entity, days: days, generatedAt: generatedAt)) {
      sheet.appendRow([excel.TextCellValue(line)]);
    }
    sheet.appendRow([]);
    sheet.appendRow(_headers.map(excel.TextCellValue.new).toList());
    for (final row in _rows(logs)) {
      // Explicit text cells preserve names and prevent formula interpretation.
      sheet.appendRow(row.map(excel.TextCellValue.new).toList());
    }
    const widths = [34.0, 16.0, 20.0, 28.0, 85.0];
    for (var column = 0; column < widths.length; column++) {
      sheet.setColumnWidth(column, widths[column]);
      sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 5))
          .cellStyle = excel.CellStyle(
            bold: true,
            backgroundColorHex: excel.ExcelColor.fromHexString('#245C35'),
            fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
          );
      for (var row = 6; row < logs.length + 6; row++) {
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
            .cellStyle = excel.CellStyle(textWrapping: excel.TextWrapping.WrapText,
                verticalAlign: excel.VerticalAlign.Top);
      }
    }
    return Uint8List.fromList(workbook.encode()!);
  }

  Future<Uint8List> generatePdf({
    required List<AuditLog> logs,
    required String action,
    required String entity,
    required int days,
    required DateTime generatedAt,
  }) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
    final document = pw.Document(title: 'Scilab Audit Report', author: 'Scilab');
    // Split very long cells into continuation rows so one record cannot exceed
    // an entire PDF page. All text is retained, including long descriptions.
    final rows = <List<String>>[];
    for (final row in _rows(logs)) {
      final chunks = row.map(_chunks).toList();
      final count = chunks.map((cell) => cell.length).reduce((a, b) => a > b ? a : b);
      for (var i = 0; i < count; i++) {
        rows.add(List.generate(row.length, (column) =>
            i < chunks[column].length ? chunks[column][i] : ''));
      }
    }
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      maxPages: rows.length + 20,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Text('Scilab Audit Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ),
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8))),
      build: (_) => [
        ..._summary(count: logs.length, action: action, entity: entity,
            days: days, generatedAt: generatedAt).map((line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
            )),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: _headers,
          data: rows,
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1.1),
            2: pw.FlexColumnWidth(1.2), 3: pw.FlexColumnWidth(1.8),
            4: pw.FlexColumnWidth(4),
          },
          headerAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontSize: 9, color: PdfColors.white,
              fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF245C35)),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.all(6),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          border: null,
        ),
      ],
    ));
    return document.save();
  }

  List<String> _chunks(String value) {
    final result = <String>[];
    var buffer = StringBuffer();
    var count = 0;
    var lines = 0;
    for (final rune in value.runes) {
      buffer.writeCharCode(rune);
      count++;
      if (rune == 10) lines++;
      if (count >= 240 || lines >= 8) {
        result.add(buffer.toString());
        buffer = StringBuffer();
        count = 0;
        lines = 0;
      }
    }
    if (buffer.isNotEmpty || result.isEmpty) result.add(buffer.toString());
    return result;
  }
}
