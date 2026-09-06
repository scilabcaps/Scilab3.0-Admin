import 'package:excel/excel.dart' as excel;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/reservations_history_model.dart';

class ReservationHistoryExportService {
  static const _headers = [
    'Reservation ID',
    'User Name',
    'Role',
    'Type',
    'Room / Item',
    'Date',
    'Time',
    'Status',
    'Created',
  ];

  List<List<String>> _rows(List<ReservationHistory> reservations) =>
      reservations
          .map((reservation) => [
                reservation.reservationId,
                reservation.userName,
                reservation.role,
                reservation.reservationType,
                reservation.roomItemReserved,
                reservation.reservationDate,
                reservation.timeSchedule,
                reservation.status,
                reservation.dateCreated,
              ])
          .toList();

  List<String> _summary({
    required int count,
    required String filtersDescription,
    required DateTime generatedAt,
  }) => [
        'Filters: $filtersDescription',
        'Generated: ${_formatTimestamp(generatedAt)} | Records: $count',
      ];

  Uint8List generateExcel({
    required List<ReservationHistory> reservations,
    required String filtersDescription,
    required DateTime generatedAt,
  }) {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Reservation History'];
    workbook.setDefaultSheet('Reservation History');
    workbook.delete('Sheet1');

    sheet.appendRow([excel.TextCellValue('Scilab Reservation History Report')]);
    for (final line in _summary(
      count: reservations.length,
      filtersDescription: filtersDescription,
      generatedAt: generatedAt,
    )) {
      sheet.appendRow([excel.TextCellValue(line)]);
    }
    sheet.appendRow([]);
    sheet.appendRow(_headers.map(excel.TextCellValue.new).toList());
    for (final row in _rows(reservations)) {
      sheet.appendRow(row.map(excel.TextCellValue.new).toList());
    }

    const headerRowIndex = 3;
    const firstDataRowIndex = headerRowIndex + 1;
    const widths = [18.0, 28.0, 15.0, 15.0, 32.0, 15.0, 22.0, 16.0, 20.0];
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
      for (var row = firstDataRowIndex;
          row < reservations.length + firstDataRowIndex;
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
    required List<ReservationHistory> reservations,
    required String filtersDescription,
    required DateTime generatedAt,
  }) async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
    final document = pw.Document(
      title: 'Scilab Reservation History Report',
      author: 'Scilab',
    );
    final rows = _rows(reservations);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'Scilab Reservation History Report',
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
          ..._summary(
            count: reservations.length,
            filtersDescription: filtersDescription,
            generatedAt: generatedAt,
          ).map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: _headers,
            data: rows,
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(1.8),
              2: pw.FlexColumnWidth(1.0),
              3: pw.FlexColumnWidth(1.0),
              4: pw.FlexColumnWidth(2.0),
              5: pw.FlexColumnWidth(1.1),
              6: pw.FlexColumnWidth(1.5),
              7: pw.FlexColumnWidth(1.1),
              8: pw.FlexColumnWidth(1.4),
            },
            headerAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
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
    String two(int value) => value.toString().padLeft(2, '0');
    final local = timestamp.toLocal();
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
