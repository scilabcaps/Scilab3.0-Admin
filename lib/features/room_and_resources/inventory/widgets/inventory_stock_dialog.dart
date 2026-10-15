import 'package:flutter/material.dart';

import '../models/inventory_model.dart';

typedef InventoryStockSave = Future<void> Function(num quantity);

class InventoryStockDialog extends StatefulWidget {
  const InventoryStockDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  final InventoryItem item;
  final InventoryStockSave onSave;

  @override
  State<InventoryStockDialog> createState() => _InventoryStockDialogState();
}

class _InventoryStockDialogState extends State<InventoryStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  bool _saving = false;
  String? _saveError;

  bool get _isChemical => widget.item.category.toLowerCase() == 'chemical';

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: _formatQuantity(widget.item.quantity),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummary(),
                        const SizedBox(height: 28),
                        _buildStockSection(),
                        if (_saveError != null) ...[
                          const SizedBox(height: 18),
                          _buildErrorMessage(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 20),
      color: const Color(0xFF247A2A),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Update Stock',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            tooltip: 'Close update stock dialog',
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 560;
        final width = twoColumns
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: width,
              child: _buildInfoCard(
                'Asset',
                widget.item.itemName,
                Icons.inventory_2_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildInfoCard(
                'Category',
                widget.item.category,
                Icons.category_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildInfoCard(
                'Current quantity',
                '${_formatQuantity(widget.item.quantity)} $_unitLabel',
                Icons.stacked_bar_chart_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF247A2A), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF245A2A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF26352A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock details',
          style: TextStyle(
            color: Color(0xFF245A2A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF247A2A), height: 1),
        const SizedBox(height: 18),
        TextFormField(
          controller: _quantityController,
          enabled: !_saving,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: _isChemical),
          decoration: InputDecoration(
            labelText: _isChemical
                ? 'Amount ($_unitLabel)'
                : 'Quantity (pieces)',
            helperText: 'Enter the new available stock level.',
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final quantity = _isChemical
                ? num.tryParse(value ?? '')
                : int.tryParse(value ?? '');
            if (quantity == null) return 'Enter a valid quantity';
            if (quantity < 0) return 'Quantity cannot be negative';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF9A2E2E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _saveError!,
              style: const TextStyle(color: Color(0xFF722525)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      alignment: Alignment.centerRight,
      color: const Color(0xFFF7FAF7),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            key: const Key('inventory-stock-save'),
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF247A2A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_saving ? 'Updating…' : 'Update stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final quantity = _isChemical
        ? num.parse(_quantityController.text)
        : int.parse(_quantityController.text);
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(quantity);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Stock could not be updated. Check the connection and try again.';
      });
    }
  }

  String get _unitLabel => _isChemical ? (widget.item.unit ?? 'mL') : 'pieces';

  String _formatQuantity(num quantity) {
    return quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
  }
}
