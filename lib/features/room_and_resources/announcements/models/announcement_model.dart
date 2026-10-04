class Announcement {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final DateTime publishAt;
  final DateTime? expiresAt;
  final bool isPublished;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.publishAt,
    required this.expiresAt,
    required this.isPublished,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdBy: json['created_by'].toString(),
      publishAt: DateTime.tryParse(json['publish_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
