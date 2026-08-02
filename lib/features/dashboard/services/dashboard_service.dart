import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/supabase_client.dart';
import '../../../core/service/cache_service.dart';
import '../models/dashboard_model.dart' show DashboardStats, CourseReservationData, BorrowedItem, RecentActivity;

class DashboardService {
  final SupabaseClient _client = SupabaseService.database;
  final CacheService _cache = CacheService();

  Future<DashboardStats> getDashboardStats() async {
    final cacheKey = 'dashboard_stats';
    
    // Try to get from cache first
    final cachedStats = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedStats != null) {
      return DashboardStats(
        totalReservations: cachedStats['totalReservations'] as int,
        approvedReservations: cachedStats['approvedReservations'] as int,
        pendingReservations: cachedStats['pendingReservations'] as int,
        rejectedReservations: cachedStats['rejectedReservations'] as int,
        totalUsers: cachedStats['totalUsers'] as int,
        activeRooms: cachedStats['activeRooms'] as int,
        maintenanceRooms: cachedStats['maintenanceRooms'] as int,
        totalChemicals: cachedStats['totalChemicals'] as int,
        totalLabAssets: cachedStats['totalLabAssets'] as int,
      );
    }

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

      // Cache the result with 10 minute TTL
      await _cache.set(cacheKey, {
        'totalReservations': stats.totalReservations,
        'approvedReservations': stats.approvedReservations,
        'pendingReservations': stats.pendingReservations,
        'rejectedReservations': stats.rejectedReservations,
        'totalUsers': stats.totalUsers,
        'activeRooms': stats.activeRooms,
        'maintenanceRooms': stats.maintenanceRooms,
        'totalChemicals': stats.totalChemicals,
        'totalLabAssets': stats.totalLabAssets,
      }, ttlMinutes: 10);

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  Future<List<CourseReservationData>> getTopCourses() async {
    final cacheKey = 'dashboard_top_courses';
    
    // Try to get from cache first
    final cachedCourses = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedCourses != null) {
      return cachedCourses.map((data) => CourseReservationData(
        course: data['course'] as String,
        reservationCount: data['reservation_count'] as int,
        month: data['month'] as String,
      )).toList();
    }

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

      // Cache the result with 15 minute TTL
      await _cache.set(cacheKey, topCourses.map((data) => {
        'course': data.course,
        'reservation_count': data.reservationCount,
        'month': data.month,
      }).toList(), ttlMinutes: 15);

      return topCourses;
    } catch (e) {
      throw Exception('Failed to fetch top courses: $e');
    }
  }

  Future<List<BorrowedItem>> getBorrowedItems() async {
    final cacheKey = 'dashboard_borrowed_items';
    
    // Try to get from cache first
    final cachedItems = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedItems != null) {
      return cachedItems.map((data) => BorrowedItem(
        name: data['name'] as String,
        count: data['count'] as int,
        status: data['status'] as String,
        category: data['category'] as String,
      )).toList();
    }

    try {
      final List<BorrowedItem> items = [];
      
      // Get most borrowed lab assets
      final assetsResponse = await _client
          .from('lab_assets')
          .select('asset_id, item_name, category, total_stock, available_stock')
          .eq('is_deleted', false)
          .order('total_stock', ascending: false)
          .limit(8);

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

      // Cache the result with 20 minute TTL (inventory changes slowly)
      await _cache.set(cacheKey, topItems.map((item) => {
        'name': item.name,
        'count': item.count,
        'status': item.status,
        'category': item.category,
      }).toList(), ttlMinutes: 20);

      return topItems;
    } catch (e) {
      throw Exception('Failed to fetch borrowed items: $e');
    }
  }

  Future<List<RecentActivity>> getRecentActivities() async {
    final cacheKey = 'dashboard_recent_activities';
    
    // Try to get from cache first (shorter TTL since activities change frequently)
    final cachedActivities = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedActivities != null) {
      return cachedActivities.map((data) => RecentActivity(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String,
        timestamp: data['timestamp'] as String,
        type: data['type'] as String,
      )).toList();
    }

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

      // Cache the result with 5 minute TTL (activities change frequently)
      await _cache.set(cacheKey, topActivities.map((activity) => {
        'id': activity.id,
        'title': activity.title,
        'description': activity.description,
        'timestamp': activity.timestamp,
        'type': activity.type,
      }).toList(), ttlMinutes: 5);

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

  /// Clear all dashboard cache
  Future<void> clearCache() async {
    await _cache.remove('dashboard_stats');
    // Clear top courses cache too (key used: 'dashboard_top_courses')
    await _cache.remove('dashboard_top_courses');
    await _cache.remove('dashboard_reservation_trends');
    await _cache.remove('dashboard_borrowed_items');
    await _cache.remove('dashboard_recent_activities');
  }
}
