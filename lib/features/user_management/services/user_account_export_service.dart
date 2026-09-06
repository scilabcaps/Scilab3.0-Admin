import 'package:excel/excel.dart' as excel;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/user_model.dart';

class UserAccountExportService {
  static const _headers = [
    'Name',
    'Email',
    'Phone',
    'User ID',
    'Role',
    'Created',
    'Status',
  ];

  List<List<String>> _rows(List<User> users) => users
      .map((user) => [
            user.displayName.isEmpty ? user.fullName.trim() : user.displayName,
            user.email,
            user.phone ?? '',
            user.userId,
            user.userType,
            user.createdAt?.toLocal().toIso8601String() ?? '',
            user.isBanned ? 'Banned' : 'Active',
          ])
      .toList();

  Uint8List generateExcel({
    required List<User> users,
    required String role,
    required DateTime generatedAt,
  }) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['User Accounts'];
    workbook.setDefaultSheet('User Accounts');
    workbook.delete('Sheet1');
    sheet.appendRow([excel.TextCellValue('Scilab ${role}s Account Report')]);
    sheet.appendRow([
      excel.TextCellValue(
          'Role: $role | Generated: ${_formatTimestamp(generatedAt)} | Records: ${users.length}'),
    ]);
    sheet.appendRow(_headers.map(excel.TextCellValue.new).toList());
    for (final row in _rows(users)) {
      sheet.appendRow(row.map(excel.TextCellValue.new).toList());
    }

    const widths = [28.0, 32.0, 20.0, 38.0, 16.0, 24.0, 14.0];
    const headerRowIndex = 2;
    for (var column = 0; column < widths.length; column++) {
      sheet.setColumnWidth(column, widths[column]);
      sheet
          .cell(excel.CellIndex.indexByColumnRow(
              columnIndex: column, rowIndex: headerRowIndex))
          .cellStyle = excel.CellStyle(
        bold: true,
        backgroundColorHex: excel.ExcelColor.fromHexString('#245C35'),
        fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
      );
      for (var row = headerRowIndex + 1;
          row < users.length + headerRowIndex + 1;
          row++) {
        sheet
            .cell(excel.CellIndex.indexByColumnRow(
                columnIndex: column, rowIndex: row))
            .cellStyle = excel.CellStyle(
          textWrapping: excel.TextWrapping.WrapText,
          verticalAlign: excel.VerticalAlign.Top,
        );
      }
    }
    return Uint8List.fromList(workbook.encode()!);
  }

  Future<Uint8List> generatePdf({
    required List<User> users,
    required String role,
    required DateTime generatedAt,
  }) async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
    final document = pw.Document(
        title: 'Scilab $role Account Report', author: 'Scilab');
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      maxPages: users.length + 20,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Text('Scilab $role Account Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (_) => [
        pw.Text(
            'Generated: ${_formatTimestamp(generatedAt)} | Records: ${users.length}',
            style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: _headers,
          data: _rows(users),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.8),
            1: pw.FlexColumnWidth(2.2),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(2.5),
            4: pw.FlexColumnWidth(1.0),
            5: pw.FlexColumnWidth(1.8),
            6: pw.FlexColumnWidth(1.0),
          },
          headerAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontSize: 8,
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF245C35)),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellPadding: const pw.EdgeInsets.all(4),
          oddRowDecoration:
              const pw.BoxDecoration(color: PdfColors.grey100),
          border: null,
        ),
      ],
    ));
    return document.save();
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
