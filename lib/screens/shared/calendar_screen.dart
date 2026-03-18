import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import '../../services/announcement_service.dart';
import '../shared/view_announcement_screen.dart';

// ── Calendar type enum ──
enum CalendarType { unit, techAdmin, viewerAdmin }

class CalendarScreen extends StatefulWidget {
  final CalendarType calendarType;
  const CalendarScreen({super.key, required this.calendarType});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _service = AnnouncementService();
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  DateTime _today = DateTime.now();
  late DateTime _currentMonth;
  DateTime? _selectedDay;

  Map<int, List<Map<String, dynamic>>> _announcementsByDay = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_today.year, _today.month);
    _selectedDay = _today;
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> data = [];

      switch (widget.calendarType) {
        case CalendarType.unit:
          data = await _service.getNewsFeed();
          break;
        case CalendarType.techAdmin:
          data = await _service.getTechAdminFeed();
          break;
        case CalendarType.viewerAdmin:
          final snapshot = await _firestore
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .get();
          data = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          break;
      }

      if (!mounted) return;

      final Map<int, List<Map<String, dynamic>>> byDay = {};
      for (final a in data) {
        if (a['dateTime'] == null) continue;
        final dt = (a['dateTime'] as Timestamp).toDate();
        if (dt.year == _currentMonth.year &&
            dt.month == _currentMonth.month) {
          byDay.putIfAbsent(dt.day, () => []).add(a);
        }
      }

      setState(() {
        _announcements = data;
        _announcementsByDay = byDay;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading announcements: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _monthName {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  int get _daysInMonth =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

  int get _firstWeekday {
    final firstDay =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    return firstDay.weekday % 7;
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
                      'Calendar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleText,
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

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              // ✅ Expanded + SingleChildScrollView so page scrolls
              // instead of overflowing
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── CALENDAR CARD ──
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [

                              // Month title
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_month,
                                      color: AppTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    _monthName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Day of week headers
                              Row(
                                children: [
                                  'Sun', 'Mon', 'Tue', 'Wed',
                                  'Thu', 'Fri', 'Sat'
                                ]
                                    .map((d) => Expanded(
                                          child: Center(
                                            child: Text(
                                              d,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: d == 'Sun' ||
                                                        d == 'Sat'
                                                    ? Colors.grey.shade400
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 8),

                              // Day grid
                              _buildDayGrid(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── SELECTED DAY SECTION ──
                      if (_selectedDay != null) ...[
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDayLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if ((_announcementsByDay[
                                        _selectedDay!.day] ??
                                    [])
                                .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_announcementsByDay[_selectedDay!.day]!.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ✅ shrinkWrap list, no Expanded needed
                        _buildSelectedDayList(),
                      ],

                      // ✅ bottom padding so last card isn't cut off
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── DAY GRID ──
  Widget _buildDayGrid() {
    final totalCells = _firstWeekday + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final day = cellIndex - _firstWeekday + 1;

            if (day < 1 || day > _daysInMonth) {
              return const Expanded(child: SizedBox(height: 64));
            }

            final hasAnnouncements =
                _announcementsByDay.containsKey(day);
            final announcements = _announcementsByDay[day] ?? [];
            final isToday = day == _today.day &&
                _currentMonth.month == _today.month &&
                _currentMonth.year == _today.year;
            final isSelected = _selectedDay != null &&
                day == _selectedDay!.day &&
                _currentMonth.month == _selectedDay!.month &&
                _currentMonth.year == _selectedDay!.year;
            final isWeekend = colIndex == 0 || colIndex == 6;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = DateTime(
                      _currentMonth.year,
                      _currentMonth.month,
                      day,
                    );
                  });
                  if (hasAnnouncements) {
                    _showDayDialog(day, announcements);
                  }
                },
                child: Container(
                  height: 64,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : isToday
                            ? AppTheme.primaryBlue.withOpacity(0.1)
                            : hasAnnouncements
                                ? AppTheme.primaryBlue.withOpacity(0.05)
                                : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppTheme.primaryBlue, width: 1.5)
                        : isSelected
                            ? null
                            : hasAnnouncements
                                ? Border.all(
                                    color: AppTheme.primaryBlue
                                        .withOpacity(0.2))
                                : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppTheme.primaryBlue
                                  : isWeekend
                                      ? Colors.grey.shade400
                                      : null,
                        ),
                      ),
                      if (hasAnnouncements) ...[
                        const SizedBox(height: 2),
                        if (announcements.length == 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2),
                            child: Text(
                              announcements.first['title'] ?? '',
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelected
                                    ? Colors.white70
                                    : AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${announcements.length}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // ── DAY DIALOG ──
  void _showDayDialog(
      int day, List<Map<String, dynamic>> announcements) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              '$day $_monthName',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${announcements.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: announcements.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = announcements[index];
              final dateTime = a['dateTime'] != null
                  ? (a['dateTime'] as Timestamp).toDate()
                  : null;
              final needsTech = a['needsTechAssist'] == true;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.campaign,
                      color: AppTheme.primaryBlue, size: 20),
                ),
                title: Text(
                  a['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (dateTime != null)
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    if ((a['venueName'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              a['venueName'],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (needsTech) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.build_circle,
                                size: 10, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'Tech Required',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                       ViewAnnouncementScreen.show(context, a);
                  },
                    style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(
                        color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: const Text('View',
                      style: TextStyle(fontSize: 13)),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── SELECTED DAY LIST ──
  Widget _buildSelectedDayList() {
    final announcements =
        _announcementsByDay[_selectedDay!.day] ?? [];

    if (announcements.isEmpty) {
      // ✅ Padding instead of Expanded for empty state
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'No announcements on this day',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ shrinkWrap + NeverScrollableScrollPhysics so it
    // sizes to content inside SingleChildScrollView
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = announcements[index];
        final dateTime = a['dateTime'] != null
            ? (a['dateTime'] as Timestamp).toDate()
            : null;
        final needsTech = a['needsTechAssist'] == true;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.campaign,
                      color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (dateTime != null) ...[
                            const Icon(Icons.access_time,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if ((a['venueName'] ?? '').isNotEmpty) ...[
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a['venueName'],
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (needsTech) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.build_circle,
                                  size: 10, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                'Tech Required',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => ViewAnnouncementScreen.show(context, a),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(
                        color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: const Text('View',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _subtitleText {
    switch (widget.calendarType) {
      case CalendarType.unit:
        return 'Your scheduled announcements this month';
      case CalendarType.techAdmin:
        return 'Announcements you\'re involved in this month';
      case CalendarType.viewerAdmin:
        return 'All scheduled announcements this month';
    }
  }

  String get _selectedDayLabel {
    if (_selectedDay == null) return '';
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    final isToday = _selectedDay!.day == _today.day &&
        _selectedDay!.month == _today.month &&
        _selectedDay!.year == _today.year;
    return isToday
        ? 'Today — ${months[_selectedDay!.month - 1]} ${_selectedDay!.day}'
        : '${months[_selectedDay!.month - 1]} ${_selectedDay!.day}';
  }
}