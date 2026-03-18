import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';

class ViewAnnouncementScreen extends StatelessWidget {
  final Map<String, dynamic> announcement;
  const ViewAnnouncementScreen({super.key, required this.announcement});

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  // ✅ Static helper to show as dialog — call this instead of Navigator.push
  static void show(BuildContext context, Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ViewAnnouncementScreen(announcement: announcement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = announcement['dateTime'] != null
        ? (announcement['dateTime'] as Timestamp).toDate()
        : null;
    final needsTech = announcement['needsTechAssist'] == true;
    final agendaItems =
        List<String>.from(announcement['agendaItems'] ?? []);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HEADER + X ──
              Row(children: [
                Expanded(
                  child: Text(announcement['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  style: IconButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ]),

              // Tech badge
              if (needsTech) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build_circle,
                          size: 14, color: Colors.orange),
                      SizedBox(width: 6),
                      Text('Tech Assistance Required',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // ── DETAILS ──
              _row('Authority', announcement['authority'] ?? '—'),
              _row('To Preside', announcement['toPreside'] ?? '—'),
              _row('Date & Time',
                  dateTime != null ? _fmt(dateTime) : '—'),
              _row('Venue', announcement['venueName'] ?? '—'),
              _row('Attendee Type',
                  announcement['attendeeType'] ?? '—'),

              // Agenda
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Agenda',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              ...agendaItems.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  )),

              // Optional fields
              if ((announcement['invitedOrganizations'] ?? '').isNotEmpty) ...[
                const Divider(),
                _row('Invited Organizations',
                    announcement['invitedOrganizations']),
              ],
              if ((announcement['invitedNames'] ?? '').isNotEmpty) ...[
                const Divider(),
                _row('Invited Names', announcement['invitedNames']),
              ],
              if ((announcement['tasks'] ?? '').isNotEmpty) ...[
                const Divider(),
                _row('Tasks', announcement['tasks']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}