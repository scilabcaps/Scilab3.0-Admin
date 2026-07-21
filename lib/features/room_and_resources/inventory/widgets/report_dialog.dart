import 'package:flutter/material.dart';
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
  DateTime? startDate;
  DateTime? endDate;
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

  void _generateReport() {
    setState(() {
      currentPage = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report generated successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      selectedCategory = 'all';
      selectedStatus = '';
      selectedStockLevel = '';
      startDate = null;
      endDate = null;
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
                    '📊 Inventory Report Generation',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 20,
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
              _buildDateFilter(
                label: 'Start Date',
                value: startDate,
                onChanged: (value) {
                  setState(() {
                    startDate = value;
                  });
                },
              ),
              _buildDateFilter(
                label: 'End Date',
                value: endDate,
                onChanged: (value) {
                  setState(() {
                    endDate = value;
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
                onPressed: _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF31CB00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Generate Report'),
              ),
              const SizedBox(width: 12),
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
                onPressed: () {
                  // TODO: Implement export to Excel
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C757D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Export Excel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement print
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C757D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Print'),
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
            value: value.isEmpty ? null : value,
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

  Widget _buildDateFilter({
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
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
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    value != null
                        ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
                        : 'Select Date',
                    style: TextStyle(
                      color: value != null ? Colors.black : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
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
          paginatedItems.isEmpty
              ? _buildEmptyState()
              : _buildInventoryTable(),
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
      child: DataTable(
        columns: const [
          DataColumn(
            label: Text(
              'Item Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Quantity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Stock Level',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Last Updated',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: paginatedItems.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.itemName)),
              DataCell(Text(item.category)),
              DataCell(Text(item.quantity.toString())),
              DataCell(_buildStatusBadge(item.status)),
              DataCell(_buildStockLevelBadge(item.stockLevel)),
              DataCell(Text(item.lastUpdated ?? '-')),
            ],
          );
        }).toList(),
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
