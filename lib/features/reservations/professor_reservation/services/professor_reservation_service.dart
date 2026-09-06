import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/service/cache_service.dart';
import '../models/professor_reservation_model.dart';

class ProfessorReservationService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cache = CacheService();

  /// Fetch professor reservations with pagination
  Future<List<ProfessorReservation>> fetchProfessorReservations({int page = 1, int limit = 20}) async {
    try {
      final start = (page - 1) * limit;
      final end = start + limit - 1;

      // Fetch paginated reservations first without user_info relation
      // Professor-made reservations are ready for admin review after professor
      // approval, but must remain on this page only while admin approval is pending.
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
          .eq('professor_approval', 'Approved')
          .eq('admin_approval', 'Pending')
          .order('created_at', ascending: false)
          .range(start, end);

      print('Fetched ${reservationsResponse.length} reservations from database');

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

      // Fetch chemical usage with chemical info
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
              purpose,
              chemicals (
                chemical_id,
                chemical_name
              )
            ''')
            .inFilter('reservation_id', reservationIds)
            .eq('is_deleted', false);

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

      // Fetch room names
      final roomIds = reservationsResponse
          .where((r) => r['room_id'] != null)
          .map((r) => r['room_id'] as int)
          .toSet()
          .toList();
      final Map<int, String> roomNameMap = {};
      if (roomIds.isNotEmpty) {
        final roomsResponse = await _client
            .from('rooms')
            .select('room_id, room_name')
            .inFilter('room_id', roomIds);
        for (var room in roomsResponse) {
          roomNameMap[room['room_id'] as int] = room['room_name'] as String;
        }
      }

      // Map reservations to ProfessorReservation model
      List<ProfessorReservation> reservations = [];
      for (var reservation in reservationsResponse) {
        final reservationId = reservation['reservation_id'] as int;
        final userId = reservation['user_id'] as String?;
        final userInfo = userId != null ? userInfoMap[userId] : null;

        // Only include reservations made by professors
        if (userInfo == null || userInfo['role'] != 'professor') {
          continue;
        }

        // Format professor name - use the professor field directly
        String professorName = reservation['professor']?.toString() ?? '';
        if (professorName.isEmpty) {
          final firstName = userInfo['first_name'] ?? '';
          final lastName = userInfo['last_name'] ?? '';
          professorName = firstName.isNotEmpty || lastName.isNotEmpty
              ? '$firstName $lastName'.trim()
              : userInfo['username'] ?? 'Unknown';
        }

        // Format date
        final reservationDate = reservation['reservation_date'];
        final formattedDate = _formatDate(reservationDate);

        // Format time
        final startTime = reservation['start_time'];
        final endTime = reservation['end_time'];
        final formattedTime = _formatTimeSchedule(startTime, endTime);

        // Format resources: room, chemicals, and items
        List<String> resourceParts = [];

        // Room
        if (reservation['room_id'] != null) {
          final roomName = roomNameMap[reservation['room_id'] as int] ?? 'Room';
          resourceParts.add('Room: $roomName');
        }

        // Chemicals
        if (chemicalsMap.containsKey(reservationId) && chemicalsMap[reservationId]!.isNotEmpty) {
          final chems = chemicalsMap[reservationId]!;
          final chemList = chems.map((chem) {
            final chemical = chem['chemicals'];
            if (chemical != null) {
              final name = chemical['chemical_name'] ?? '';
              final qty = chem['quantity_used'] ?? '';
              final unit = chem['unit'] ?? '';
              return '$name $qty$unit'.trim();
            }
            return '';
          }).where((s) => s.isNotEmpty).join(', ');
          if (chemList.isNotEmpty) {
            resourceParts.add('Chemicals: $chemList');
          }
        }

        // Items/Assets
        if (itemsMap.containsKey(reservationId) && itemsMap[reservationId]!.isNotEmpty) {
          final items = itemsMap[reservationId]!;
          final itemList = items.map((item) {
            final asset = item['lab_assets'];
            if (asset != null) {
              final itemName = asset['item_name'] ?? '';
              final quantity = item['quantity_borrowed'] ?? 0;
              return '$itemName x$quantity';
            }
            return '';
          }).where((s) => s.isNotEmpty).join(', ');
          if (itemList.isNotEmpty) {
            resourceParts.add('Items: $itemList');
          }
        }

        String resources = resourceParts.isEmpty ? '' : resourceParts.join('\n');

        // Format last updated
        final updatedAt = reservation['updated_at'];
        final formattedLastUpdated = _formatDate(updatedAt);

        final profApproval = reservation['professor_approval']?.toString() ?? 'Pending';
        print('Reservation $reservationId: professor_approval=$profApproval');

        reservations.add(ProfessorReservation(
          reservationId: reservationId.toString(),
          roomId: reservation['room_id']?.toString(),
          professorName: professorName,
          date: formattedDate,
          time: formattedTime,
          resources: resources,
          additionalNote: reservation['additional_note']?.toString() ?? '',
          professorApproval: profApproval,
          adminApproval: reservation['admin_approval']?.toString() ?? 'Pending',
          status: reservation['status']?.toString() ?? 'Pending',
          lastUpdated: formattedLastUpdated,
        ));
      }

      print('Mapped ${reservations.length} professor reservations');
      return reservations;
    } catch (e) {
      print('Error fetching professor reservations: $e');
      throw Exception('Failed to fetch professor reservations: $e');
    }
  }

  /// Update the room's status (e.g. set to "Occupied" when a reservation is approved)
  Future<void> updateRoomStatus(int roomId, String status) async {
    try {
      await _client
          .from('rooms')
          .update({'status': status})
          .eq('room_id', roomId);

      // Clear rooms cache
      await _cache.remove('rooms_list');
    } catch (e) {
      throw Exception('Failed to update room status: $e');
    }
  }

  /// Update professor approval status
  Future<void> updateProfessorApproval(int reservationId, String approval) async {
    try {
      await _client
          .from('reservations')
          .update({'professor_approval': approval})
          .eq('reservation_id', reservationId);

      // Clear dashboard cache since this affects stats
      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_recent_activities');
    } catch (e) {
      throw Exception('Failed to update professor approval: $e');
    }
  }

  /// Count total professor reservations (for pagination)
  Future<int> countProfessorReservations() async {
    try {
      final response = await _client
          .from('reservations')
          .select('reservation_id')
          .eq('professor_approval', 'Approved')
          .eq('admin_approval', 'Pending')
          .count();
      return response.count;
    } catch (e) {
      print('Error counting professor reservations: $e');
      return 0;
    }
  }

  /// Approve reservation: admin_approval = 'Approved', status = 'Ongoing'
  Future<void> approveReservation(int reservationId) async {
    try {
      await _client
          .from('reservations')
          .update({
            'admin_approval': 'Approved',
            'status': 'Ongoing',
          })
          .eq('reservation_id', reservationId);

      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_recent_activities');
    } catch (e) {
      throw Exception('Failed to approve reservation: $e');
    }
  }

  /// Reject reservation: admin_approval = 'Declined', status = 'Declined'
  Future<void> rejectReservation(int reservationId) async {
    try {
      await _client
          .from('reservations')
          .update({
            'admin_approval': 'Declined',
            'status': 'Declined',
          })
          .eq('reservation_id', reservationId);

      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_recent_activities');
    } catch (e) {
      throw Exception('Failed to reject reservation: $e');
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
