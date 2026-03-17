import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../app_theme.dart';
import '../../firebase_options.dart';

class ManageViewerAdminsScreen extends StatefulWidget {
  const ManageViewerAdminsScreen({super.key});

  @override
  State<ManageViewerAdminsScreen> createState() =>
      _ManageViewerAdminsScreenState();
}

class _ManageViewerAdminsScreenState
    extends State<ManageViewerAdminsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _viewerAdmins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewerAdmins();
  }

  Future<void> _loadViewerAdmins() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'viewer_admin')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _viewerAdmins = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error loading viewer admins: $e', isError: true);
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
                      'Manage Viewer Admins',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_viewerAdmins.length} viewer admin${_viewerAdmins.length != 1 ? 's' : ''} registered',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddViewerAdminDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Viewer Admin'),
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

            // ── LIST ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _viewerAdmins.isEmpty
                      ? _buildEmptyState()
                      : _buildViewerAdminsList(),
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
          Icon(Icons.admin_panel_settings_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No viewer admins yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click "Add Viewer Admin" to register the first one.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerAdminsList() {
    return ListView.separated(
      itemCount: _viewerAdmins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final admin = _viewerAdmins[index];
        final isActive = admin['isActive'] == true;

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

                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            admin['name'] ?? 'Unnamed',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          // Read-only badge
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility,
                                    size: 11, color: Colors.purple),
                                SizedBox(width: 4),
                                Text(
                                  'Read-Only',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if ((admin['position'] ?? '').isNotEmpty)
                        Text(
                          admin['position'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        admin['email'] ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _toggleViewerAdminStatus(admin);
                    } else if (value == 'delete') {
                      _confirmDelete(admin);
                    }
                  },
                  itemBuilder: (_) => [
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
                          Text(isActive ? 'Set Inactive' : 'Set Active'),
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

  // ── ADD VIEWER ADMIN DIALOG ──
  void _showAddViewerAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final positionController = TextEditingController();
    String errorMessage = '';
    bool isSubmitting = false;
    bool obscurePass = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Text('Add Viewer Admin'),
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
                        'Creates a read-only account with the same view as Tech Admin but no edit permissions.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      _dialogLabel('Full Name *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration:
                            _inputDecoration('e.g. Maria Santos'),
                      ),
                      const SizedBox(height: 16),

                      _dialogLabel('Position / Role Title *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: positionController,
                        decoration:
                            _inputDecoration('e.g. School Principal'),
                      ),
                      const SizedBox(height: 16),

                      _dialogLabel('Email *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            _inputDecoration('e.g. principal@school.edu'),
                      ),
                      const SizedBox(height: 16),

                      _dialogLabel('Password *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePass,
                        decoration:
                            _inputDecoration('Min. 6 characters').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () => setDialogState(
                                () => obscurePass = !obscurePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info note
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.purple.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.visibility,
                                size: 14, color: Colors.purple),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Viewer Admins have read-only access. They cannot create, edit, or delete anything.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.purple),
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
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final password =
                              passwordController.text.trim();
                          final position =
                              positionController.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty ||
                              position.isEmpty) {
                            setDialogState(() => errorMessage =
                                'All fields are required.');
                            return;
                          }
                          if (password.length < 6) {
                            setDialogState(() => errorMessage =
                                'Password must be at least 6 characters.');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = '';
                          });

                          final result = await _createViewerAdmin(
                            name: name,
                            email: email,
                            password: password,
                            position: position,
                          );

                          if (!dialogContext.mounted) return;

                          if (result['success']) {
                            Navigator.pop(dialogContext);
                            _showSnackbar(
                                'Viewer Admin "$name" created successfully! ✅');
                            _loadViewerAdmins();
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
                      isSubmitting ? 'Creating...' : 'Create Viewer Admin'),
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

  // ── CREATE VIEWER ADMIN LOGIC ──
  Future<Map<String, dynamic>> _createViewerAdmin({
    required String name,
    required String email,
    required String password,
    required String position,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final currentAdmin = _auth.currentUser;
      if (currentAdmin == null) {
        return {'success': false, 'message': 'Not logged in.'};
      }

      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = credential.user!.uid;

      await secondaryAuth.signOut();

      await _firestore.collection('users').doc(newUid).set({
        'name': name,
        'email': email,
        'position': position,
        'role': 'viewer_admin',
        'isActive': true,
        'createdBy': currentAdmin.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters.';
          break;
        default:
          message = e.message ?? 'Authentication error.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      await secondaryApp?.delete();
    }
  }

  // ── TOGGLE ACTIVE STATUS ──
  Future<void> _toggleViewerAdminStatus(
      Map<String, dynamic> admin) async {
    final newStatus = !(admin['isActive'] == true);
    try {
      await _firestore
          .collection('users')
          .doc(admin['id'])
          .update({'isActive': newStatus});
      if (!mounted) return;
      _showSnackbar(
          '"${admin['name']}" marked as ${newStatus ? 'Active' : 'Inactive'}.');
      _loadViewerAdmins();
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error updating status: $e', isError: true);
    }
  }

  // ── CONFIRM DELETE ──
  void _confirmDelete(Map<String, dynamic> admin) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Viewer Admin'),
        content: Text(
          'Are you sure you want to delete "${admin['name']}"?\n\nThis removes them from Firestore. Their Firebase Auth account will remain but they will no longer be able to access the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteViewerAdmin(admin);
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

  Future<void> _deleteViewerAdmin(Map<String, dynamic> admin) async {
    try {
      await _firestore
          .collection('users')
          .doc(admin['id'])
          .delete();
      if (!mounted) return;
      _showSnackbar('"${admin['name']}" deleted successfully.');
      _loadViewerAdmins();
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error deleting viewer admin: $e', isError: true);
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