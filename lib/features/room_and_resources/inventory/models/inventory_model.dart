class InventoryItem {
  final String itemId;
  final String itemName;
  final String category;
  final int quantity;
  final String status;
  final String stockLevel;
  final String? lastUpdated;
  final String? formula;
  final String? unit;
  final int? totalStock;
  final String? conditionNotes;

  InventoryItem({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.status,
    required this.stockLevel,
    this.lastUpdated,
    this.formula,
    this.unit,
    this.totalStock,
    this.conditionNotes,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle chemicals table
    if (json.containsKey('chemical_id')) {
      final stockQuantity = (json['stock_quantity'] as num?)?.toInt() ?? 0;
      return InventoryItem(
        itemId: json['chemical_id']?.toString() ?? '',
        itemName: json['chemical_name'] ?? '',
        category: 'Chemical',
        quantity: stockQuantity,
        status: stockQuantity == 0 ? 'Out of Stock' : 'Available',
        stockLevel: _calculateStockLevel(stockQuantity),
        lastUpdated: json['created_at']?.toString(),
        formula: json['formula'],
        unit: json['unit'],
      );
    }
    
    // Handle lab_assets table
    if (json.containsKey('asset_id')) {
      final availableStock = json['available_stock'] as int? ?? 0;
      final totalStock = json['total_stock'] as int? ?? 0;
      return InventoryItem(
        itemId: json['asset_id']?.toString() ?? '',
        itemName: json['item_name'] ?? '',
        category: json['category'] ?? '',
        quantity: availableStock,
        status: availableStock == 0 ? 'Out of Stock' : 'Available',
        stockLevel: _calculateStockLevel(availableStock),
        lastUpdated: json['created_at']?.toString(),
        totalStock: totalStock,
        conditionNotes: json['condition_notes'],
      );
    }
    
    // Fallback for legacy format
    return InventoryItem(
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? 'Available',
      stockLevel: json['stock_level'] ?? 'Medium',
      lastUpdated: json['last_updated'],
    );
  }

  static String _calculateStockLevel(int quantity) {
    if (quantity <= 3) return 'Low';
    if (quantity <= 10) return 'Medium';
    return 'High';
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'category': category,
      'quantity': quantity,
      'status': status,
      'stock_level': stockLevel,
      'last_updated': lastUpdated,
      'formula': formula,
      'unit': unit,
      'total_stock': totalStock,
      'condition_notes': conditionNotes,
    };
  }

  InventoryItem copyWith({
    String? itemId,
    String? itemName,
    String? category,
    int? quantity,
    String? status,
    String? stockLevel,
    String? lastUpdated,
    String? formula,
    String? unit,
    int? totalStock,
    String? conditionNotes,
  }) {
    return InventoryItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      stockLevel: stockLevel ?? this.stockLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      formula: formula ?? this.formula,
      unit: unit ?? this.unit,
      totalStock: totalStock ?? this.totalStock,
      conditionNotes: conditionNotes ?? this.conditionNotes,
    );
  }
}
