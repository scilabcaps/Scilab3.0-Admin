import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/service/cache_service.dart';
import '../models/ongoing_reservation_model.dart';

class OngoingReservationService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cache = CacheService();

  /// Fetch all ongoing reservations with user information
  Future<List<OngoingReservation>> fetchOngoingReservations() async {
    try {
      // Fetch reservations with status 'Ongoing'
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
          .eq('status', 'Ongoing')
          .order('created_at', ascending: false);

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

      // Fetch user info for all users
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
            final year = reservation['year']?.toString() ?? '';
            final section = reservation['section']?.toString() ?? '';
            programYear = year.isNotEmpty || section.isNotEmpty
                ? '$year - $section'.trim()
                : '';
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

        // Format items from reservation_items
        List<ReservedItem>? items;
        if (itemsMap.containsKey(reservationId) && itemsMap[reservationId]!.isNotEmpty) {
          final itemsData = itemsMap[reservationId]!;
          items = itemsData.map((item) {
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
              itemName: itemName,
              quantity: quantity,
              returnedQuantity: returnedQuantity,
              status: itemStatus,
            );
          }).toList();
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
