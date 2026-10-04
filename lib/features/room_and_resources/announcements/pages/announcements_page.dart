import 'package:flutter/material.dart';
import '../controllers/announcement_controller.dart';
import '../models/announcement_model.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final AnnouncementController _controller = AnnouncementController();

  @override
  void initState() {
    super.initState();
    _controller.loadAnnouncements();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Announcements', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                Row(children: [
                  IconButton(onPressed: _controller.isLoading ? null : _controller.loadAnnouncements, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add), label: const Text('Add Announcement')),
                ]),
              ],
            ),
            const SizedBox(height: 24),
            if (_controller.errorMessage != null) _buildError(),
            if (_controller.isLoading && _controller.announcements.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
            else if (_controller.announcements.isEmpty)
              _buildEmptyState()
            else
              ..._controller.announcements.map(_buildAnnouncementCard),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Row(children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(_controller.errorMessage!, style: TextStyle(color: Colors.red.shade700))),
          TextButton(onPressed: _controller.loadAnnouncements, child: const Text('Retry')),
        ]),
      );

  Widget _buildEmptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: _cardDecoration(),
        child: const Column(children: [
          Icon(Icons.campaign_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('No announcements yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Add an announcement to share an update with users.'),
        ]),
      );

  Widget _buildAnnouncementCard(Announcement announcement) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(22, 20, 14, 18),
        decoration: _cardDecoration(),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.campaign_outlined, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(announcement.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF18231B)))),
              const SizedBox(width: 12),
              _statusBadge(announcement.isPublished),
            ]),
            const SizedBox(height: 8),
            Text(announcement.content, style: TextStyle(fontSize: 15, height: 1.45, color: Colors.grey.shade800)),
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.schedule_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('Published ${_formatDate(announcement.publishAt)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ]),
          ])),
          PopupMenuButton<String>(
            tooltip: 'Announcement actions',
            onSelected: (action) => action == 'edit' ? _showAnnouncementDialog(announcement: announcement) : _confirmDelete(announcement),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ]),
      );

  Widget _statusBadge(bool isPublished) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: isPublished ? const Color(0xFFE8F5E9) : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: isPublished ? const Color(0xFF2E7D32) : Colors.grey, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(isPublished ? 'Published' : 'Draft', style: TextStyle(color: isPublished ? const Color(0xFF24642A) : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(.1), blurRadius: 4)]);

  String _formatDate(DateTime value) => '${value.month}/${value.day}/${value.year}';

  Future<void> _showAddDialog() => _showAnnouncementDialog();

  Future<void> _showAnnouncementDialog({Announcement? announcement}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: announcement?.title);
    final contentController = TextEditingController(text: announcement?.content);
    final isEditing = announcement != null;
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(28, 26, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.campaign_outlined, color: Color(0xFF2E7D32))),
          const SizedBox(width: 14),
          Expanded(child: Text(isEditing ? 'Edit announcement' : 'New announcement', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
          IconButton(onPressed: () => Navigator.pop(dialogContext, false), icon: const Icon(Icons.close), tooltip: 'Close'),
        ]),
        content: SizedBox(width: 520, child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isEditing ? 'Update the message shared with users.' : 'Share an important update with users.', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 22),
          TextFormField(controller: titleController, autofocus: true, textInputAction: TextInputAction.next, decoration: _inputDecoration('Title', Icons.title), validator: (value) => value == null || value.trim().isEmpty ? 'Enter a title' : null),
          const SizedBox(height: 16),
          TextFormField(controller: contentController, minLines: 5, maxLines: 8, decoration: _inputDecoration('Message', Icons.notes_outlined), validator: (value) => value == null || value.trim().isEmpty ? 'Enter announcement content' : null),
        ]))),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.icon(icon: Icon(isEditing ? Icons.save_outlined : Icons.send_outlined), label: Text(isEditing ? 'Save changes' : 'Publish'), onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final button = isEditing
                ? await _controller.updateAnnouncement(id: announcement.id, title: titleController.text, content: contentController.text)
                : await _controller.addAnnouncement(title: titleController.text, content: contentController.text);
            if (dialogContext.mounted) Navigator.pop(dialogContext, button);
          }),
        ],
      ),
    );
    titleController.dispose();
    contentController.dispose();
    if (added == true && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Announcement updated' : 'Announcement published')));
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFF7F9F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
      );

  Future<void> _confirmDelete(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete announcement?'),
        content: Text('“${announcement.title}” will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(foregroundColor: Colors.red.shade700), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      final deleted = await _controller.deleteAnnouncement(announcement.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(deleted ? 'Announcement deleted' : 'Unable to delete announcement')));
    }
  }
}
