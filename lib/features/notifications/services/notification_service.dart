import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/supabase_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  SupabaseClient get _client => SupabaseService.database;

  Future<List<AppNotification>> fetchNotifications() async {
    if (SupabaseService.auth.currentUser == null) {
      return const <AppNotification>[];
    }
    final rows = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<int> unreadCount() async =>
      (await fetchNotifications()).where((notification) => !notification.isRead).length;

  Future<void> markAsRead(String id) async =>
      SupabaseService.auth.currentUser == null
          ? Future<void>.value()
          : _client.from('notifications').update({'is_read': true}).eq('id', id);

  Future<void> markAllAsRead() async =>
      SupabaseService.auth.currentUser == null
          ? Future<void>.value()
          : _client.from('notifications').update({'is_read': true}).eq('is_read', false);

  RealtimeChannel subscribe({required void Function(PostgresChangePayload) onChange}) {
    if (SupabaseService.auth.currentUser == null) {
      throw StateError('No authenticated user');
    }
    return _client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: onChange,
        )
        ..subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) => _client.removeChannel(channel);
}
