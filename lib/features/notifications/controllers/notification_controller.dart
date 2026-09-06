import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({NotificationService? service}) : _service = service ?? NotificationService();
  final NotificationService _service;
  List<AppNotification> notifications = [];
  bool isLoading = false;
  String? errorMessage;
  RealtimeChannel? _channel;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  Future<void> initialize() async {
    if (_channel != null) return;
    isLoading = true;
    notifyListeners();
    try {
      notifications = await _service.fetchNotifications();
      errorMessage = null;
      _channel = _service.subscribe(onChange: _handleChange);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _handleChange(PostgresChangePayload payload) {
    final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
    if (record.isEmpty) return;
    final item = AppNotification.fromJson(Map<String, dynamic>.from(record));
    final index = notifications.indexWhere((existing) => existing.id == item.id);
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        if (index < 0) notifications = [item, ...notifications];
      case PostgresChangeEvent.update:
        if (index >= 0) notifications[index] = item;
      case PostgresChangeEvent.delete:
        if (index >= 0) notifications.removeAt(index);
      case PostgresChangeEvent.all:
        break;
    }
    notifyListeners();
  }

  Future<void> markAsRead(AppNotification item) async {
    if (item.isRead) return;
    notifications = notifications.map((n) => n.id == item.id ? n.copyWith(isRead: true) : n).toList();
    notifyListeners();
    try {
      await _service.markAsRead(item.id);
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _service.markAllAsRead();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) _service.unsubscribe(channel);
    super.dispose();
  }
}
