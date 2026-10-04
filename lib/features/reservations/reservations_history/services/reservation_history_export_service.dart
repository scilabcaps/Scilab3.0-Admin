import 'package:excel/excel.dart' as excel;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/reservations_history_model.dart';

class ReservationHistoryExportService {
  static const _headers = [
    'Reservation ID',
    'Full Name',
    'Role',
    'Created By',
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
                '${reservation.createdByType}: ${reservation.createdByName}',
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
    const widths = [18.0, 28.0, 15.0, 30.0, 15.0, 32.0, 15.0, 22.0, 16.0, 20.0];
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

  Future<Uint8List> generateReceiptPdf({
    required ReservationHistory reservation,
    required DateTime generatedAt,
  }) async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
    final document = pw.Document(
      title: 'Reservation Receipt ${reservation.reservationId}',
      author: 'SciLab Reserve',
    );
    final items = reservation.items ?? const <ReservedItem>[];
    final green = PdfColor.fromInt(0xFF245C35);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (_) => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: green, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SciLab Reserve',
                    style: pw.TextStyle(
                      color: green,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'RESERVATION RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 19,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Text(
                'Receipt #${reservation.reservationId}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Text(
            'Generated ${_formatTimestamp(generatedAt)}  |  '
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 22),
          pw.Text(
            'Reservation details',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(125),
              1: pw.FlexColumnWidth(),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            children: [
              _receiptRow('Reservation ID', reservation.reservationId),
              _receiptRow('Full name', reservation.userName),
              _receiptRow('Role', reservation.role),
              _receiptRow('Reservation type', reservation.reservationType),
              _receiptRow('Room / item', reservation.roomItemReserved),
              _receiptRow('Reservation date', reservation.reservationDate),
              _receiptRow('Time schedule', reservation.timeSchedule),
              _receiptRow('Status', reservation.status),
              _receiptRow('Date created', reservation.dateCreated),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Reserved items',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (items.isEmpty)
            pw.Text(
              'No item details recorded for this reservation.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Item', 'Quantity', 'Returned', 'Status'],
              data: items
                  .map((item) => [
                        item.itemName,
                        item.quantity.toString(),
                        item.returnedQuantity.toString(),
                        item.status,
                      ])
                  .toList(),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1.5),
              },
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: pw.BoxDecoration(color: green),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'This document serves as a printable record of the reservation.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.TableRow _receiptRow(String label, String value) => pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      );

  String _formatTimestamp(DateTime timestamp) {
    String two(int value) => value.toString().padLeft(2, '0');
    final local = timestamp.toLocal();
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
