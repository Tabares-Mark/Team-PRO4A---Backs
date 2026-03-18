import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otherCategoryController = TextEditingController();

  String? _selectedCategory;
  bool _isSubmitting = false;
  String _errorMessage = '';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'UI Bug', 'icon': Icons.brush_outlined, 'color': Colors.blue},
    {'label': 'Wrong Data Displayed', 'icon': Icons.data_object, 'color': Colors.orange},
    {'label': 'Crash / App Not Responding', 'icon': Icons.warning_amber_rounded, 'color': Colors.red},
    {'label': 'Feature Not Working', 'icon': Icons.extension_off_outlined, 'color': Colors.purple},
    {'label': 'Performance Issue', 'icon': Icons.speed, 'color': Colors.teal},
    {'label': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _errorMessage = '');

    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a title.');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a category.');
      return;
    }
    if (_selectedCategory == 'Other' &&
        _otherCategoryController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please describe the bug category.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please describe the bug you found.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Not logged in.';
          _isSubmitting = false;
        });
        return;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final submitterName = userDoc.data()?['name'] ?? 'Unknown';
      final submitterRole = userDoc.data()?['role'] ?? 'unknown';

      final finalCategory = _selectedCategory == 'Other'
          ? 'Other: ${_otherCategoryController.text.trim()}'
          : _selectedCategory!;

      // ✅ Capture values BEFORE clearing the form
      final capturedTitle = _titleController.text.trim();
      final capturedDescription = _descriptionController.text.trim();

      final docRef = await _firestore.collection('bug_reports').add({
        'title': capturedTitle,
        'category': finalCategory,
        'description': capturedDescription,
        'submittedBy': currentUser.uid,
        'submittedByName': submitterName,
        'submittedByRole': submitterRole,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;

      // ✅ Clear form BEFORE showing dialog
      _titleController.clear();
      _descriptionController.clear();
      _otherCategoryController.clear();
      setState(() {
        _selectedCategory = null;
        _isSubmitting = false;
        _errorMessage = '';
      });

      // ✅ Show dialog with captured values — not the now-empty controllers
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _BugReportSuccessDialog(
          title: capturedTitle,
          category: finalCategory,
          description: capturedDescription,
          submittedByName: submitterName,
          reportId: docRef.id,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error submitting report: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text('Bug Report',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Help us improve by reporting issues you encounter',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _fieldLabel('Bug Title *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        'e.g. Button not responding on login screen',
                        icon: Icons.title,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _fieldLabel('Category *'),
                    const SizedBox(height: 4),
                    const Text('Select the type of issue you encountered',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    _buildCategoryChips(),

                    if (_selectedCategory == 'Other') ...[
                      const SizedBox(height: 12),
                      _fieldLabel('Describe the category *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _otherCategoryController,
                        decoration: _inputDecoration(
                          'e.g. Notification issue',
                          icon: Icons.edit_outlined,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    _fieldLabel('Bug Description *'),
                    const SizedBox(height: 4),
                    const Text(
                        'Describe what happened, what you expected, and how to reproduce it',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. When I tap the "Create Announcement" button, nothing happens. '
                            'I expected a form to open. This happens every time I try.',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(16),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Screenshot attachment will be available in a future update.',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitReport,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting
                            ? 'Submitting...'
                            : 'Submit Bug Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['label'];
          final color = cat['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['label']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData,
                        size: 14, color: isSelected ? color : Colors.grey),
                    const SizedBox(width: 6),
                    Text(cat['label'],
                        style: TextStyle(
                          fontSize: 12,
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
        }).toList(),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));

  InputDecoration _inputDecoration(String hint, {required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ══════════════════════════════════════════════
// ── SUCCESS DIALOG ──
// ══════════════════════════════════════════════
class _BugReportSuccessDialog extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final String submittedByName;
  final String reportId;

  const _BugReportSuccessDialog({
    required this.title,
    required this.category,
    required this.description,
    required this.submittedByName,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Title + X
              Row(
                children: [
                  const Expanded(
                    child: Text('Report Submitted',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    style: IconButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Success banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 44),
                    const SizedBox(height: 10),
                    const Text(
                        'Thank you for helping us improve the app.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Report ID: $reportId',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Report Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _row(Icons.title, 'Title', title),
              const Divider(height: 20),
              _row(Icons.category_outlined, 'Category', category),
              const Divider(height: 20),
              _row(Icons.person_outline, 'Submitted By', submittedByName),
              const Divider(height: 20),
              _row(Icons.description_outlined, 'Description', description),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
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
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      );
}