import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/service/cache_service.dart';
import '../models/student_reservation_model.dart';

class StudentReservationService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cache = CacheService();

  /// Fetch all student reservations with user information
  Future<List<StudentReservation>> fetchStudentReservations() async {
    try {
      // Fetch all reservations first without user_info relation
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
          .order('created_at', ascending: false);

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

      // Map reservations to StudentReservation model
      List<StudentReservation> reservations = [];
      for (var reservation in reservationsResponse) {
        final reservationId = reservation['reservation_id'] as int;
        final userId = reservation['user_id'] as String?;
        final userInfo = userId != null ? userInfoMap[userId] : null;

        // Only include reservations made by students
        if (userInfo == null || userInfo['role'] != 'student') {
          continue;
        }

        // Format student name
        String studentName = '';
        if (userInfo != null) {
          final firstName = userInfo['first_name'] ?? '';
          final lastName = userInfo['last_name'] ?? '';
          studentName = firstName.isNotEmpty || lastName.isNotEmpty
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

        // Format resources from items
        String resources = '';
        if (itemsMap.containsKey(reservationId) && itemsMap[reservationId]!.isNotEmpty) {
          final items = itemsMap[reservationId]!;
          final resourceList = items.map((item) {
            final asset = item['lab_assets'];
            if (asset != null) {
              final itemName = asset['item_name'] ?? '';
              final quantity = item['quantity_borrowed'] ?? 0;
              return '$itemName x$quantity';
            }
            return '';
          }).where((s) => s.isNotEmpty).join(', ');
          resources = resourceList;
        }

        // Format year and section
        final year = reservation['year']?.toString() ?? '';
        final section = reservation['section']?.toString() ?? '';
        final yearSection = year.isNotEmpty || section.isNotEmpty
            ? '$year - $section'.trim()
            : '';

        // Format professor name
        final professorName = reservation['professor']?.toString() ?? '';

        // Format last updated
        final updatedAt = reservation['updated_at'];
        final formattedLastUpdated = _formatDate(updatedAt);

        // Use admin_approval for status
        final adminApproval = reservation['admin_approval']?.toString() ?? 'Pending';
        print('Reservation $reservationId: admin_approval=$adminApproval');

        reservations.add(StudentReservation(
          reservationId: reservationId.toString(),
          studentName: studentName,
          date: formattedDate,
          time: formattedTime,
          resources: resources,
          yearSection: yearSection,
          professor: professorName,
          status: adminApproval,
          lastUpdated: formattedLastUpdated,
        ));
      }

      print('Mapped ${reservations.length} student reservations');
      return reservations;
    } catch (e) {
      print('Error fetching student reservations: $e');
      throw Exception('Failed to fetch student reservations: $e');
    }
  }

  /// Update admin approval status
  Future<void> updateAdminApproval(int reservationId, String approval) async {
    try {
      await _client
          .from('reservations')
          .update({'admin_approval': approval})
          .eq('reservation_id', reservationId);

      // Clear dashboard cache since this affects stats
      await _cache.remove('dashboard_stats');
      await _cache.remove('dashboard_recent_activities');
    } catch (e) {
      throw Exception('Failed to update admin approval: $e');
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
