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
  }) async {
    try {
      // Build base query without user info join
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableAuditLogs)
          .select()
          .gte('created_at', DateTime.now().subtract(Duration(days: days)).toIso8601String())
          .order('created_at', ascending: false);

      // Process logs
      List<AuditLog> logs = response.map((e) => AuditLog.fromJson(e)).toList();

      // Fetch user information for unique user IDs
      final uniqueUserIds = logs.map((log) => log.userId).toSet().toList();
      final userMap = <String, String?>{};
      
      if (uniqueUserIds.isNotEmpty) {
        final usersResponse = await SupabaseService.database
            .from(SupabaseConfig.tableUserInfo)
            .select('id, first_name, last_name')
            .inFilter('id', uniqueUserIds);
        
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

      // Filter on client side if needed
      if (entityType != null && entityType.isNotEmpty && entityType != 'all') {
        logs = logs.where((log) => log.entityType == entityType).toList();
      }
      if (actionType != null && actionType.isNotEmpty && actionType != 'all') {
        logs = logs.where((log) => log.actionType == actionType).toList();
      }
      if (userId != null && userId.isNotEmpty) {
        logs = logs.where((log) => log.userId == userId).toList();
      }

      return logs;
    } catch (e) {
      print('Failed to fetch audit logs: $e');
      return [];
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
