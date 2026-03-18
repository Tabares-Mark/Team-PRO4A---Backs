import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';

// ── Shared helpers ──
Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'pending': return Colors.orange;
    case 'in review': return Colors.blue;
    case 'resolved': return Colors.green;
    default: return Colors.grey;
  }
}

IconData _statusIcon(String s) {
  switch (s.toLowerCase()) {
    case 'pending': return Icons.hourglass_empty;
    case 'in review': return Icons.search;
    case 'resolved': return Icons.check_circle;
    default: return Icons.help_outline;
  }
}

Color _categoryColor(String c) {
  if (c.startsWith('UI Bug')) return Colors.blue;
  if (c.startsWith('Wrong Data')) return Colors.orange;
  if (c.startsWith('Crash')) return Colors.red;
  if (c.startsWith('Feature')) return Colors.purple;
  if (c.startsWith('Performance')) return Colors.teal;
  return Colors.grey;
}

String _capitalizeStatus(String s) {
  if (s == 'in review') return 'In Review';
  if (s.isEmpty) return '';
  return s[0].toUpperCase() + s.substring(1);
}

String _statusDescription(String s) {
  switch (s) {
    case 'pending': return 'Not yet reviewed';
    case 'in review': return 'Currently being investigated';
    case 'resolved': return 'Issue has been fixed or addressed';
    default: return '';
  }
}

String _formatDate(DateTime dt) =>
    '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

// ══════════════════════════════════════════════
// ── BUG REPORTS MANAGEMENT SCREEN ──
// ══════════════════════════════════════════════
class BugReportsManagementScreen extends StatefulWidget {
  const BugReportsManagementScreen({super.key});

  @override
  State<BugReportsManagementScreen> createState() =>
      _BugReportsManagementScreenState();
}

class _BugReportsManagementScreenState
    extends State<BugReportsManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final _filterOptions = ['All', 'Pending', 'In Review', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snap = await _firestore
          .collection('bug_reports')
          .orderBy('submittedAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _reports = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _applyFilter(_selectedFilter);
      });
    } catch (e) {
      if (!mounted) return;
      _snackbar('Error loading reports: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String f) => setState(() {
        _selectedFilter = f;
        _filteredReports = f == 'All'
            ? List.from(_reports)
            : _reports
                .where((r) => (r['status'] ?? 'pending')
                    .toString()
                    .toLowerCase() ==
                    f.toLowerCase())
                .toList();
      });

  int _count(String s) => _reports
      .where((r) =>
          (r['status'] ?? 'pending').toString().toLowerCase() ==
          s.toLowerCase())
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFilterChips(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredReports.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bug Reports',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _isLoading
                    ? 'Loading...'
                    : '${_filteredReports.length} of ${_reports.length} report${_reports.length != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              if (!_isLoading) ...[
                _StatusBadge('Pending', _count('pending'), Colors.orange),
                const SizedBox(width: 8),
                _StatusBadge('In Review', _count('in review'), Colors.blue),
                const SizedBox(width: 8),
                _StatusBadge('Resolved', _count('resolved'), Colors.green),
                const SizedBox(width: 16),
              ],
              IconButton(
                  onPressed: _loadReports,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh'),
            ],
          ),
        ],
      );

  Widget _buildFilterChips() => Row(
        children: [
          const Text('Status:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey)),
          const SizedBox(width: 8),
          ..._filterOptions.map((f) {
            final isSelected = _selectedFilter == f;
            final color = f == 'All' ? AppTheme.primaryBlue : _statusColor(f);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _applyFilter(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (f != 'All') ...[
                        Icon(_statusIcon(f),
                            size: 11,
                            color: isSelected ? color : Colors.grey),
                        const SizedBox(width: 4),
                      ],
                      Text(f,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? color : Colors.grey,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All'
                  ? 'No bug reports yet'
                  : 'No $_selectedFilter reports',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'Bug reports submitted by units and viewer admins will appear here.'
                  : 'No reports with "$_selectedFilter" status found.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  // ✅ showDialog instead of Navigator.push
  Widget _buildList() => ListView.separated(
        itemCount: _filteredReports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _BugReportCard(
          report: _filteredReports[i],
          onView: () => showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => _BugReportDetailDialog(
              report: _filteredReports[i],
              onStatusUpdated: _loadReports,
            ),
          ),
        ),
      );

  void _snackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }
}

// ── Reusable small widgets ──
class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      );
}

class _InlineStatusBadge extends StatelessWidget {
  final String status;
  const _InlineStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 11, color: color),
          const SizedBox(width: 4),
          Text(_capitalizeStatus(status),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final Color color;
  const _CategoryChip(this.category, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(category,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      );
}

class _NotePreview extends StatelessWidget {
  final String note;
  const _NotePreview(this.note);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notes, size: 12, color: Colors.green),
            const SizedBox(width: 6),
            Expanded(
              child: Text(note,
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _DetailRow(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      );
}

class _BugReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onView;
  const _BugReportCard({required this.report, required this.onView});

  @override
  Widget build(BuildContext context) {
    final status = (report['status'] ?? 'pending').toString();
    final category = (report['category'] ?? 'Unknown').toString();
    final submittedAt = report['submittedAt'] != null
        ? (report['submittedAt'] as Timestamp).toDate()
        : null;
    final catColor = _categoryColor(category);
    final role = report['submittedByRole'] ?? '';
    final isUnit = role == 'unit';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22)),
              child: Icon(Icons.bug_report, color: catColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(report['title'] ?? 'Untitled',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    _InlineStatusBadge(status),
                  ]),
                  const SizedBox(height: 4),
                  _CategoryChip(category, catColor),
                  const SizedBox(height: 6),
                  Text(report['description'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(report['submittedByName'] ?? 'Unknown',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (submittedAt != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatDate(submittedAt).replaceAll(' at ', '  '),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                    if (role.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isUnit
                              ? Colors.green.withOpacity(0.1)
                              : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(isUnit ? 'Unit' : 'Viewer Admin',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isUnit ? Colors.green : Colors.purple)),
                      ),
                    ],
                  ]),
                  if ((report['resolutionNote'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _NotePreview(report['resolutionNote']),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined, size: 14),
              label: const Text('View', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── BUG REPORT DETAIL DIALOG ──
// ✅ Dialog instead of Scaffold — sidebar stays visible
// ══════════════════════════════════════════════
class _BugReportDetailDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback onStatusUpdated;
  const _BugReportDetailDialog(
      {required this.report, required this.onStatusUpdated});

  @override
  State<_BugReportDetailDialog> createState() =>
      _BugReportDetailDialogState();
}

class _BugReportDetailDialogState extends State<_BugReportDetailDialog> {
  final _firestore = FirebaseFirestore.instance;
  final _noteController = TextEditingController();
  late String _selectedStatus;
  late Map<String, dynamic> _report;
  bool _isSaving = false;
  String _errorMessage = '';
  final _statusOptions = ['pending', 'in review', 'resolved'];

  @override
  void initState() {
    super.initState();
    _report = Map.from(widget.report);
    _selectedStatus = (_report['status'] ?? 'pending').toString();
    _noteController.text = _report['resolutionNote'] ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveUpdate() async {
    if (!mounted) return;
    setState(() { _isSaving = true; _errorMessage = ''; });
    try {
      await _firestore.collection('bug_reports').doc(_report['id']).update({
        'status': _selectedStatus,
        'resolutionNote': _noteController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _report['status'] = _selectedStatus;
        _report['resolutionNote'] = _noteController.text.trim();
      });
      widget.onStatusUpdated();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Status updated to "${_capitalizeStatus(_selectedStatus)}" ✅'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error saving: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submittedAt = _report['submittedAt'] != null
        ? (_report['submittedAt'] as Timestamp).toDate()
        : null;
    final updatedAt = _report['updatedAt'] != null
        ? (_report['updatedAt'] as Timestamp).toDate()
        : null;
    final status = _report['status'] ?? 'pending';
    final category = (_report['category'] ?? 'Unknown').toString();
    final isUnit = _report['submittedByRole'] == 'unit';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HEADER + X ──
              Row(children: [
                const Expanded(
                  child: Text('Bug Report Detail',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  style: IconButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ]),
              const SizedBox(height: 16),

              // ── TITLE + STATUS ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(_report['title'] ?? 'Untitled',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  _InlineStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // ── DETAILS ──
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Category',
                child: _CategoryChip(category, _categoryColor(category)),
              ),
              const SizedBox(height: 12),

              _DetailRow(
                icon: Icons.person_outline,
                label: 'Submitted By',
                child: Row(children: [
                  Text(_report['submittedByName'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUnit
                          ? Colors.green.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isUnit ? 'Unit' : 'Viewer Admin',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUnit ? Colors.green : Colors.purple),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              if (submittedAt != null) ...[
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Submitted At',
                  child: Text(_formatDate(submittedAt),
                      style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 12),
              ],

              if (updatedAt != null) ...[
                _DetailRow(
                  icon: Icons.update,
                  label: 'Last Updated',
                  child: Text(_formatDate(updatedAt),
                      style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 12),
              ],

              _DetailRow(
                icon: Icons.description_outlined,
                label: 'Description',
                child: Text(_report['description'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // ── TECH ADMIN ACTIONS ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tech Admin Actions',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Add a note and update the status',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveUpdate,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 16),
                    label: Text(_isSaving ? 'Saving...' : 'Save',
                        style: const TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── NOTE + STATUS SIDE BY SIDE ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Note',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text(
                            'Findings, fix details, or follow-up actions',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Found a missing onTap handler. Fixed in v1.2.3.',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('Update the current status',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              items: _statusOptions
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Row(children: [
                                          Icon(_statusIcon(s),
                                              size: 14,
                                              color: _statusColor(s)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(_capitalizeStatus(s),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                        color: _statusColor(s))),
                                                Text(_statusDescription(s),
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ]),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMessage,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}