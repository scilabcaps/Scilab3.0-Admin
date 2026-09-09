import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../models/inventory_model.dart';

class ReportDialog extends StatefulWidget {
  final List<InventoryItem> inventoryItems;
  final VoidCallback onRefresh;

  const ReportDialog({
    super.key,
    required this.inventoryItems,
    required this.onRefresh,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String selectedCategory = 'all';
  String selectedStatus = '';
  String selectedStockLevel = '';
  int currentPage = 1;
  int itemsPerPage = 10;

  List<InventoryItem> get filteredItems {
    var items = widget.inventoryItems;

    // Filter by category
    if (selectedCategory != 'all') {
      items = items.where((item) {
        switch (selectedCategory) {
          case 'equipment':
            return item.category.toLowerCase() == 'equipment';
          case 'chemical':
            return item.category.toLowerCase() == 'chemical';
          case 'glassware':
            return item.category.toLowerCase() == 'glassware';
          default:
            return true;
        }
      }).toList();
    }

    // Filter by status
    if (selectedStatus.isNotEmpty) {
      items = items.where((item) => item.status == selectedStatus).toList();
    }

    // Filter by stock level
    if (selectedStockLevel.isNotEmpty) {
      items = items.where((item) => item.stockLevel == selectedStockLevel).toList();
    }

    return items;
  }

  List<InventoryItem> get paginatedItems {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return filteredItems.length > startIndex
        ? filteredItems.sublist(startIndex, endIndex > filteredItems.length ? filteredItems.length : endIndex)
        : [];
  }

  int get totalPages => (filteredItems.length / itemsPerPage).ceil();

  Future<void> _exportToExcel() async {
    try {
      final excelFile = excel.Excel.createExcel();
      
      // Delete default sheet if it exists
      excelFile.delete('Sheet1');
      
      final sheet = excelFile['Inventory Report'];

      // Add headers with styling
      final headerStyle = excel.CellStyle(
        backgroundColorHex: excel.ExcelColor.fromHexString('#4CAF50'),
        fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
      );

      sheet.appendRow([
        excel.TextCellValue('Item Name'),
        excel.TextCellValue('Category'),
        excel.TextCellValue('Quantity'),
        excel.TextCellValue('Status'),
        excel.TextCellValue('Stock Level'),
        excel.TextCellValue('Last Updated'),
        excel.TextCellValue('Expiration'),
      ]);

      // Apply header style to first row
      for (int i = 0; i < 7; i++) {
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      // Add data - use filtered items if filters are applied, otherwise use all items
      final itemsToExport = filteredItems.isNotEmpty ? filteredItems : widget.inventoryItems;
      
      debugPrint('Exporting ${itemsToExport.length} items to Excel');
      debugPrint('Total inventory items: ${widget.inventoryItems.length}');
      debugPrint('Filtered items: ${filteredItems.length}');
      
      // Track max lengths for each column to auto-adjust widths
      final List<int> maxColumnLengths = [10, 8, 8, 10, 11, 16, 10]; // Initial values based on headers

      for (final item in itemsToExport) {
        String formattedDate = '-';
        if (item.lastUpdated != null && item.lastUpdated != '-') {
          try {
            final dateTime = DateTime.parse(item.lastUpdated!);
            formattedDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            formattedDate = item.lastUpdated ?? '-';
          }
        }

        String formattedExpiration = '-';
        if (item.expiration != null && item.expiration!.isNotEmpty) {
          formattedExpiration = _formatDate(item.expiration);
        }

        final values = [
          item.itemName,
          item.category,
          '${item.quantity}${item.category.toLowerCase() == 'chemical' ? ' ${item.unit ?? 'mL'}' : ' pieces'}',
          item.status,
          item.stockLevel,
          formattedDate,
          formattedExpiration,
        ];
        
        // Update max lengths
        for (int i = 0; i < values.length; i++) {
          if (values[i].length > maxColumnLengths[i]) {
            maxColumnLengths[i] = values[i].length;
          }
        }
        
        sheet.appendRow([
          excel.TextCellValue(item.itemName),
          excel.TextCellValue(item.category),
          excel.TextCellValue(
            '${item.quantity}${item.category.toLowerCase() == 'chemical' ? ' ${item.unit ?? 'mL'}' : ' pieces'}',
          ),
          excel.TextCellValue(item.status),
          excel.TextCellValue(item.stockLevel),
          excel.TextCellValue(formattedDate),
          excel.TextCellValue(formattedExpiration),
        ]);
      }
      
      debugPrint('Excel rows added: ${itemsToExport.length}');

      // Auto-adjust column widths based on max content length
      for (int i = 0; i < maxColumnLengths.length; i++) {
        final columnWidth = (maxColumnLengths[i] * 1.2).round(); // Add some padding
        sheet.setColumnWidth(i, columnWidth.toDouble());
      }

      // Set the 'Inventory Report' sheet as the active/default sheet
      excelFile.setDefaultSheet('Inventory Report');

      // Let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Inventory Report',
        fileName: 'inventory_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final bytes = excelFile.encode();
        if (bytes != null) {
          final file = File(result);
          await file.writeAsBytes(bytes);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report saved to: $result'),
                duration: const Duration(seconds: 3),
                backgroundColor: const Color(0xFF31CB00),
              ),
            );

            // Show dialog to ask if user wants to open the file
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Open Report?'),
                content: const Text('Do you want to open the generated report?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await OpenFile.open(result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF31CB00),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting to Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final regular = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
      final bold = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
      final itemsToExport =
          filteredItems.isNotEmpty ? filteredItems : widget.inventoryItems;
      final document = pw.Document(title: 'Scilab Inventory Report', author: 'Scilab');
      final rows = itemsToExport.map((item) => [
        item.itemName,
        item.category,
        '${item.quantity}${item.category.toLowerCase() == 'chemical' ? ' ${item.unit ?? 'mL'}' : ' pieces'}',
        item.status,
        item.stockLevel,
        item.lastUpdated ?? '-',
        item.expiration == null || item.expiration!.isEmpty
            ? '-'
            : _formatDate(item.expiration),
      ]).toList();

      document.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: itemsToExport.length + 20,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text('Scilab Inventory Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8)),
        ),
        build: (_) => [
          pw.Text(
              'Category: ${selectedCategory == 'all' ? 'All' : selectedCategory} | '
              'Status: ${selectedStatus.isEmpty ? 'All' : selectedStatus} | '
              'Stock Level: ${selectedStockLevel.isEmpty ? 'All' : selectedStockLevel}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
              'Generated: ${_formatDateTime(DateTime.now())} | Records: ${itemsToExport.length}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Item Name', 'Category', 'Quantity', 'Status', 'Stock Level',
              'Last Updated', 'Expiration'
            ],
            data: rows,
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0), 1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(0.8), 3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.2), 5: pw.FlexColumnWidth(1.7),
              6: pw.FlexColumnWidth(1.4),
            },
            headerAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontSize: 8, color: PdfColors.white,
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
      ));

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Inventory Report',
        fileName: 'inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null) return;
      await File(result).writeAsBytes(await document.save(), flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('PDF report saved to: $result'),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF31CB00),
      ));
      await _askToOpenReport(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error exporting to PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _askToOpenReport(String path) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Report?'),
        content: const Text('Do you want to open the generated report?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await OpenFile.open(path);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF31CB00),
                foregroundColor: Colors.white),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == '-' || dateStr.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(dateStr);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategory = 'all';
      selectedStatus = '';
      selectedStockLevel = '';
      currentPage = 1;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFFD4EDDA);
      case 'in use':
        return const Color(0xFFD1ECF1);
      case 'borrowed':
        return const Color(0xFFFFF3CD);
      case 'reserved':
        return const Color(0xFFE2E3E5);
      case 'damaged':
        return const Color(0xFFF8D7DA);
      case 'maintenance':
        return const Color(0xFFE2E3E5);
      case 'expired':
        return const Color(0xFFF8D7DA);
      case 'out of stock':
        return const Color(0xFFF8D7DA);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF155724);
      case 'in use':
        return const Color(0xFF0C5460);
      case 'borrowed':
        return const Color(0xFF856404);
      case 'reserved':
        return const Color(0xFF383D41);
      case 'damaged':
        return const Color(0xFF721C24);
      case 'maintenance':
        return const Color(0xFF383D41);
      case 'expired':
        return const Color(0xFF721C24);
      case 'out of stock':
        return const Color(0xFF721C24);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStockLevelColor(String stockLevel) {
    switch (stockLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFFFFF3CD);
      case 'medium':
        return const Color(0xFFD1ECF1);
      case 'high':
        return const Color(0xFFD4EDDA);
      case 'out':
        return const Color(0xFFF8D7DA);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStockLevelTextColor(String stockLevel) {
    switch (stockLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFF856404);
      case 'medium':
        return const Color(0xFF0C5460);
      case 'high':
        return const Color(0xFF155724);
      case 'out':
        return const Color(0xFF721C24);
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventory Report Generation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: widget.onRefresh,
                        tooltip: 'Refresh',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFilters(),
              const SizedBox(height: 20),
              Expanded(
                child: _buildReportResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.end,
            children: [
              _buildFilterDropdown(
                label: 'Category',
                value: selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Categories')),
                  DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                  DropdownMenuItem(value: 'chemical', child: Text('Chemical')),
                  DropdownMenuItem(value: 'glassware', child: Text('Glassware')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value ?? 'all';
                  });
                },
              ),
              _buildFilterDropdown(
                label: 'Status',
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'Available', child: Text('Available')),
                  DropdownMenuItem(value: 'In Use', child: Text('In Use')),
                  DropdownMenuItem(value: 'Borrowed', child: Text('Borrowed')),
                  DropdownMenuItem(value: 'Reserved', child: Text('Reserved')),
                  DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                  DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                  DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value ?? '';
                  });
                },
              ),
              _buildFilterDropdown(
                label: 'Stock Level',
                value: selectedStockLevel,
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Levels')),
                  DropdownMenuItem(value: 'Low', child: Text('Low Stock')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium Stock')),
                  DropdownMenuItem(value: 'High', child: Text('High Stock')),
                  DropdownMenuItem(value: 'Out', child: Text('Out of Stock')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedStockLevel = value ?? '';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C757D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset Filters'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _exportToExcel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C757D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Export Excel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _exportToPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C757D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Export PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value.isEmpty ? null : value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildReportResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: paginatedItems.isEmpty
                ? _buildEmptyState()
                : _buildInventoryTable(),
          ),
          if (filteredItems.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Apply filters and click "Generate Report" to view inventory data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTableHeader(),
          ...paginatedItems.map((item) => _buildInventoryRow(item)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 1, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Stock Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Last Updated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Expiration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(InventoryItem item) {
    String formattedExpiration = '-';
    if (item.expiration != null && item.expiration!.isNotEmpty) {
      formattedExpiration = _formatDate(item.expiration);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.itemName),
          ),
          Expanded(
            flex: 2,
            child: Text(item.category),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.quantity}${item.category.toLowerCase() == 'chemical' ? ' ${item.unit ?? 'mL'}' : ' pieces'}',
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildStatusBadge(item.status),
          ),
          Expanded(
            flex: 2,
            child: _buildStockLevelBadge(item.stockLevel),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatDate(item.lastUpdated)),
          ),
          Expanded(
            flex: 2,
            child: Text(formattedExpiration),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusTextColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStockLevelBadge(String stockLevel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStockLevelColor(stockLevel),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stockLevel,
        style: TextStyle(
          color: _getStockLevelTextColor(stockLevel),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Show: '),
              DropdownButton<int>(
                value: itemsPerPage,
                items: const [10, 25, 50].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    itemsPerPage = value ?? 10;
                    currentPage = 1;
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: currentPage > 1
                    ? () {
                        setState(() {
                          currentPage--;
                        });
                      }
                    : null,
              ),
              Text('Page $currentPage of $totalPages'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: currentPage < totalPages
                    ? () {
                        setState(() {
                          currentPage++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
