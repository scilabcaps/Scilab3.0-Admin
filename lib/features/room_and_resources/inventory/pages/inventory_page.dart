import 'package:flutter/material.dart';
import '../../../../core/utils/table_loading_indicator.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_model.dart';
import '../widgets/inventory_add_dialog.dart';
import '../widgets/inventory_edit_dialog.dart';
import '../widgets/inventory_stock_dialog.dart';
import '../widgets/report_dialog.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryController _controller = InventoryController();

  String _formatQuantity(num quantity) {
    return quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
  }

  String _formatExpiration(String value) {
    try {
      final date = DateTime.parse(value);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadInventory();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _generateReport() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        inventoryItems: _controller.inventoryItems,
        onRefresh: _controller.loadInventory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: const Color(0xFFE8F5E9),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Inventory Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _controller.refresh();
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF152614),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _showAddAssetDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Asset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF31CB00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _generateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF31CB00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Generate Report'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildInventoryTabs()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventoryTabs() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildTabButton('Chemicals', 'chemicals'),
                    const SizedBox(width: 8),
                    _buildTabButton('Equipment', 'equipment'),
                    const SizedBox(width: 8),
                    _buildTabButton('Glassware', 'glassware'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, String tabValue) {
    final isSelected = _controller.selectedTab == tabValue;
    return Expanded(
      child: InkWell(
        onTap: () {
          _controller.setSelectedTab(tabValue);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF31CB00) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search inventory...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                _controller.setSearchTerm(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_controller.isLoading) return const TableLoadingIndicator();
    final tabItems = _controller.filteredItems;

    if (tabItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_controller.selectedTab.capitalize()} found',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tabItems.length,
      itemBuilder: (context, index) {
        final item = tabItems[index];
        return _buildInventoryCard(item);
      },
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category.toLowerCase() == 'chemical'
                      ? 'Stock: ${_formatQuantity(item.quantity)} ${item.unit ?? 'mL'}'
                      : 'Quantity: ${item.quantity.toInt()} pieces',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (item.category.toLowerCase() == 'chemical' &&
                    item.expiration != null &&
                    item.expiration!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expires: ${_formatExpiration(item.expiration!)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () {
              _showUpdateStockDialog(item);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF31CB00),
              side: const BorderSide(color: Color(0xFF31CB00)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update Stock'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showEditAssetDialog(item),
            icon: const Icon(Icons.edit, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF31CB00),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _showDeleteAssetDialog(item),
            icon: const Icon(Icons.delete, size: 20),
            style: IconButton.styleFrom(foregroundColor: Colors.red),
          ),
          const SizedBox(width: 12),
          _buildStatusBadge(item.status),
          if (item.stockLevel == 'Low') ...[
            const SizedBox(width: 8),
            _buildStockLevelBadge(item.stockLevel),
          ],
        ],
      ),
    );
  }

  void _showUpdateStockDialog(InventoryItem item) {
    showDialog<bool>(
      context: context,
      builder: (context) => InventoryStockDialog(
        item: item,
        onSave: (quantity) async {
          debugPrint(
            'Update button pressed: itemId=${item.itemId}, category=${item.category}, newQuantity=$quantity',
          );
          await _controller.updateStock(item.itemId, item.category, quantity);
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _controller.getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _controller.getStatusTextColor(status),
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
        color: _controller.getStockLevelColor(stockLevel),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stockLevel,
        style: TextStyle(
          color: _controller.getStockLevelTextColor(stockLevel),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAddAssetDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => InventoryAddDialog(
        onSave:
            ({
              required itemName,
              required category,
              required quantity,
              formula,
              unit,
              expiration,
              conditionNotes,
            }) => _controller.addAsset(
              itemName: itemName,
              category: category,
              quantity: quantity,
              formula: formula,
              unit: unit,
              expiration: expiration,
              conditionNotes: conditionNotes,
            ),
      ),
    ).then((added) {
      if (added == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset added successfully'),
            backgroundColor: Color(0xFF31CB00),
          ),
        );
      }
    });
  }

  Future<void> _showEditAssetDialog(InventoryItem item) async {
    final updated = await showDialog<bool>(
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
            }) => _controller.editAsset(
              itemId: item.itemId,
              category: item.category,
              itemName: itemName,
              quantity: quantity,
              formula: formula,
              unit: unit,
              conditionNotes: conditionNotes,
            ),
      ),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset updated successfully'),
          backgroundColor: Color(0xFF31CB00),
        ),
      );
    }
  }

  void _showDeleteAssetDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Are you sure you want to delete "${item.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _controller.deleteAsset(item.itemId, item.category);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Asset deleted successfully'),
                  backgroundColor: Color(0xFF31CB00),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
