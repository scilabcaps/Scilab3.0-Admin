import 'package:flutter/foundation.dart';
import '../../../../core/api/supabase_client.dart';
import '../../../../core/api/supabase_config.dart';
import '../models/announcement_model.dart';

class AnnouncementController extends ChangeNotifier {
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableAnnouncements)
          .select()
          .order('publish_at', ascending: false);
      _announcements = (response as List)
          .map((row) => Announcement.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      _errorMessage = 'Unable to load announcements. Please try again.';
      debugPrint('Error loading announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAnnouncement({required String title, required String content}) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'You must be signed in to add an announcement.';
      notifyListeners();
      return false;
    }
    try {
      await SupabaseService.database.from(SupabaseConfig.tableAnnouncements).insert({
        'title': title.trim(),
        'content': content.trim(),
        'created_by': userId,
        'is_published': true,
      });
      await loadAnnouncements();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to add announcement. Please try again.';
      debugPrint('Error adding announcement: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String content,
  }) async {
    try {
      await SupabaseService.database
          .from(SupabaseConfig.tableAnnouncements)
          .update({'title': title.trim(), 'content': content.trim()})
          .eq('id', id);
      await loadAnnouncements();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update announcement. Please try again.';
      debugPrint('Error updating announcement: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAnnouncement(String id) async {
    try {
      await SupabaseService.database
          .from(SupabaseConfig.tableAnnouncements)
          .delete()
          .eq('id', id);
      _announcements = _announcements.where((item) => item.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to delete announcement. Please try again.';
      debugPrint('Error deleting announcement: $e');
      notifyListeners();
      return false;
    }
  }
}
