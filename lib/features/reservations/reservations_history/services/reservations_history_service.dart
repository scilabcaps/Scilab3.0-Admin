import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/service/cache_service.dart';
import '../models/reservations_history_model.dart';

class ReservationsHistoryService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cache = CacheService();

  /// Fetch all reservations with user, room, and items information
  Future<List<ReservationHistory>> fetchReservations() async {
    final cacheKey = 'reservations_history';
    
    // Try to get from cache first
    final cachedReservations = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedReservations != null) {
      return cachedReservations.map((data) => ReservationHistory(
        reservationId: data['reservationId'] as String,
        userName: data['userName'] as String,
        role: data['role'] as String,
        reservationType: data['reservationType'] as String,
        roomItemReserved: data['roomItemReserved'] as String,
        reservationDate: data['reservationDate'] as String,
        timeSchedule: data['timeSchedule'] as String,
        status: data['status'] as String,
        dateCreated: data['dateCreated'] as String,
        items: data['items'] != null 
            ? (data['items'] as List).map((item) => ReservedItem(
              itemId: item['itemId'] as String,
              itemName: item['itemName'] as String,
              quantity: item['quantity'] as int,
              returnedQuantity: item['returnedQuantity'] as int,
              status: item['status'] as String,
            )).toList()
            : null,
      )).toList();
    }

    try {
      // Fetch reservations with user info and room info
      final reservationsResponse = await _client
          .from('reservations')
          .select('''
            reservation_id,
            user_id,
            room_id,
            reservation_date,
            start_time,
            end_time,
            year,
            section,
            professor,
            professor_approval,
            admin_approval,
            status,
            additional_note,
            created_at,
            updated_at
          ''')
          .eq('status', 'Completed')
          .order('created_at', ascending: false);

      // Fetch user info for all users in reservations
      final userIds = reservationsResponse.map((r) => r['user_id'] as String).toSet().toList();
      final Map<String, Map<String, dynamic>> userInfoMap = {};
      if (userIds.isNotEmpty) {
        final usersResponse = await _client
            .from('user_info')
            .select('id, username, email, first_name, last_name, middle_name, role')
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
          final items = itemsMap[reservationId]!;
          if (items.length == 1) {
            roomItemReserved = items[0].itemName;
          } else {
            roomItemReserved = '${items.length} items';
          }
        } else {
          roomItemReserved = 'Room ID: ${reservation['room_id'] ?? 'Unknown'}';
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

      // Cache the result with 30 minute TTL (historical data is static)
      await _cache.set(cacheKey, reservations.map((reservation) => {
        'reservationId': reservation.reservationId,
        'userName': reservation.userName,
        'role': reservation.role,
        'reservationType': reservation.reservationType,
        'roomItemReserved': reservation.roomItemReserved,
        'reservationDate': reservation.reservationDate,
        'timeSchedule': reservation.timeSchedule,
        'status': reservation.status,
        'dateCreated': reservation.dateCreated,
        'items': reservation.items?.map((item) => {
          'itemId': item.itemId,
          'itemName': item.itemName,
          'quantity': item.quantity,
          'returnedQuantity': item.returnedQuantity,
          'status': item.status,
        }).toList(),
      }).toList(), ttlMinutes: 30);

      return reservations;
    } catch (e) {
      throw Exception('Failed to fetch reservations: $e');
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
            year,
            section,
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
              middle_name,
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
