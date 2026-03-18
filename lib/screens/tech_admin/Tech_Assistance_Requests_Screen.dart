import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import '../shared/view_announcement_screen.dart';

class TechAssistanceRequestsScreen extends StatefulWidget {
  const TechAssistanceRequestsScreen({super.key});

  @override
  State<TechAssistanceRequestsScreen> createState() =>
      _TechAssistanceRequestsScreenState();
}

class _TechAssistanceRequestsScreenState
    extends State<TechAssistanceRequestsScreen> {
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  try {
    final now = Timestamp.fromDate(DateTime.now());

    final snapshot = await _firestore
        .collection('announcements')
        .where('needsTechAssist', isEqualTo: true)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .orderBy('dateTime') // ✅ ascending is the default, no parameter needed
        .get();

    if (!mounted) return;
    setState(() {
      _requests = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  } catch (e) {
    if (!mounted) return;
    _showSnackbar('Error loading requests: $e', isError: true);
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
                      'Tech Assistance Requests',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoading
                          ? 'Loading...'
                          : '${_requests.length} upcoming request${_requests.length != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadRequests,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── LIST ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
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
          Icon(Icons.build_circle_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No upcoming tech requests',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upcoming announcements requiring tech assistance will appear here.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _requests[index];
        final dateTime = a['dateTime'] != null
            ? (a['dateTime'] as Timestamp).toDate()
            : null;

        // ── How soon is this? ──
        final daysUntil = dateTime != null
            ? dateTime.difference(DateTime.now()).inDays
            : null;

        final urgencyColor = daysUntil == null
            ? Colors.grey
            : daysUntil == 0
                ? Colors.red
                : daysUntil <= 3
                    ? Colors.orange
                    : Colors.green;

        final urgencyLabel = daysUntil == null
            ? 'Unknown'
            : daysUntil == 0
                ? 'Today'
                : daysUntil == 1
                    ? 'Tomorrow'
                    : 'In $daysUntil days';

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              children: [

                // ── Urgency indicator ──
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.build_circle,
                    color: urgencyColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // ── Urgency badge ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              urgencyLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: urgencyColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Date & time
                      if (dateTime != null)
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${dateTime.day}/${dateTime.month}/${dateTime.year}  ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),

                      // Venue
                      if ((a['venueName'] ?? '').isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              a['venueName'],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),

                      // Attendee type
                      Row(
                        children: [
                          Icon(
                            a['attendeeType'] == 'Virtual'
                                ? Icons.video_call
                                : Icons.person,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            a['attendeeType'] ?? 'Physical',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ── View Button ──
                OutlinedButton.icon(
                  onPressed: () => ViewAnnouncementScreen.show(context, a),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
} 