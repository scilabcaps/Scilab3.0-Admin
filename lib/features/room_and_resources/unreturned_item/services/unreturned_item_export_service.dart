import 'package:excel/excel.dart' as excel;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/unreturned_item_model.dart';

class UnreturnedItemExportService {
  static const _headers = [
    'Detail ID',
    'Reservation ID',
    'Item',
    'Category',
    'Borrower',
    'Role',
    'Borrowed',
    'Returned',
    'Unreturned',
    'Reservation Date',
  ];

  List<List<String>> _rows(List<UnreturnedItem> items) => items
      .map((item) => [
            item.detailId,
            item.reservationId,
            item.itemName,
            item.itemType,
            item.borrowerName,
            item.borrowerType,
            item.borrowedQuantity.toString(),
            item.returnedQuantity.toString(),
            item.unreturnedQuantity.toString(),
            item.reservationDate,
          ])
      .toList();

  Uint8List generateExcel({
    required List<UnreturnedItem> items,
    required String filtersDescription,
    required DateTime generatedAt,
  }) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Unreturned Items'];
    workbook.setDefaultSheet('Unreturned Items');
    workbook.delete('Sheet1');
    sheet.appendRow([excel.TextCellValue('Scilab Unreturned Items Report')]);
    sheet.appendRow([excel.TextCellValue('Filters: $filtersDescription')]);
    sheet.appendRow([
      excel.TextCellValue(
          'Generated: ${_formatTimestamp(generatedAt)} | Records: ${items.length}'),
    ]);
    sheet.appendRow(_headers.map(excel.TextCellValue.new).toList());
    for (final row in _rows(items)) {
      sheet.appendRow(row.map(excel.TextCellValue.new).toList());
    }

    const widths = [14.0, 17.0, 28.0, 18.0, 28.0, 16.0, 12.0, 12.0, 14.0, 20.0];
    const headerRowIndex = 3;
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
          row < items.length + headerRowIndex + 1;
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
    required List<UnreturnedItem> items,
    required String filtersDescription,
    required DateTime generatedAt,
  }) async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
    final document = pw.Document(
      title: 'Scilab Unreturned Items Report',
      author: 'Scilab',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: items.length + 20,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'Scilab Unreturned Items Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (_) => [
          pw.Text('Filters: $filtersDescription',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
              'Generated: ${_formatTimestamp(generatedAt)} | Records: ${items.length}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: _headers,
            data: _rows(items),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.0),
              1: pw.FlexColumnWidth(1.1),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.8),
              5: pw.FlexColumnWidth(1.0),
              6: pw.FlexColumnWidth(0.8),
              7: pw.FlexColumnWidth(0.8),
              8: pw.FlexColumnWidth(0.9),
              9: pw.FlexColumnWidth(1.2),
            },
            headerAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF245C35)),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.all(4),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey100),
            border: null,
          ),
        ],
      ),
    );
    return document.save();
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
