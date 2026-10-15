import 'package:flutter/material.dart';

import '../models/inventory_model.dart';

typedef InventoryEditSave =
    Future<void> Function({
      required String itemName,
      required num quantity,
      String? formula,
      String? unit,
      String? conditionNotes,
    });

class InventoryEditDialog extends StatefulWidget {
  const InventoryEditDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  final InventoryItem item;
  final InventoryEditSave onSave;

  @override
  State<InventoryEditDialog> createState() => _InventoryEditDialogState();
}

class _InventoryEditDialogState extends State<InventoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _formulaController;
  late final TextEditingController _conditionController;
  late String _unit;
  bool _saving = false;
  String? _saveError;

  bool get _isChemical => widget.item.category.toLowerCase() == 'chemical';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _quantityController = TextEditingController(
      text: _formatQuantity(widget.item.quantity),
    );
    _formulaController = TextEditingController(text: widget.item.formula ?? '');
    _conditionController = TextEditingController(
      text: widget.item.conditionNotes ?? '',
    );
    _unit = widget.item.unit?.isNotEmpty == true ? widget.item.unit! : 'mL';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _formulaController.dispose();
    _conditionController.dispose();
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
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
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
                        _buildEditSection(),
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
          Expanded(
            child: Text(
              _isChemical ? 'Edit Chemical' : 'Edit Asset',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            tooltip: 'Close edit dialog',
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final fields = <Widget>[
      _buildInfoCard('Asset ID', widget.item.itemId, Icons.tag_outlined),
      _buildInfoCard(
        'Category',
        widget.item.category,
        Icons.inventory_2_outlined,
      ),
      if (_isChemical)
        _buildInfoCard(
          'Expiration',
          _formatExpiration(widget.item.expiration),
          Icons.lock_outline,
          helperText: 'Expiration cannot be edited',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final width = columns == 2
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: fields
              .map((field) => SizedBox(width: width, child: field))
              .toList(),
        );
      },
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    String? helperText,
  }) {
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
                if (helperText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    helperText,
                    style: const TextStyle(
                      color: Color(0xFF526B57),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Details',
          style: TextStyle(
            color: Color(0xFF245A2A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF247A2A), height: 1),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 560;
            final fieldWidth = twoColumns
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(width: fieldWidth, child: _buildNameField()),
                SizedBox(width: fieldWidth, child: _buildQuantityField()),
                if (_isChemical) ...[
                  SizedBox(width: fieldWidth, child: _buildFormulaField()),
                  SizedBox(width: fieldWidth, child: _buildUnitField()),
                ] else
                  SizedBox(
                    width: constraints.maxWidth,
                    child: _buildConditionField(),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      enabled: !_saving,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Item name',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Enter an item name' : null,
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      enabled: !_saving,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.numberWithOptions(decimal: _isChemical),
      decoration: const InputDecoration(
        labelText: 'Quantity',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final quantity = _isChemical
            ? num.tryParse(value ?? '')
            : int.tryParse(value ?? '');
        if (quantity == null) return 'Enter a valid quantity';
        if (quantity < 0) return 'Quantity cannot be negative';
        return null;
      },
    );
  }

  Widget _buildFormulaField() {
    return TextFormField(
      controller: _formulaController,
      enabled: !_saving,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Formula (optional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildUnitField() {
    final units = <String>{'mL', 'g', _unit}.toList();
    return DropdownButtonFormField<String>(
      initialValue: _unit,
      decoration: const InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(),
      ),
      items: units
          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
          .toList(),
      onChanged: _saving
          ? null
          : (value) {
              if (value != null) setState(() => _unit = value);
            },
    );
  }

  Widget _buildConditionField() {
    return TextFormField(
      controller: _conditionController,
      enabled: !_saving,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Condition notes (optional)',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
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
            key: const Key('inventory-edit-save'),
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
            label: Text(_saving ? 'Saving…' : 'Save changes'),
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
      await widget.onSave(
        itemName: _nameController.text.trim(),
        quantity: quantity,
        formula: _formulaController.text.trim().isEmpty
            ? null
            : _formulaController.text.trim(),
        unit: _isChemical ? _unit : null,
        conditionNotes: _conditionController.text.trim().isEmpty
            ? null
            : _conditionController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Changes could not be saved. Check the connection and try again.';
      });
    }
  }

  String _formatQuantity(num quantity) {
    return quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
  }

  String _formatExpiration(String? value) {
    if (value == null || value.trim().isEmpty || value == '-') return 'Not set';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
