import 'package:flutter_test/flutter_test.dart';
import 'package:admin_scalib/features/room_and_resources/announcements/models/announcement_model.dart';

void main() {
  test('parses an announcement row from Supabase', () {
    final announcement = Announcement.fromJson({
      'id': 'abc',
      'title': 'Lab closed',
      'content': 'The lab is closed today.',
      'created_by': 'user-1',
      'publish_at': '2026-10-04T08:00:00Z',
      'expires_at': null,
      'is_published': true,
      'created_at': '2026-10-04T08:00:00Z',
    });

    expect(announcement.id, 'abc');
    expect(announcement.title, 'Lab closed');
    expect(announcement.isPublished, isTrue);
    expect(announcement.expiresAt, isNull);
  });
}
