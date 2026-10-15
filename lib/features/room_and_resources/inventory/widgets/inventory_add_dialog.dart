import 'package:flutter/material.dart';

typedef InventoryAddSave =
    Future<void> Function({
      required String itemName,
      required String category,
      required num quantity,
      String? formula,
      String? unit,
      String? expiration,
      String? conditionNotes,
    });

class InventoryAddDialog extends StatefulWidget {
  const InventoryAddDialog({super.key, required this.onSave});

  final InventoryAddSave onSave;

  @override
  State<InventoryAddDialog> createState() => _InventoryAddDialogState();
}

class _InventoryAddDialogState extends State<InventoryAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _formulaController = TextEditingController();
  final _conditionController = TextEditingController();
  String _category = 'Chemical';
  String _unit = 'mL';
  DateTime? _expirationDate;
  bool _saving = false;
  String? _saveError;

  bool get _isChemical => _category == 'Chemical';

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
                        _buildAssetSection(),
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
              'Add New Asset',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            tooltip: 'Close add asset dialog',
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
                'Asset type',
                'New inventory item',
                Icons.add_box_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildInfoCard(
                'Category',
                _category,
                Icons.inventory_2_outlined,
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

  Widget _buildAssetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asset details',
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
                SizedBox(width: fieldWidth, child: _buildCategoryField()),
                SizedBox(width: fieldWidth, child: _buildNameField()),
                SizedBox(width: fieldWidth, child: _buildQuantityField()),
                if (_isChemical) ...[
                  SizedBox(width: fieldWidth, child: _buildFormulaField()),
                  SizedBox(width: fieldWidth, child: _buildUnitField()),
                  SizedBox(width: fieldWidth, child: _buildExpirationField()),
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

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Chemical', child: Text('Chemical')),
        DropdownMenuItem(value: 'Equipment', child: Text('Equipment')),
        DropdownMenuItem(value: 'Glassware', child: Text('Glassware')),
      ],
      onChanged: _saving
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _category = value;
                _saveError = null;
              });
            },
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
    return DropdownButtonFormField<String>(
      initialValue: _unit,
      decoration: const InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'mL', child: Text('mL')),
        DropdownMenuItem(value: 'g', child: Text('g')),
      ],
      onChanged: _saving
          ? null
          : (value) {
              if (value != null) setState(() => _unit = value);
            },
    );
  }

  Widget _buildExpirationField() {
    final value = _expirationDate == null
        ? 'Select date'
        : _formatDate(_expirationDate!);
    return InkWell(
      onTap: _saving ? null : _pickExpirationDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expiration (optional)',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: _expirationDate == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
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
            key: const Key('inventory-add-save'),
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
                : const Icon(Icons.add, size: 18),
            label: Text(_saving ? 'Adding…' : 'Add asset'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() => _expirationDate = picked);
    }
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
        category: _category,
        quantity: quantity,
        formula: _formulaController.text.trim().isEmpty
            ? null
            : _formulaController.text.trim(),
        unit: _isChemical ? _unit : null,
        expiration: _expirationDate == null
            ? null
            : _formatDate(_expirationDate!),
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
            'This asset could not be added. Check the connection and try again.';
      });
    }
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
