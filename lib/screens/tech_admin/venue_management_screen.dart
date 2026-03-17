import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';

class VenueManagementScreen extends StatefulWidget {
  final bool isReadOnly;                                             // ✅ ADDED
  const VenueManagementScreen({super.key, this.isReadOnly = false}); // ✅ ADDED

  @override
  State<VenueManagementScreen> createState() =>
      _VenueManagementScreenState();
}

class _VenueManagementScreenState extends State<VenueManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('venues')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _venues = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error loading venues: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false); // ✅ finally block
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
                      'Venue Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_venues.length} venue${_venues.length != 1 ? 's' : ''} registered',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // ✅ hidden when read-only
                if (!widget.isReadOnly)
                  ElevatedButton.icon(
                    onPressed: () => _showAddVenueDialog(),
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Add Venue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ── VENUES LIST ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _venues.isEmpty
                      ? _buildEmptyState()
                      : _buildVenuesList(),
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
          Icon(Icons.location_off_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No venues yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            // ✅ context-aware empty message
            widget.isReadOnly
                ? 'No venues have been registered yet.'
                : 'Click "Add Venue" to register the first venue.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVenuesList() {
    return ListView.separated(
      itemCount: _venues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final venue = _venues[index];
        final isActive = venue['isActive'] == true;
        final requiresTech = venue['requiresTechAssist'] == true;

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

                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: requiresTech
                        ? Colors.orange.withOpacity(0.1)
                        : AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: requiresTech
                        ? Colors.orange
                        : AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Venue Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            venue['name'] ?? 'Unnamed Venue',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Active badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          // Tech Required badge
                          if (requiresTech) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.build_circle,
                                      size: 11, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tech Required',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        requiresTech
                            ? 'Auto-ticks tech assistance in announcements'
                            : 'No automatic tech assistance',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // ✅ Actions hidden when read-only
                if (!widget.isReadOnly)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditVenueDialog(venue);
                      } else if (value == 'toggle') {
                        _toggleVenueStatus(venue);
                      } else if (value == 'delete') {
                        _confirmDelete(venue);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.block
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: isActive
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(isActive
                                ? 'Set Inactive'
                                : 'Set Active'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── ADD VENUE DIALOG ──
  void _showAddVenueDialog() {
    final nameController = TextEditingController();
    bool requiresTech = false;
    String errorMessage = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,          // ✅ removed useRootNavigator
      builder: (dialogContext) {          // ✅ dialogContext
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_location_alt,
                      color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Text('Add New Venue'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Registers a venue that can be selected when creating announcements.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      _dialogLabel('Venue Name *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration:
                            _inputDecoration('e.g. Main Auditorium'),
                      ),
                      const SizedBox(height: 20),

                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setDialogState(
                            () => requiresTech = !requiresTech),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: requiresTech
                                ? Colors.orange.withOpacity(0.07)
                                : Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: requiresTech
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: requiresTech,
                                onChanged: (val) => setDialogState(
                                    () => requiresTech = val ?? false),
                                activeColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Requires Tech Assistance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      requiresTech
                                          ? 'Will auto-tick the tech assistance box in announcements'
                                          : 'Tech assistance can still be requested manually',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: requiresTech
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Status and timestamps are set automatically.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext), // ✅ dialogContext
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            setDialogState(() => errorMessage =
                                'Please enter a venue name.');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = '';
                          });

                          final result = await _addVenue(
                            name: name,
                            requiresTechAssist: requiresTech,
                          );

                          if (!dialogContext.mounted) return; // ✅ dialogContext

                          if (result['success']) {
                            Navigator.pop(dialogContext);     // ✅ dialogContext
                            _showSnackbar(
                                'Venue "$name" added successfully! ✅');
                            _loadVenues();
                          } else {
                            setDialogState(() {
                              errorMessage = result['message'] ??
                                  'An error occurred.';
                              isSubmitting = false;
                            });
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(isSubmitting ? 'Adding...' : 'Add Venue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── EDIT VENUE DIALOG ──
  void _showEditVenueDialog(Map<String, dynamic> venue) {
    final nameController =
        TextEditingController(text: venue['name'] ?? '');
    bool requiresTech = venue['requiresTechAssist'] == true;
    String errorMessage = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,          // ✅ removed useRootNavigator
      builder: (dialogContext) {          // ✅ dialogContext
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_location_alt,
                      color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Text('Edit Venue'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _dialogLabel('Venue Name *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration:
                            _inputDecoration('e.g. Main Auditorium'),
                      ),
                      const SizedBox(height: 20),

                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setDialogState(
                            () => requiresTech = !requiresTech),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: requiresTech
                                ? Colors.orange.withOpacity(0.07)
                                : Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: requiresTech
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: requiresTech,
                                onChanged: (val) => setDialogState(
                                    () => requiresTech = val ?? false),
                                activeColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Requires Tech Assistance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      requiresTech
                                          ? 'Will auto-tick the tech assistance box in announcements'
                                          : 'Tech assistance can still be requested manually',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: requiresTech
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext), // ✅ dialogContext
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            setDialogState(() => errorMessage =
                                'Please enter a venue name.');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = '';
                          });

                          final result = await _updateVenue(
                            venueId: venue['id'],
                            name: name,
                            requiresTechAssist: requiresTech,
                          );

                          if (!dialogContext.mounted) return; // ✅ dialogContext

                          if (result['success']) {
                            Navigator.pop(dialogContext);     // ✅ dialogContext
                            _showSnackbar(
                                'Venue "$name" updated successfully! ✅');
                            _loadVenues();
                          } else {
                            setDialogState(() {
                              errorMessage = result['message'] ??
                                  'An error occurred.';
                              isSubmitting = false;
                            });
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                      isSubmitting ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── ADD VENUE LOGIC ──
  Future<Map<String, dynamic>> _addVenue({
    required String name,
    required bool requiresTechAssist,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'Not logged in.'};
      }

      await _firestore.collection('venues').add({
        'name': name,
        'requiresTechAssist': requiresTechAssist,
        'isActive': true,
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── UPDATE VENUE LOGIC ──
  Future<Map<String, dynamic>> _updateVenue({
    required String venueId,
    required String name,
    required bool requiresTechAssist,
  }) async {
    try {
      await _firestore.collection('venues').doc(venueId).update({
        'name': name,
        'requiresTechAssist': requiresTechAssist,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── TOGGLE ACTIVE STATUS ──
  Future<void> _toggleVenueStatus(Map<String, dynamic> venue) async {
    final newStatus = !(venue['isActive'] == true);
    try {
      await _firestore
          .collection('venues')
          .doc(venue['id'])
          .update({'isActive': newStatus});
      if (!mounted) return;
      _showSnackbar(
          'Venue marked as ${newStatus ? 'Active' : 'Inactive'}.');
      _loadVenues();
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error updating status: $e', isError: true);
    }
  }

  // ── CONFIRM DELETE ──
  void _confirmDelete(Map<String, dynamic> venue) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Venue'),
        content: Text(
          'Are you sure you want to delete "${venue['name']}"?\n\nThis cannot be undone. Existing announcements using this venue will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // ✅ dialogContext
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);                // ✅ dialogContext
              await _deleteVenue(venue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVenue(Map<String, dynamic> venue) async {
    try {
      await _firestore
          .collection('venues')
          .doc(venue['id'])
          .delete();
      if (!mounted) return;
      _showSnackbar('"${venue['name']}" deleted successfully.');
      _loadVenues();
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error deleting venue: $e', isError: true);
    }
  }

  // ── HELPERS ──
  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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