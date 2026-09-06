import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/service/cache_service.dart';
import '../models/reservations_history_model.dart';

class ReservationsHistoryService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cache = CacheService();

  /// Fetch reservations with pagination
  Future<List<ReservationHistory>> fetchReservations({int page = 1, int limit = 20}) async {
    final start = (page - 1) * limit;
    final end = start + limit - 1;

    try {
      // Fetch paginated reservations with user info and room info
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
            updated_at,
            rooms (
              room_id,
              room_name
            )
          ''')
          .inFilter('status', ['Completed', 'Declined', 'Cancelled', 'Unreturned'])
          .order('created_at', ascending: false)
          .range(start, end);

      // Fetch user info for all users in reservations
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

      // Fetch all reservation items with asset info
      final itemsResponse = await _client
          .from('reservation_items')
          .select('''
            detail_id,
            reservation_id,
            asset_id,
            quantity_borrowed,
            quantity_returned,
            is_returned,
            lab_assets (
              asset_id,
              item_name,
              category,
              total_stock,
              available_stock
            )
          ''');

      // Group items by reservation_id
      final Map<int, List<ReservedItem>> itemsMap = {};
      for (var item in itemsResponse) {
        final reservationId = item['reservation_id'] as int;
        final asset = item['lab_assets'];
        if (asset != null) {
          final reservedItem = ReservedItem(
            itemId: asset['asset_id'].toString(),
            itemName: asset['item_name'] ?? '',
            quantity: item['quantity_borrowed'] ?? 0,
            returnedQuantity: item['quantity_returned'] ?? 0,
            status: item['is_returned'] == true ? 'Returned' : 'Pending',
          );
          itemsMap.putIfAbsent(reservationId, () => []).add(reservedItem);
        }
      }

      // Map reservations to ReservationHistory model
      List<ReservationHistory> reservations = [];
      for (var reservation in reservationsResponse) {
        final reservationId = reservation['reservation_id'] as int;

        // Determine reservation type based on whether it has items
        final hasItems = itemsMap.containsKey(reservationId) && itemsMap[reservationId]!.isNotEmpty;
        final reservationType = hasItems ? 'Equipment' : 'Room';

        // Determine room/item name
        String roomItemReserved = '';
        if (hasItems) {
          // If has items, show the first item name or count
          final items = itemsMap[reservationId];
          if (items != null && items.length == 1) {
            roomItemReserved = items[0].itemName;
          } else {
            roomItemReserved = '${items?.length ?? 0} items';
          }
        } else {
          // Use room name from rooms relation
          final room = reservation['rooms'];
          roomItemReserved = room != null ? (room['room_name'] ?? 'Unknown Room') : 'Room ID: ${reservation['room_id'] ?? 'Unknown'}';
        }

        // Format time schedule
        final startTime = reservation['start_time'];
        final endTime = reservation['end_time'];
        final timeSchedule = _formatTimeSchedule(startTime, endTime);

        // Format user name
        String userName = 'Unknown User';
        String role = 'Student';
        final userId = reservation['user_id'] as String?;
        if (userId != null && userInfoMap.containsKey(userId)) {
          final userInfo = userInfoMap[userId]!;
          final firstName = userInfo['first_name'] ?? '';
          final lastName = userInfo['last_name'] ?? '';
          userName = firstName.isNotEmpty || lastName.isNotEmpty
              ? '$firstName $lastName'.trim()
              : userInfo['username'] ?? 'Unknown User';
          role = userInfo['role'] ?? 'Student';
        }

        // Format dates
        final reservationDate = reservation['reservation_date'];
        final createdAt = reservation['created_at'];

        reservations.add(ReservationHistory(
          reservationId: reservationId.toString(),
          userName: userName,
          role: role,
          reservationType: reservationType,
          roomItemReserved: roomItemReserved,
          reservationDate: _formatDate(reservationDate),
          timeSchedule: timeSchedule,
          status: reservation['status'] ?? 'Pending',
          dateCreated: _formatDateTime(createdAt),
          items: itemsMap[reservationId],
        ));
      }

      return reservations;
    } catch (e) {
      throw Exception('Failed to fetch reservations: $e');
    }
  }

  /// Fetch every reservation history record for report generation.
  Future<List<ReservationHistory>> fetchAllReservations() async {
    const pageSize = 500;
    final total = await countReservations();
    final reservations = <ReservationHistory>[];

    for (var page = 1; reservations.length < total; page++) {
      final batch = await fetchReservations(page: page, limit: pageSize);
      if (batch.isEmpty) break;
      reservations.addAll(batch);
      if (batch.length < pageSize) break;
    }
    return reservations;
  }

  /// Count total history reservations (for pagination)
  Future<int> countReservations() async {
    try {
      final response = await _client
          .from('reservations')
          .select('reservation_id')
          .inFilter('status', ['Completed', 'Declined', 'Cancelled', 'Unreturned'])
          .count();
      return response.count;
    } catch (e) {
      print('Error counting reservations: $e');
      return 0;
    }
  }

  /// Fetch a single reservation by ID with full details
  Future<ReservationHistory?> fetchReservationById(int reservationId) async {
    try {
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
            updated_at,
            user_info (
              id,
              username,
              email,
              first_name,
              last_name,
              role
            ),
            rooms (
              room_id,
              room_name,
              capacity,
              status
            )
          ''')
          .eq('reservation_id', reservationId)
          .single();

      // Fetch items for this reservation
      final itemsResponse = await _client
          .from('reservation_items')
          .select('''
            detail_id,
            reservation_id,
            asset_id,
            quantity_borrowed,
            quantity_returned,
            is_returned,
            lab_assets (
              asset_id,
              item_name,
              category,
              total_stock,
              available_stock
            )
          ''')
          .eq('reservation_id', reservationId);

      // Map items
      List<ReservedItem> items = [];
      for (var item in itemsResponse) {
        final asset = item['lab_assets'];
        if (asset != null) {
          items.add(ReservedItem(
            itemId: asset['asset_id'].toString(),
            itemName: asset['item_name'] ?? '',
            quantity: item['quantity_borrowed'] ?? 0,
            returnedQuantity: item['quantity_returned'] ?? 0,
            status: item['is_returned'] == true ? 'Returned' : 'Pending',
          ));
        }
      }

      final userInfo = reservationsResponse['user_info'];
      final room = reservationsResponse['rooms'];

      // Determine reservation type
      final reservationType = items.isNotEmpty ? 'Equipment' : 'Room';

      // Determine room/item name
      String roomItemReserved = '';
      if (items.isNotEmpty) {
        if (items.length == 1) {
          roomItemReserved = items[0].itemName;
        } else {
          roomItemReserved = '${items.length} items';
        }
      } else if (room != null) {
        roomItemReserved = room['room_name'] ?? '';
      }

      // Format time schedule
      final startTime = reservationsResponse['start_time'];
      final endTime = reservationsResponse['end_time'];
      final timeSchedule = _formatTimeSchedule(startTime, endTime);

      // Format user name
      String userName = 'Unknown User';
      String role = 'Student';
      if (userInfo != null) {
        final firstName = userInfo['first_name'] ?? '';
        final lastName = userInfo['last_name'] ?? '';
        userName = firstName.isNotEmpty || lastName.isNotEmpty
            ? '$firstName $lastName'.trim()
            : userInfo['username'] ?? 'Unknown User';
        role = userInfo['role'] ?? 'Student';
      }

      // Format dates
      final reservationDate = reservationsResponse['reservation_date'];
      final createdAt = reservationsResponse['created_at'];

      return ReservationHistory(
        reservationId: reservationsResponse['reservation_id'].toString(),
        userName: userName,
        role: role,
        reservationType: reservationType,
        roomItemReserved: roomItemReserved,
        reservationDate: _formatDate(reservationDate),
        timeSchedule: timeSchedule,
        status: reservationsResponse['status'] ?? 'Pending',
        dateCreated: _formatDateTime(createdAt),
        items: items.isNotEmpty ? items : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch reservation: $e');
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

  String _formatDateTime(dynamic date) {
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

  /// Clear reservations history cache
  Future<void> clearCache() async {
    await _cache.remove('reservations_history');
  }
}
