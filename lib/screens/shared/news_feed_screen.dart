import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import '../../services/announcement_service.dart';
import 'view_announcement_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  final bool isTechAdmin;                                          // ✅ ADDED
  const NewsFeedScreen({super.key, this.isTechAdmin = false});    // ✅ ADDED

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final _service = AnnouncementService();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // ✅ switch data source based on role
      final data = widget.isTechAdmin
          ? await _service.getTechAdminFeed()
          : await _service.getNewsFeed();
      if (!mounted) return;
      setState(() => _announcements = data);
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

            // ── HEADER ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'News Feed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      // ✅ subtitle differs per role
                      widget.isTechAdmin
                          ? 'Announcements you are tagged in or need tech assistance'
                          : 'Announcements you are mentioned in',
                      style: const TextStyle(color: Colors.grey),
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

            // ── CONTENT ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _announcements.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) =>
                              _buildCard(_announcements[index]),
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
          Icon(Icons.feed, size: 80, color: Colors.grey.shade300),
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
          Text(
            widget.isTechAdmin
                ? 'Announcements tagged to you or needing tech assistance will appear here'
                : 'Announcements you are mentioned in will appear here',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
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
    final attendeeType = announcement['attendeeType'] ?? 'Physical';

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

            // ── TITLE ROW + BADGES ──
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
                const SizedBox(width: 8),
                // Attendee type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: attendeeType == 'Virtual'
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: attendeeType == 'Virtual'
                          ? Colors.purple.withOpacity(0.5)
                          : Colors.blue.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        attendeeType == 'Virtual'
                            ? Icons.video_call
                            : Icons.person,
                        size: 11,
                        color: attendeeType == 'Virtual'
                            ? Colors.purple
                            : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attendeeType,
                        style: TextStyle(
                          fontSize: 11,
                          color: attendeeType == 'Virtual'
                              ? Colors.purple
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tech assist badge
                if (needsTech) ...[
                  const SizedBox(width: 6),
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
                              fontSize: 11, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── INFO CHIPS ──
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

            // ── VIEW BUTTON ──
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _viewAnnouncement(announcement),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
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
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  void _viewAnnouncement(Map<String, dynamic> announcement) =>
    ViewAnnouncementScreen.show(context, announcement);
}