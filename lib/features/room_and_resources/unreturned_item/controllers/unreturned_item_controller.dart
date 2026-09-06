import 'package:flutter/material.dart';
import '../models/unreturned_item_model.dart';
import '../../../../core/api/supabase_client.dart';
import '../../../../core/api/supabase_config.dart';
import '../../../audit/services/audit_service.dart';

class UnreturnedItemController extends ChangeNotifier {
  final AuditService _auditService = AuditService();
  List<UnreturnedItem> _unreturnedItems = [];
  String _selectedTab = 'all'; // 'all', 'students', 'professors'
  String _searchTerm = '';
  String? _selectedCategory; // null = all
  String _selectedDueDateFilter = 'all'; // 'all', 'overdue', 'today', 'this_week', 'next_week'

  List<UnreturnedItem> get unreturnedItems => _unreturnedItems;
  String get selectedTab => _selectedTab;
  String get searchTerm => _searchTerm;
  String? get selectedCategory => _selectedCategory;
  String get selectedDueDateFilter => _selectedDueDateFilter;

  List<String> get categories {
    final cats = _unreturnedItems.map((i) => i.itemType).toSet().toList();
    cats.sort();
    return cats;
  }

  List<UnreturnedItem> get filteredItems {
    return _unreturnedItems.where((item) {
      final matchesTab = switch (_selectedTab) {
        'students' => item.borrowerType.toLowerCase() == 'student',
        'professors' => item.borrowerType.toLowerCase() == 'professor',
        _ => true,
      };
      final matchesSearch = item.itemName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          item.borrowerName.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          item.itemType.toLowerCase() == _selectedCategory!.toLowerCase();

      final matchesDueDate = _matchesDueDateFilter(item);

      return matchesTab && matchesSearch && matchesCategory && matchesDueDate;
    }).toList();
  }

  bool _matchesDueDateFilter(UnreturnedItem item) {
    // Due date column doesn't exist in database, so always return true
    return true;
  }

  Map<String, List<UnreturnedItem>> get itemsByBorrower {
    final Map<String, List<UnreturnedItem>> grouped = {};
    for (final item in filteredItems) {
      final key = '${item.borrowerType}_${item.borrowerId}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }
    return grouped;
  }

  List<Map<String, dynamic>> get studentBorrowers {
    final students = <String, dynamic>{};
    for (final item in _unreturnedItems) {
      if (item.borrowerType.toLowerCase() == 'student') {
        if (!students.containsKey(item.borrowerId)) {
          students[item.borrowerId] = {
            'name': item.borrowerName,
            'id': item.borrowerId,
            'items': <UnreturnedItem>[],
          };
        }
        students[item.borrowerId]['items'].add(item);
      }
    }
    return students.values.cast<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> get professorBorrowers {
    final professors = <String, dynamic>{};
    for (final item in _unreturnedItems) {
      if (item.borrowerType.toLowerCase() == 'professor') {
        if (!professors.containsKey(item.borrowerId)) {
          professors[item.borrowerId] = {
            'name': item.borrowerName,
            'id': item.borrowerId,
            'items': <UnreturnedItem>[],
          };
        }
        professors[item.borrowerId]['items'].add(item);
      }
    }
    return professors.values.cast<Map<String, dynamic>>().toList();
  }

  Future<void> loadUnreturnedItems() async {
    try {
      // Check current user
      final currentUser = SupabaseService.auth.currentUser;
      debugPrint('Current user ID: ${currentUser?.id}');
      debugPrint('Current user email: ${currentUser?.email}');

      // Fetch current user's role
      if (currentUser != null) {
        final currentUserInfo = await SupabaseService.database
            .from(SupabaseConfig.tableUserInfo)
            .select('*')
            .eq('id', currentUser.id)
            .maybeSingle();
        debugPrint('Current user info: $currentUserInfo');
        debugPrint('Current user role: ${currentUserInfo?['role']}');
      }

      // First, try to fetch ALL reservation_items without filters
      final simpleResponse = await SupabaseService.database
          .from(SupabaseConfig.tableReservationItems)
          .select('*');
      debugPrint('Simple query (all reservation_items): ${simpleResponse.length} rows');

      // Now try the full query with filters
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableReservationItems)
          .select('''
            detail_id,
            reservation_id,
            asset_id,
            quantity_borrowed,
            quantity_returned,
            is_returned,
            reservations!inner(
              reservation_id,
              reservation_date,
              user_id,
              status
            ),
            lab_assets!left(
              asset_id,
              item_name,
              category
            )
          ''')
          .inFilter('reservations.status', ['Unreturned', 'Partially Returned'])
          .eq('is_returned', false)
          .order('reservation_date', referencedTable: 'reservations');

      final List<UnreturnedItem> items = [];
      debugPrint('Total reservation_items fetched: ${response.length}');

      // Collect all unique user IDs first
      final Set<String> userIds = {};
      for (final item in response) {
        final reservation = item['reservations'] as Map<String, dynamic>?;
        final userId = reservation?['user_id'] as String?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      // Fetch all user info in a single batch query
      final Map<String, Map<String, dynamic>> userInfoMap = {};
      if (userIds.isNotEmpty) {
        final usersResponse = await SupabaseService.database
            .from(SupabaseConfig.tableUserInfo)
            .select('id, first_name, last_name, role')
            .inFilter('id', userIds.toList());
        
        for (var user in usersResponse) {
          userInfoMap[user['id'] as String] = user;
        }
        debugPrint('Fetched ${userInfoMap.length} user info records');
      }

      // Now process items with the user info map
      for (final item in response) {
        final reservation = item['reservations'] as Map<String, dynamic>?;
        final labAsset = item['lab_assets'] as Map<String, dynamic>?;

        // Don't skip if reservation is null - use default values
        final userId = reservation?['user_id'] as String?;
        String borrowerName = 'Unknown Borrower';
        String borrowerType = 'Unknown';
        String borrowerId = 'Unknown';

        // Try to get user info from the map
        if (userId != null && userInfoMap.containsKey(userId)) {
          final userInfo = userInfoMap[userId]!;
          borrowerName = '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}'.trim();
          borrowerType = userInfo['role'] ?? 'Unknown';
          borrowerId = userInfo['id']?.toString() ?? 'Unknown';
          
          if (borrowerName.isEmpty) {
            borrowerName = 'Unknown Borrower';
          }
        } else {
          debugPrint('User info not found for userId: $userId');
        }

        final borrowedQuantity = item['quantity_borrowed'] as int? ?? 0;
        final returnedQuantity = item['quantity_returned'] as int? ?? 0;
        final isReturned = item['is_returned'] as bool? ?? false;
        final unreturnedQuantity = borrowedQuantity - returnedQuantity;

        debugPrint('Item ${item['detail_id']}: borrowed=$borrowedQuantity, returned=$returnedQuantity, isReturned=$isReturned, unreturned=$unreturnedQuantity');

        if (!isReturned && unreturnedQuantity > 0) {
          items.add(UnreturnedItem(
            detailId: item['detail_id']?.toString() ?? '',
            reservationId: item['reservation_id']?.toString() ?? '',
            itemId: item['asset_id']?.toString() ?? '',
            itemName: labAsset?['item_name'] ?? 'Unknown Item',
            itemType: labAsset?['category'] ?? 'Unknown Category',
            borrowerName: borrowerName,
            borrowerType: borrowerType,
            borrowerId: borrowerId,
            borrowedQuantity: borrowedQuantity,
            returnedQuantity: returnedQuantity,
            unreturnedQuantity: unreturnedQuantity,
            reservationDate: reservation?['reservation_date'] ?? 'Unknown Date',
            dueDate: null, // due_date column doesn't exist in reservations table
          ));
        }
      }

      debugPrint('Final unreturned items count: ${items.length}');

      _unreturnedItems = items;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unreturned items: $e');
      _unreturnedItems = _getMockUnreturnedItems();
      notifyListeners();
    }
  }

  List<UnreturnedItem> _getMockUnreturnedItems() {
    return [
      UnreturnedItem(
        detailId: '1',
        reservationId: '101',
        itemId: '1',
        itemName: 'Microscope',
        itemType: 'Equipment',
        borrowerName: 'John Doe',
        borrowerType: 'Student',
        borrowerId: 'STU001',
        borrowedQuantity: 2,
        returnedQuantity: 1,
        unreturnedQuantity: 1,
        reservationDate: '2026-06-20',
        dueDate: '2026-06-25',
      ),
      UnreturnedItem(
        detailId: '2',
        reservationId: '101',
        itemId: '2',
        itemName: 'Beaker 500ml',
        itemType: 'Glassware',
        borrowerName: 'John Doe',
        borrowerType: 'Student',
        borrowerId: 'STU001',
        borrowedQuantity: 5,
        returnedQuantity: 3,
        unreturnedQuantity: 2,
        reservationDate: '2026-06-20',
        dueDate: '2026-06-25',
      ),
      UnreturnedItem(
        detailId: '3',
        reservationId: '102',
        itemId: '3',
        itemName: 'Sulfuric Acid',
        itemType: 'Chemical',
        borrowerName: 'Dr. Smith',
        borrowerType: 'Professor',
        borrowerId: 'PROF001',
        borrowedQuantity: 3,
        returnedQuantity: 2,
        unreturnedQuantity: 1,
        reservationDate: '2026-06-18',
        dueDate: '2026-06-23',
      ),
      UnreturnedItem(
        detailId: '4',
        reservationId: '103',
        itemId: '4',
        itemName: 'Test Tube Rack',
        itemType: 'Glassware',
        borrowerName: 'Jane Smith',
        borrowerType: 'Student',
        borrowerId: 'STU002',
        borrowedQuantity: 1,
        returnedQuantity: 0,
        unreturnedQuantity: 1,
        reservationDate: '2026-06-22',
        dueDate: '2026-06-27',
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

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedDueDateFilter(String filter) {
    _selectedDueDateFilter = filter;
    notifyListeners();
  }

  Future<void> returnItem(String detailId, String borrowerId) async {
    try {
      final index = _unreturnedItems.indexWhere(
        (i) => i.detailId == detailId && i.borrowerId == borrowerId,
      );
      
      if (index != -1) {
        final item = _unreturnedItems[index];
        if (item.unreturnedQuantity > 0) {
          final newReturnedQuantity = item.borrowedQuantity;
          
          // Get current asset stock
          final assetResponse = await SupabaseService.database
              .from(SupabaseConfig.tableLabAssets)
              .select('available_stock, total_stock')
              .eq('asset_id', int.parse(item.itemId))
              .single();
          
          final previousStock = assetResponse['available_stock'] as int? ?? 0;
          final totalStock = assetResponse['total_stock'] as int? ?? 0;
          final newStock = previousStock + item.unreturnedQuantity;
          
          // Ensure new stock doesn't exceed total stock
          final finalStock = newStock > totalStock ? totalStock : newStock;
          
          // Update reservation item
          await SupabaseService.database
              .from(SupabaseConfig.tableReservationItems)
              .update({
                'quantity_returned': newReturnedQuantity,
                'is_returned': true,
              })
              .eq('detail_id', int.parse(detailId));
          
          // Update lab asset stock
          await SupabaseService.database
              .from(SupabaseConfig.tableLabAssets)
              .update({'available_stock': finalStock})
              .eq('asset_id', int.parse(item.itemId));
          
          // Log to stock history
          await SupabaseService.database
              .from(SupabaseConfig.tableStockHistory)
              .insert({
                'item_type': 'asset',
                'item_id': int.parse(item.itemId),
                'previous_quantity': previousStock,
                'new_quantity': finalStock,
                'change_reason': 'Item returned: ${item.itemName} (Reservation ID: ${item.reservationId})',
                'changed_by': SupabaseService.auth.currentUser?.id,
              });

          // Try to get accurate borrower info for audit log
          String auditBorrowerName = item.borrowerName;
          if (auditBorrowerName == 'Unknown Borrower' || auditBorrowerName.isEmpty) {
            try {
              // First try to get user info from user_info table
              final userInfo = await SupabaseService.database
                  .from(SupabaseConfig.tableUserInfo)
                  .select('first_name, last_name')
                  .eq('id', borrowerId)
                  .maybeSingle();
              
              if (userInfo != null) {
                final firstName = userInfo['first_name'] as String? ?? '';
                final lastName = userInfo['last_name'] as String? ?? '';
                auditBorrowerName = '$firstName $lastName'.trim();
                if (auditBorrowerName.isEmpty) {
                  auditBorrowerName = borrowerId; // Fallback to ID if name is empty
                }
              } else {
                // If user not found in user_info, try to get from reservation
                final reservation = await SupabaseService.database
                    .from(SupabaseConfig.tableReservations)
                    .select('professor')
                    .eq('reservation_id', int.parse(item.reservationId))
                    .maybeSingle();
                
                if (reservation != null && reservation['professor'] != null) {
                  auditBorrowerName = reservation['professor'].toString();
                } else {
                  auditBorrowerName = borrowerId; // Final fallback to ID
                }
              }
            } catch (e) {
              debugPrint('Error fetching user info for audit log: $e');
              auditBorrowerName = borrowerId; // Fallback to ID on error
            }
          }

          // Log audit action for item return
          await _auditService.logAction(
            actionType: 'RETURN',
            entityType: 'reservation_item',
            entityId: detailId,
            oldValues: {
              'quantity_returned': item.returnedQuantity,
              'is_returned': false,
            },
            newValues: {
              'quantity_returned': newReturnedQuantity,
              'is_returned': true,
            },
            description: 'Marked item as returned: ${item.itemName} (Borrower: $auditBorrowerName, Qty: ${item.unreturnedQuantity})',
          );

          _unreturnedItems[index] = item.copyWith(
            returnedQuantity: newReturnedQuantity,
            unreturnedQuantity: 0,
          );
          notifyListeners();

          // Remove item from list if fully returned
          if (newReturnedQuantity >= item.borrowedQuantity) {
            _unreturnedItems.removeAt(index);
          }
          notifyListeners();

          // Check if all items in the reservation are returned and update status
          await _checkAndUpdateReservationStatus(item.reservationId);
        }
      }
    } catch (e) {
      debugPrint('Error returning item: $e');
    }
  }

  Future<void> _checkAndUpdateReservationStatus(String reservationId) async {
    try {
      // Fetch all items for this reservation
      final reservationItems = await SupabaseService.database
          .from(SupabaseConfig.tableReservationItems)
          .select('*')
          .eq('reservation_id', int.parse(reservationId));

      // Check if all items are returned
      final allReturned = reservationItems.every((item) {
        final borrowed = item['quantity_borrowed'] as int? ?? 0;
        final returned = item['quantity_returned'] as int? ?? 0;
        final isReturned = item['is_returned'] as bool? ?? false;
        return isReturned && returned >= borrowed;
      });

      if (allReturned && reservationItems.isNotEmpty) {
        // Update reservation status to Completed
        await SupabaseService.database
            .from(SupabaseConfig.tableReservations)
            .update({'status': 'Completed'})
            .eq('reservation_id', int.parse(reservationId));
        debugPrint('Reservation $reservationId status updated to Completed');
      }
    } catch (e) {
      debugPrint('Error checking and updating reservation status: $e');
    }
  }

  Future<void> returnPartialItem(String detailId, String borrowerId, int quantity) async {
    try {
      final index = _unreturnedItems.indexWhere(
        (i) => i.detailId == detailId && i.borrowerId == borrowerId,
      );
      if (index != -1) {
        final item = _unreturnedItems[index];
        if (quantity <= item.unreturnedQuantity) {
          // Get current asset stock
          final assetResponse = await SupabaseService.database
              .from(SupabaseConfig.tableLabAssets)
              .select('available_stock, total_stock')
              .eq('asset_id', int.parse(item.itemId))
              .single();
          
          final previousStock = assetResponse['available_stock'] as int? ?? 0;
          final totalStock = assetResponse['total_stock'] as int? ?? 0;
          final newStock = previousStock + quantity;
          
          // Ensure new stock doesn't exceed total stock
          final finalStock = newStock > totalStock ? totalStock : newStock;
          
          await SupabaseService.database
              .from(SupabaseConfig.tableReservationItems)
              .update({
                'quantity_returned': item.returnedQuantity + quantity,
                'is_returned': (item.returnedQuantity + quantity) >= item.borrowedQuantity,
              })
              .eq('detail_id', int.parse(detailId));
          
          // Update lab asset stock
          await SupabaseService.database
              .from(SupabaseConfig.tableLabAssets)
              .update({'available_stock': finalStock})
              .eq('asset_id', int.parse(item.itemId));
          
          // Log to stock history
          await SupabaseService.database
              .from(SupabaseConfig.tableStockHistory)
              .insert({
                'item_type': 'asset',
                'item_id': int.parse(item.itemId),
                'previous_quantity': previousStock,
                'new_quantity': finalStock,
                'change_reason': 'Partial return: $quantity ${item.itemName} (Reservation ID: ${item.reservationId})',
                'changed_by': SupabaseService.auth.currentUser?.id,
              });

          // Try to get accurate borrower info for audit log
          String auditBorrowerName = item.borrowerName;
          if (auditBorrowerName == 'Unknown Borrower' || auditBorrowerName.isEmpty) {
            try {
              // First try to get user info from user_info table
              final userInfo = await SupabaseService.database
                  .from(SupabaseConfig.tableUserInfo)
                  .select('first_name, last_name')
                  .eq('id', borrowerId)
                  .maybeSingle();
              
              if (userInfo != null) {
                final firstName = userInfo['first_name'] as String? ?? '';
                final lastName = userInfo['last_name'] as String? ?? '';
                auditBorrowerName = '$firstName $lastName'.trim();
                if (auditBorrowerName.isEmpty) {
                  auditBorrowerName = borrowerId; // Fallback to ID if name is empty
                }
              } else {
                // If user not found in user_info, try to get from reservation
                final reservation = await SupabaseService.database
                    .from(SupabaseConfig.tableReservations)
                    .select('professor')
                    .eq('reservation_id', int.parse(item.reservationId))
                    .maybeSingle();
                
                if (reservation != null && reservation['professor'] != null) {
                  auditBorrowerName = reservation['professor'].toString();
                } else {
                  auditBorrowerName = borrowerId; // Final fallback to ID
                }
              }
            } catch (e) {
              debugPrint('Error fetching user info for audit log: $e');
              auditBorrowerName = borrowerId; // Fallback to ID on error
            }
          }

          // Log audit action for partial item return
          await _auditService.logAction(
            actionType: 'PARTIAL_RETURN',
            entityType: 'reservation_item',
            entityId: detailId,
            oldValues: {
              'quantity_returned': item.returnedQuantity,
            },
            newValues: {
              'quantity_returned': item.returnedQuantity + quantity,
            },
            description: 'Partial return of item: ${item.itemName} (Borrower: $auditBorrowerName, Qty: $quantity)',
          );

          _unreturnedItems[index] = item.copyWith(
            returnedQuantity: item.returnedQuantity + quantity,
            unreturnedQuantity: item.unreturnedQuantity - quantity,
          );
          notifyListeners();

          // Remove item from list if fully returned
          if (item.returnedQuantity + quantity >= item.borrowedQuantity) {
            _unreturnedItems.removeAt(index);
          }
          notifyListeners();

          // Check if all items in the reservation are returned and update status
          await _checkAndUpdateReservationStatus(item.reservationId);
        }
      }
    } catch (e) {
      debugPrint('Error returning partial item: $e');
    }
  }

  bool get hasUnreturnedItems => _unreturnedItems.isNotEmpty;
  bool get hasStudentUnreturnedItems => studentBorrowers.isNotEmpty;
  bool get hasProfessorUnreturnedItems => professorBorrowers.isNotEmpty;

  void refresh() {
    loadUnreturnedItems();
  }
}
