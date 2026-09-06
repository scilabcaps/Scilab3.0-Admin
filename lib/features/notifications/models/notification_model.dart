class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.entityType,
    this.entityId,
    this.action,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final String? entityType;
  final int? entityId;
  final String? action;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      relatedId: json['related_id']?.toString(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'].toString()),
      entityType: json['entity_type']?.toString(),
      entityId: (json['entity_id'] as num?)?.toInt(),
      action: json['action']?.toString(),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        entityType: entityType,
        entityId: entityId,
        action: action,
      );
}
