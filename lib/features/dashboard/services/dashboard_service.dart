import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/supabase_client.dart';
import '../models/dashboard_model.dart' show DashboardStats, CourseReservationData, BorrowedItem, RecentActivity;

class DashboardService {
  final SupabaseClient _client = SupabaseService.database;

  Future<DashboardStats> getDashboardStats() async {
    try {
      // Get total reservations
      final totalResResponse = await _client
          .from('reservations')
          .select('reservation_id')
          .eq('is_deleted', false);
      
      // Get approved reservations
      final approvedResResponse = await _client
          .from('reservations')
          .select('reservation_id')
          .eq('status', 'Approved')
          .eq('is_deleted', false);
      
      // Get pending reservations
      final pendingResResponse = await _client
          .from('reservations')
          .select('reservation_id')
          .eq('status', 'Pending')
          .eq('is_deleted', false);
      
      // Get rejected/declined/cancelled reservations
      final rejectedResResponse = await _client
          .from('reservations')
          .select('reservation_id')
          .or('status.eq.Declined,status.eq.Cancelled')
          .eq('is_deleted', false);
      
      // Get total users
      final usersResponse = await _client
          .from('user_info')
          .select('id')
          .eq('is_banned', false);
      
      // Get active rooms
      final activeRoomsResponse = await _client
          .from('rooms')
          .select('room_id')
          .eq('status', 'Available')
          .eq('is_deleted', false);
      
      // Get maintenance rooms
      final maintenanceRoomsResponse = await _client
          .from('rooms')
          .select('room_id')
          .eq('status', 'Maintenance')
          .eq('is_deleted', false);

      // Get total chemicals
      final chemicalsResponse = await _client
          .from('chemicals')
          .select('chemical_id')
          .eq('is_deleted', false);

      // Get total lab assets
      final labAssetsResponse = await _client
          .from('lab_assets')
          .select('asset_id')
          .eq('is_deleted', false);

      final stats = DashboardStats(
        totalReservations: totalResResponse.length,
        approvedReservations: approvedResResponse.length,
        pendingReservations: pendingResResponse.length,
        rejectedReservations: rejectedResResponse.length,
        totalUsers: usersResponse.length,
        activeRooms: activeRoomsResponse.length,
        maintenanceRooms: maintenanceRoomsResponse.length,
        totalChemicals: chemicalsResponse.length,
        totalLabAssets: labAssetsResponse.length,
      );

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  Future<List<CourseReservationData>> getTopCourses() async {
    try {
      // Get all reservations with course column directly
      final response = await _client
          .from('reservations')
          .select('course')
          .eq('is_deleted', false);

      // Group by course name and count reservations
      final Map<String, int> courseCounts = {};

      for (var res in response) {
        // Get course directly from reservations table
        String course;
        if (res['course'] != null && res['course'].toString().trim().isNotEmpty) {
          course = res['course'].toString();
        } else {
          course = 'Unknown';
        }

        courseCounts[course] = (courseCounts[course] ?? 0) + 1;
      }

      // Convert to list and sort by count (descending)
      final sortedCourses = courseCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Take top 10 courses
      final now = DateTime.now();
      final topCourses = sortedCourses.take(10).map((entry) {
        return CourseReservationData(
          course: entry.key,
          reservationCount: entry.value,
          month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
        );
      }).toList();

      return topCourses;
    } catch (e) {
      throw Exception('Failed to fetch top courses: $e');
    }
  }

  Future<List<BorrowedItem>> getBorrowedItems() async {
    try {
      final List<BorrowedItem> items = [];
      
      // Get most borrowed lab assets
      final assetsResponse = await _client
          .from('lab_assets')
          .select('asset_id, item_name, category, total_stock, available_stock')
          .eq('is_deleted', false)
          .order('total_stock', ascending: false);

      for (var asset in assetsResponse) {
        final borrowedCount = (asset['total_stock'] as int) - (asset['available_stock'] as int);
        items.add(BorrowedItem(
          name: asset['item_name'],
          count: borrowedCount,
          status: asset['available_stock'] > 0 ? 'AVAILABLE' : 'OUT OF STOCK',
          category: asset['category'],
        ));
      }

      // Get most used chemicals
      final chemicalsResponse = await _client
          .from('chemicals')
          .select('chemical_id, chemical_name, stock_quantity, unit')
          .eq('is_deleted', false)
          .order('stock_quantity', ascending: false)
          .limit(4);

      for (var chem in chemicalsResponse) {
        final stockQuantity = chem['stock_quantity'];
        final quantity = stockQuantity is num ? stockQuantity.toInt() : int.tryParse(stockQuantity.toString()) ?? 0;
        
        items.add(BorrowedItem(
          name: chem['chemical_name'],
          count: quantity,
          status: quantity > 10 ? 'AVAILABLE' : 'LOW STOCK',
          category: 'Chemicals',
        ));
      }

      // Sort by count and return top items
      items.sort((a, b) => b.count.compareTo(a.count));
      final topItems = items.take(12).toList();

      return topItems;
    } catch (e) {
      throw Exception('Failed to fetch borrowed items: $e');
    }
  }

  Future<List<RecentActivity>> getRecentActivities() async {
    try {
      final List<RecentActivity> activities = [];
      
      // Get recent reservations
      final recentReservations = await _client
          .from('reservations')
          .select('reservation_id, reservation_date, professor, status, created_at')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(3);

      for (var res in recentReservations) {
        final createdAt = DateTime.parse(res['created_at']);
        final timestamp = _formatTimestamp(createdAt);
        
        activities.add(RecentActivity(
          id: res['reservation_id'].toString(),
          title: 'New Reservation',
          description: '${res['professor'] ?? 'User'} made a reservation',
          timestamp: timestamp,
          type: 'reservation',
        ));
      }

      // Get recent stock history
      final stockHistory = await _client
          .from('stock_history')
          .select('history_id, item_type, change_reason, created_at')
          .order('created_at', ascending: false)
          .limit(2);

      for (var history in stockHistory) {
        final createdAt = DateTime.parse(history['created_at']);
        final timestamp = _formatTimestamp(createdAt);
        
        activities.add(RecentActivity(
          id: history['history_id'].toString(),
          title: 'Inventory Update',
          description: history['change_reason'] ?? 'Stock updated',
          timestamp: timestamp,
          type: 'inventory',
        ));
      }

      // Sort by timestamp (most recent first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final topActivities = activities.take(5).toList();

      return topActivities;
    } catch (e) {
      throw Exception('Failed to fetch recent activities: $e');
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

}
