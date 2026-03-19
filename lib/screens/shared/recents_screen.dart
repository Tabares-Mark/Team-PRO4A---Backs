import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import '../../services/announcement_service.dart';
import 'view_announcement_screen.dart';
import 'edit_announcement_screen.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  final _service = AnnouncementService();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  void _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _service.getMyAnnouncements();
    if (!mounted) return;
    setState(() {
      _announcements = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recents',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Announcements you have created',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadAnnouncements,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator())
                  : _announcements.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            return _buildCard(
                                _announcements[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dynamic_feed,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No announcements yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Announcements you create will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> announcement) {
    final needsTech = announcement['needsTechAssist'] ?? false;
    final dateTime = announcement['dateTime'] != null
        ? (announcement['dateTime'] as Timestamp).toDate()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title + badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (needsTech)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.build_circle,
                            size: 11, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Tech Assist',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (dateTime != null)
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${dateTime.day}/${dateTime.month}/${dateTime.year}  ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                  ),
                _buildInfoChip(
                  Icons.location_on,
                  announcement['venueName'] ?? 'No venue',
                ),
                _buildInfoChip(
                  Icons.people,
                  '${(announcement['attendeeUnitIds'] as List?)?.length ?? 0} unit(s)',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ FIXED — Wrap instead of Row to prevent overflow
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _viewAnnouncement(announcement),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(
                        color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _editAnnouncement(announcement),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _confirmDelete(announcement['id']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  void _viewAnnouncement(Map<String, dynamic> announcement) =>
    ViewAnnouncementScreen.show(context, announcement);

  void _editAnnouncement(Map<String, dynamic> announcement) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAnnouncementScreen(announcement: announcement),
      ),
    );
    if (result == true) _loadAnnouncements(); // ✅ use 'result'
  }
  
  void _confirmDelete(String announcementId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
            'Are you sure you want to delete this? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteAnnouncement(announcementId);
              _loadAnnouncements();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}