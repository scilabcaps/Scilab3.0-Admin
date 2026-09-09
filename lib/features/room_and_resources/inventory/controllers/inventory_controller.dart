import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../../../../core/api/supabase_client.dart';
import '../../../../core/api/supabase_config.dart';
import '../../../../core/service/cache_service.dart';
import '../../../audit/services/audit_service.dart';

class InventoryController extends ChangeNotifier {
  List<InventoryItem> _inventoryItems = [];
  String _selectedTab = 'chemicals';
  String _searchTerm = '';
  final CacheService _cache = CacheService();
  final AuditService _auditService = AuditService();

  List<InventoryItem> get inventoryItems => _inventoryItems;
  String get selectedTab => _selectedTab;
  String get searchTerm => _searchTerm;

  List<InventoryItem> get filteredItems {
    return _inventoryItems.where((item) {
      final matchesCategory = switch (_selectedTab) {
        'chemicals' => item.category.toLowerCase() == 'chemical',
        'equipment' => item.category.toLowerCase() == 'equipment',
        'glassware' => item.category.toLowerCase() == 'glassware',
        _ => true,
      };
      final matchesSearch = item.itemName.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> loadInventory() async {
    final cacheKey = 'inventory_items';
    
    // Try to get from cache first
    final cachedItems = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedItems != null) {
      _inventoryItems = cachedItems.map((data) => InventoryItem.fromJson(data)).toList();
      notifyListeners();
      return;
    }

    try {
      final chemicalsResponse = await SupabaseService.database
          .from(SupabaseConfig.tableChemicals)
          .select()
          .order('chemical_name');

      final labAssetsResponse = await SupabaseService.database
          .from(SupabaseConfig.tableLabAssets)
          .select()
          .order('item_name');

      final List<InventoryItem> items = [];

      for (final chemical in chemicalsResponse) {
        items.add(InventoryItem.fromJson(chemical));
      }

      for (final asset in labAssetsResponse) {
        items.add(InventoryItem.fromJson(asset));
      }

      _inventoryItems = items;
      notifyListeners();

      // Cache the result with 30 minute TTL (inventory changes slowly)
      await _cache.set(cacheKey, items.map((item) => item.toJson()).toList(), ttlMinutes: 30);
    } catch (e) {
      debugPrint('Error loading inventory: $e');
      _inventoryItems = _getMockInventory();
      notifyListeners();
    }
  }

  List<InventoryItem> _getMockInventory() {
    return [
      InventoryItem(
        itemId: '1',
        itemName: 'Sulfuric Acid',
        category: 'Chemical',
        quantity: 5,
        status: 'Available',
        stockLevel: 'Low',
        lastUpdated: '2026-06-28',
      ),
      InventoryItem(
        itemId: '2',
        itemName: 'Microscope',
        category: 'Equipment',
        quantity: 15,
        status: 'Available',
        stockLevel: 'High',
        lastUpdated: '2026-06-27',
      ),
      InventoryItem(
        itemId: '3',
        itemName: 'Beaker 500ml',
        category: 'Glassware',
        quantity: 30,
        status: 'In Use',
        stockLevel: 'Medium',
        lastUpdated: '2026-06-28',
      ),
      InventoryItem(
        itemId: '4',
        itemName: 'Hydrochloric Acid',
        category: 'Chemical',
        quantity: 2,
        status: 'Available',
        stockLevel: 'Low',
        lastUpdated: '2026-06-25',
      ),
      InventoryItem(
        itemId: '5',
        itemName: 'Test Tube Rack',
        category: 'Glassware',
        quantity: 0,
        status: 'Out of Stock',
        stockLevel: 'Out',
        lastUpdated: '2026-06-20',
      ),
    ];
  }

  void setSelectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  Future<void> updateStock(String itemId, String category, num newQuantity) async {
    debugPrint('updateStock called: itemId=$itemId, category=$category, newQuantity=$newQuantity');
    debugPrint('Current inventory items count: ${_inventoryItems.length}');
    
    // Find item by matching both itemId AND category to avoid ID conflicts
    final index = _inventoryItems.indexWhere((i) => i.itemId == itemId && i.category.toLowerCase() == category.toLowerCase());
    debugPrint('Item index found by itemId and category: $index');
    
    if (index == -1) {
      debugPrint('Item not found in inventory list with itemId=$itemId and category=$category');
      return;
    }
    
    final item = _inventoryItems[index];
    final oldQuantity = item.quantity;
    debugPrint('Item found: ${item.itemName}, category: ${item.category}');
      
    try {
      // Determine which table to update based on category
      if (item.category.toLowerCase() == 'chemical') {
        debugPrint('Updating chemicals table');
        await SupabaseService.database
            .from(SupabaseConfig.tableChemicals)
            .update({'stock_quantity': newQuantity})
            .eq('chemical_id', int.parse(itemId));
        debugPrint('Chemicals update successful');
      } else {
        debugPrint('Updating lab_assets: itemId=$itemId, category=${item.category}, newQuantity=$newQuantity');
        await SupabaseService.database
            .from(SupabaseConfig.tableLabAssets)
            .update({
              'available_stock': newQuantity,
              'total_stock': newQuantity,
            })
            .eq('asset_id', int.parse(itemId));
        debugPrint('Lab assets update successful');
      }

      _inventoryItems[index] = item.copyWith(
        quantity: newQuantity,
        stockLevel: _calculateStockLevel(newQuantity),
        status: newQuantity == 0 ? 'Out of Stock' : 'Available',
        totalStock: newQuantity,
      );
      notifyListeners();
      debugPrint('Local state updated and listeners notified');

      // Clear cache after stock update to ensure consistency
      await _cache.remove('inventory_items');
      debugPrint('Inventory cache cleared after stock update');

      // Log audit action for manual stock adjustment
      await _auditService.logAction(
        actionType: 'UPDATE',
        entityType: category.toLowerCase() == 'chemical' ? 'chemical' : 'asset',
        entityId: itemId,
        oldValues: {'quantity': oldQuantity},
        newValues: {'quantity': newQuantity},
        description: 'Manual stock adjustment for ${item.itemName}: $oldQuantity → $newQuantity',
      );
    } catch (e) {
      debugPrint('Error updating stock: $e');
      debugPrint('Item details: itemId=$itemId, category=${item.category}');
    }
  }

  String _calculateStockLevel(num quantity) {
    if (quantity <= 3) return 'Low';
    if (quantity <= 10) return 'Medium';
    return 'High';
  }

  Future<void> addAsset({
    required String itemName,
    required String category,
    required num quantity,
    String? formula,
    String? unit,
    String? expiration,
    String? conditionNotes,
  }) async {
    try {
      String? newItemId;
      String entityType;

      if (category.toLowerCase() == 'chemical') {
        entityType = 'chemical';
        final response = await SupabaseService.database
            .from(SupabaseConfig.tableChemicals)
            .insert({
              'chemical_name': itemName,
              'stock_quantity': quantity,
              'formula': formula,
              'unit': unit,
              'expiration': expiration,
            })
            .select()
            .single();

        newItemId = response['chemical_id']?.toString();
        final newItem = InventoryItem.fromJson(response);
        _inventoryItems.add(newItem);
      } else {
        entityType = 'asset';
        final response = await SupabaseService.database
            .from(SupabaseConfig.tableLabAssets)
            .insert({
              'item_name': itemName,
              'category': category,
              'available_stock': quantity,
              'total_stock': quantity,
              'condition_notes': conditionNotes,
            })
            .select()
            .single();

        newItemId = response['asset_id']?.toString();
        final newItem = InventoryItem.fromJson(response);
        _inventoryItems.add(newItem);
      }

      // Log audit action for asset creation
      if (newItemId != null) {
        await _auditService.logAction(
          actionType: 'CREATE',
          entityType: entityType,
          entityId: newItemId,
          newValues: {
            'name': itemName,
            'category': category,
            'quantity': quantity,
          },
          description: 'Created new $entityType: $itemName',
        );
      }

      notifyListeners();

      // Clear cache after adding an asset to ensure consistency
      await _cache.remove('inventory_items');
    } catch (e) {
      debugPrint('Error adding asset: $e');
      rethrow;
    }
  }

  Future<void> editAsset({
    required String itemId,
    required String category,
    String? itemName,
    num? quantity,
    String? formula,
    String? unit,
    String? expiration,
    String? conditionNotes,
  }) async {
    try {
      final index = _inventoryItems.indexWhere((i) => i.itemId == itemId && i.category.toLowerCase() == category.toLowerCase());
      if (index == -1) {
        debugPrint('Item not found in inventory list with itemId=$itemId and category=$category');
        return;
      }

      final item = _inventoryItems[index];

      if (category.toLowerCase() == 'chemical') {
        final updateData = <String, dynamic>{};
        if (itemName != null) updateData['chemical_name'] = itemName;
        if (quantity != null) updateData['stock_quantity'] = quantity;
        if (formula != null) updateData['formula'] = formula;
        if (unit != null) updateData['unit'] = unit;
        if (expiration != null) updateData['expiration'] = expiration;

        await SupabaseService.database
            .from(SupabaseConfig.tableChemicals)
            .update(updateData)
            .eq('chemical_id', int.parse(itemId));
      } else {
        final updateData = <String, dynamic>{};
        if (itemName != null) updateData['item_name'] = itemName;
        if (quantity != null) {
          updateData['available_stock'] = quantity;
          updateData['total_stock'] = quantity;
        }
        if (conditionNotes != null) updateData['condition_notes'] = conditionNotes;

        await SupabaseService.database
            .from(SupabaseConfig.tableLabAssets)
            .update(updateData)
            .eq('asset_id', int.parse(itemId));
      }

      _inventoryItems[index] = item.copyWith(
        itemName: itemName,
        quantity: quantity ?? item.quantity,
        stockLevel: quantity != null ? _calculateStockLevel(quantity) : item.stockLevel,
        status: quantity == 0 ? 'Out of Stock' : 'Available',
        totalStock: quantity,
        formula: formula,
        unit: unit,
        expiration: expiration,
        conditionNotes: conditionNotes,
      );
      notifyListeners();

      // Clear cache after editing an asset to ensure consistency
      await _cache.remove('inventory_items');
    } catch (e) {
      debugPrint('Error editing asset: $e');
      rethrow;
    }
  }

  Future<void> deleteAsset(String itemId, String category) async {
    try {
      final index = _inventoryItems.indexWhere((i) => i.itemId == itemId && i.category.toLowerCase() == category.toLowerCase());
      if (index == -1) {
        debugPrint('Item not found in inventory list with itemId=$itemId and category=$category');
        return;
      }

      final item = _inventoryItems[index];
      final entityType = category.toLowerCase() == 'chemical' ? 'chemical' : 'asset';

      if (category.toLowerCase() == 'chemical') {
        await SupabaseService.database
            .from(SupabaseConfig.tableChemicals)
            .delete()
            .eq('chemical_id', int.parse(itemId));
      } else {
        await SupabaseService.database
            .from(SupabaseConfig.tableLabAssets)
            .delete()
            .eq('asset_id', int.parse(itemId));
      }

      // Log audit action for asset deletion
      await _auditService.logAction(
        actionType: 'DELETE',
        entityType: entityType,
        entityId: itemId,
        oldValues: {
          'name': item.itemName,
          'category': item.category,
          'quantity': item.quantity,
        },
        description: 'Deleted $entityType: ${item.itemName}',
      );

      _inventoryItems.removeAt(index);
      notifyListeners();

      // Clear cache after deleting an asset to ensure consistency
      await _cache.remove('inventory_items');
    } catch (e) {
      debugPrint('Error deleting asset: $e');
      rethrow;
    }
  }

  Color getStatusColor(String status) {
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

  Color getStatusTextColor(String status) {
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

  Color getStockLevelColor(String stockLevel) {
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

  Color getStockLevelTextColor(String stockLevel) {
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

  void refresh() {
    loadInventory();
  }
}
