import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/service/cache_service.dart';
import '../models/ongoing_reservation_model.dart';

class OngoingReservationService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cache = CacheService();

  /// Fetch ongoing reservations with pagination
  Future<List<OngoingReservation>> fetchOngoingReservations({int page = 1, int limit = 20}) async {
    try {
      final start = (page - 1) * limit;
      final end = start + limit - 1;

      // Fetch paginated reservations with status 'Ongoing'
      // Also catch student reservations where professor_approval = Approved
      // but the status hasn't been synced to 'Ongoing' yet.
      final reservationsResponse = await _client
          .from('reservations')
          .select('''
            reservation_id,
            user_id,
            room_id,
            reservation_date,
            start_time,
            end_time,
            year_section,
            course,
            professor,
            professor_approval,
            admin_approval,
            status,
            additional_note,
            created_at,
            updated_at
          ''')
          .eq('status', 'Ongoing')
          .order('created_at', ascending: false)
          .range(start, end);

      print('Fetched ${reservationsResponse.length} ongoing reservations from database');

      // Fetch reservation items with asset info
      final reservationIds = reservationsResponse
          .map((r) => r['reservation_id'] as int)
          .toSet()
          .toList();
      
      final Map<int, List<Map<String, dynamic>>> itemsMap = {};
      if (reservationIds.isNotEmpty) {
        final itemsResponse = await _client
            .from('reservation_items')
            .select('''
              detail_id,
              reservation_id,
              asset_id,
              quantity_borrowed,
              quantity_returned,
              lab_assets (
                asset_id,
                item_name,
                category
              )
            ''')
            .inFilter('reservation_id', reservationIds);

        for (var item in itemsResponse) {
          final reservationId = item['reservation_id'] as int;
          itemsMap.putIfAbsent(reservationId, () => []).add(item);
        }
      }

      // Fetch chemical usage for all reservations
      final Map<int, List<Map<String, dynamic>>> chemicalsMap = {};
      if (reservationIds.isNotEmpty) {
        final chemicalsResponse = await _client
            .from('chemical_usage')
            .select('''
              usage_id,
              reservation_id,
              chemical_id,
              quantity_used,
              unit,
              chemicals (
                chemical_id,
                chemical_name
              )
            ''')
            .inFilter('reservation_id', reservationIds);

        for (var chem in chemicalsResponse) {
          final reservationId = chem['reservation_id'] as int;
          chemicalsMap.putIfAbsent(reservationId, () => []).add(chem);
        }
      }

      // Fetch user info for all users
      final userIds = reservationsResponse.map((r) => r['user_id'] as String).toSet().toList();
      final Map<String, Map<String, dynamic>> userInfoMap = {};
      if (userIds.isNotEmpty) {
        final usersResponse = await _client
            .from('user_info')
            .select('id, username, email, first_name, last_name, role')
            .inFilter('id', userIds);
        for (var user in usersResponse) {
          userInfoMap[user['id'] as String] = user;
        }
      }

      // Map reservations to OngoingReservation model
      List<OngoingReservation> reservations = [];
      for (var reservation in reservationsResponse) {
        final reservationId = reservation['reservation_id'] as int;
        final userId = reservation['user_id'] as String?;
        final userInfo = userId != null ? userInfoMap[userId] : null;

        // Determine user type and name
        String userType = 'Student';
        String name = '';
        String programYear = '';
        
        if (userInfo != null) {
          final role = userInfo['role']?.toString().toLowerCase() ?? '';
          userType = role == 'professor' ? 'Professor' : 'Student';
          
          final firstName = userInfo['first_name'] ?? '';
          final lastName = userInfo['last_name'] ?? '';
          name = firstName.isNotEmpty || lastName.isNotEmpty
              ? '$firstName $lastName'.trim()
              : userInfo['username'] ?? 'Unknown';
          
          if (userType == 'Student') {
            programYear = reservation['year_section']?.toString() ?? '';
          }
        }

        // Format professor name
        final professorName = reservation['professor']?.toString() ?? '';

        // Format date
        final reservationDate = reservation['reservation_date'];
        final formattedDate = _formatDate(reservationDate);

        // Format time
        final startTime = reservation['start_time'];
        final endTime = reservation['end_time'];
        final formattedTime = _formatTimeSchedule(startTime, endTime);

        // Format items from reservation_items and chemical_usage
        List<ReservedItem> items = [];
        if (itemsMap.containsKey(reservationId) && itemsMap[reservationId]!.isNotEmpty) {
          final itemsData = itemsMap[reservationId]!;
          items.addAll(itemsData.map((item) {
            final asset = item['lab_assets'];
            final itemName = asset != null ? (asset['item_name'] ?? '') : '';
            final quantity = item['quantity_borrowed'] ?? 0;
            final returnedQuantity = item['quantity_returned'] ?? 0;

            // Determine item status
            String itemStatus = 'Pending';
            if (returnedQuantity >= quantity) {
              itemStatus = 'Returned';
            } else if (returnedQuantity > 0) {
              itemStatus = 'Partial';
            }

            return ReservedItem(
              itemId: item['detail_id'].toString(),
              assetId: item['asset_id'].toString(),
              itemName: itemName,
              quantity: quantity,
              returnedQuantity: returnedQuantity,
              status: itemStatus,
            );
          }));
        }

        // Add chemical items
        if (chemicalsMap.containsKey(reservationId) && chemicalsMap[reservationId]!.isNotEmpty) {
          final chemItems = chemicalsMap[reservationId]!;
          for (var chem in chemItems) {
            final chemicalData = chem['chemicals'];
            final chemName = chemicalData != null ? (chemicalData['chemical_name'] ?? '') : '';
            final quantityUsed = (chem['quantity_used'] ?? 0).toInt();
            final unit = chem['unit'] ?? '';

            items.add(ReservedItem(
              itemId: chem['usage_id'].toString(),
              assetId: '',
              itemName: '$chemName ($unit)',
              quantity: quantityUsed,
              returnedQuantity: 0,
              status: 'Used',
            ));
          }
        }

        // Format last updated
        final updatedAt = reservation['updated_at'];
        final formattedLastUpdated = _formatDate(updatedAt);

        reservations.add(OngoingReservation(
          reservationId: reservationId.toString(),
          name: name,
          userType: userType,
          programYear: programYear,
          professor: userType == 'Student' ? professorName : null,
          date: formattedDate,
          time: formattedTime,
          status: 'Ongoing',
          items: items,
          lastUpdated: formattedLastUpdated,
        ));
      }

      print('Mapped ${reservations.length} ongoing reservations');
      return reservations;
    } catch (e) {
      print('Error fetching ongoing reservations: $e');
      throw Exception('Failed to fetch ongoing reservations: $e');
    }
  }

  /// Update item return status
  Future<void> updateItemReturn(int detailId, int returnedQuantity) async {
    try {
      await _client
          .from('reservation_items')
          .update({'quantity_returned': returnedQuantity})
          .eq('detail_id', detailId);

      // Clear dashboard cache since this affects stats
      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_borrowed_items');
      await _cache.remove('dashboard_recent_activities');
    } catch (e) {
      throw Exception('Failed to update item return: $e');
    }
  }

  /// Count total ongoing reservations (for pagination)
  Future<int> countOngoingReservations() async {
    try {
      final response = await _client
          .from('reservations')
          .select('reservation_id')
          .eq('status', 'Ongoing')
          .count();
      return response.count;
    } catch (e) {
      print('Error counting ongoing reservations: $e');
      return 0;
    }
  }

  /// Complete reservation
  Future<void> completeReservation(int reservationId) async {
    try {
      await _client
          .from('reservations')
          .update({'status': 'Completed'})
          .eq('reservation_id', reservationId);

      // Clear dashboard and reservations history cache
      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_reservation_trends');
      await _cache.remove('dashboard_recent_activities');
      await _cache.remove('reservations_history');
    } catch (e) {
      throw Exception('Failed to complete reservation: $e');
    }
  }

  /// Return item - marks item as fully returned and updates stock
  Future<void> returnItem(int detailId, int assetId, int borrowedQuantity, int unreturnedQuantity, String reservationId) async {
    try {
      // Get current asset stock
      final assetResponse = await _client
          .from('lab_assets')
          .select('available_stock, total_stock')
          .eq('asset_id', assetId)
          .single();
      
      final previousStock = assetResponse['available_stock'] as int? ?? 0;
      final totalStock = assetResponse['total_stock'] as int? ?? 0;
      final newStock = previousStock + unreturnedQuantity;
      
      // Ensure new stock doesn't exceed total stock
      final finalStock = newStock > totalStock ? totalStock : newStock;
      
      // Update reservation item
      await _client
          .from('reservation_items')
          .update({
            'quantity_returned': borrowedQuantity,
            'is_returned': true,
          })
          .eq('detail_id', detailId);
      
      // Update lab asset stock
      await _client
          .from('lab_assets')
          .update({'available_stock': finalStock})
          .eq('asset_id', assetId);
      
      // Log to stock history
      await _client
          .from('stock_history')
          .insert({
            'item_type': 'asset',
            'item_id': assetId,
            'previous_quantity': previousStock,
            'new_quantity': finalStock,
            'change_reason': 'Item returned early (Reservation ID: $reservationId)',
            'changed_by': _client.auth.currentUser?.id,
          });

      // Clear dashboard cache
      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_borrowed_items');
      await _cache.remove('dashboard_recent_activities');
    } catch (e) {
      throw Exception('Failed to return item: $e');
    }
  }

  /// Return partial item - updates stock and returned quantity
  Future<void> returnPartialItem(int detailId, int assetId, int currentReturnedQuantity, int returnQuantity, String reservationId) async {
    try {
      // Get current asset stock
      final assetResponse = await _client
          .from('lab_assets')
          .select('available_stock, total_stock')
          .eq('asset_id', assetId)
          .single();
      
      final previousStock = assetResponse['available_stock'] as int? ?? 0;
      final totalStock = assetResponse['total_stock'] as int? ?? 0;
      final newStock = previousStock + returnQuantity;
      
      // Ensure new stock doesn't exceed total stock
      final finalStock = newStock > totalStock ? totalStock : newStock;
      
      await _client
          .from('reservation_items')
          .update({
            'quantity_returned': currentReturnedQuantity + returnQuantity,
            'is_returned': false,
          })
          .eq('detail_id', detailId);
      
      // Update lab asset stock
      await _client
          .from('lab_assets')
          .update({'available_stock': finalStock})
          .eq('asset_id', assetId);
      
      // Log to stock history
      await _client
          .from('stock_history')
          .insert({
            'item_type': 'asset',
            'item_id': assetId,
            'previous_quantity': previousStock,
            'new_quantity': finalStock,
            'change_reason': 'Partial return: $returnQuantity items (Reservation ID: $reservationId)',
            'changed_by': _client.auth.currentUser?.id,
          });

      // Clear dashboard cache
      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_borrowed_items');
      await _cache.remove('dashboard_recent_activities');
    } catch (e) {
      throw Exception('Failed to return partial item: $e');
    }
  }

  /// Check if all items in reservation are returned and update status
  Future<void> checkAndUpdateReservationStatus(int reservationId) async {
    try {
      // Fetch all items for this reservation
      final reservationItems = await _client
          .from('reservation_items')
          .select('*')
          .eq('reservation_id', reservationId);

      // Check if all items are returned
      final allReturned = reservationItems.every((item) {
        final borrowed = item['quantity_borrowed'] as int? ?? 0;
        final returned = item['quantity_returned'] as int? ?? 0;
        final isReturned = item['is_returned'] as bool? ?? false;
        return isReturned && returned >= borrowed;
      });

      if (allReturned && reservationItems.isNotEmpty) {
        // Update reservation status to Completed
        await _client
            .from('reservations')
            .update({'status': 'Completed'})
            .eq('reservation_id', reservationId);
        
        // Clear dashboard cache
        await _cache.remove('dashboard_stats');
        await _cache.remove('dashboard_reservation_trends');
        await _cache.remove('dashboard_recent_activities');
        await _cache.remove('reservations_history');
      }
    } catch (e) {
      throw Exception('Failed to check and update reservation status: $e');
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is String) {
      try {
        final dateTime = DateTime.parse(date);
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  String _formatTimeSchedule(dynamic startTime, dynamic endTime) {
    String formatTime(dynamic time) {
      if (time == null) return '';
      if (time is String) {
        try {
          final parts = time.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = parts[1];
            final period = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            return '$displayHour:$minute $period';
          }
        } catch (e) {
          return time;
        }
      }
      return time.toString();
    }

    final start = formatTime(startTime);
    final end = formatTime(endTime);
    return '$start - $end';
  }
}
