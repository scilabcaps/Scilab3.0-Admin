import '../../../core/api/supabase_client.dart';
import '../../../core/api/supabase_config.dart';
import '../models/audit_log_model.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();

  factory AuditService() => _instance;

  AuditService._internal();

  /// Log an audit action to Supabase
  Future<void> logAction({
    required String actionType,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? description,
  }) async {
    try {
      final currentUser = SupabaseService.auth.currentUser;
      if (currentUser == null) return;

      await SupabaseService.database
          .from(SupabaseConfig.tableAuditLogs)
          .insert({
        'user_id': currentUser.id,
        'action_type': actionType,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_values': oldValues,
        'new_values': newValues,
        'description': description,
      });
    } catch (e) {
      // Log error but don't throw - audit failures shouldn't break the app
      print('Failed to log audit action: $e');
    }
  }

  /// Get recent audit logs from Supabase
  Future<List<AuditLog>> getRecentLogs({
    int days = 30,
    String? entityType,
    String? actionType,
    String? userId,
    DateTime? through,
  }) async {
    try {
      final end = (through ?? DateTime.now()).toUtc();
      final start = end.subtract(Duration(days: days));
      List<AuditLog> logs = [];
      var offset = 0;
      // Fetch every batch, including when the server imposes a smaller row cap.
      while (true) {
        var query = SupabaseService.database
            .from(SupabaseConfig.tableAuditLogs)
            .select()
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());
        if (entityType != null && entityType.isNotEmpty && entityType != 'all') {
          query = query.eq('entity_type', entityType);
        }
        if (actionType != null && actionType.isNotEmpty && actionType != 'all') {
          query = query.eq('action_type', actionType);
        }
        if (userId != null && userId.isNotEmpty) {
          query = query.eq('user_id', userId);
        }
        final response = await query
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .range(offset, offset + 499);
        if (response.isEmpty) break;
        logs.addAll(response.map((row) => AuditLog.fromJson(row)));
        offset += response.length;
      }

      // Fetch user information for unique user IDs
      final uniqueUserIds = logs.map((log) => log.userId).toSet().toList();
      final userMap = <String, String?>{};
      
      for (var i = 0; i < uniqueUserIds.length; i += 100) {
        final batch = uniqueUserIds.skip(i).take(100).toList();
        final usersResponse = await SupabaseService.database
            .from(SupabaseConfig.tableUserInfo)
            .select('id, first_name, last_name')
            .inFilter('id', batch);
        
        for (final user in usersResponse) {
          final firstName = user['first_name'] as String? ?? '';
          final lastName = user['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          userMap[user['id'] as String] = fullName.isNotEmpty ? fullName : null;
        }
      }

      // Add user names to logs
      logs = logs.map((log) {
        final userName = userMap[log.userId];
        return log.copyWith(userName: userName);
      }).toList();

      return logs;
    } catch (e) {
      print('Failed to fetch audit logs: $e');
      rethrow;
    }
  }

  /// Get audit logs for a specific entity
  Future<List<AuditLog>> getLogsByEntity(String entityType, String entityId) async {
    return getRecentLogs(
      days: 365, // Longer retention for entity-specific queries
      entityType: entityType,
    ).then((logs) => logs.where((log) => log.entityId == entityId).toList());
  }

  /// Get audit logs for a specific user
  Future<List<AuditLog>> getLogsByUser(String userId) async {
    return getRecentLogs(days: 365, userId: userId);
  }
}
