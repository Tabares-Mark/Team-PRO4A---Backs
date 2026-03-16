import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../app_theme.dart';
import '../../firebase_options.dart';

class ManageUnitsScreen extends StatefulWidget {
  const ManageUnitsScreen({super.key});

  @override
  State<ManageUnitsScreen> createState() => _ManageUnitsScreenState();
}

class _ManageUnitsScreenState extends State<ManageUnitsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('units')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _units = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      _showSnackbar('Error loading units: $e', isError: true);
    }
    setState(() => _isLoading = false);
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
                      'Manage Units',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_units.length} unit${_units.length != 1 ? 's' : ''} registered',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddUnitDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Unit'),
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

            // ── UNITS LIST ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _units.isEmpty
                      ? _buildEmptyState()
                      : _buildUnitsList(),
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
          Icon(Icons.business_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No units yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click "Add Unit" to create the first unit.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList() {
    return ListView.separated(
      itemCount: _units.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final unit = _units[index];
        final isActive = unit['isActive'] == true;

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

                // Unit Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Unit Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            unit['name'] ?? 'Unnamed Unit',
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unit['email'] ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${unit['personnelCount'] ?? 0} personnel',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _toggleUnitStatus(unit);
                    } else if (value == 'delete') {
                      _confirmDelete(unit);
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

  // ── ADD UNIT DIALOG ──
  void _showAddUnitDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String errorMessage = '';
    bool isSubmitting = false;
    bool obscureUnitPass = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.business, color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Text('Add New Unit'),
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
                        'Creates a login account and registers the unit in the system.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // Unit Name
                      _dialogLabel('Unit Name *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration: _inputDecoration(
                            'e.g. College of Engineering'),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _dialogLabel('Unit Email *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                            'e.g. engineering@school.edu'),
                      ),
                      const SizedBox(height: 16),

                      // Unit Password
                      _dialogLabel('Unit Password *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordController,
                        obscureText: obscureUnitPass,
                        decoration:
                            _inputDecoration('Min. 6 characters').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureUnitPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () => setDialogState(
                                () => obscureUnitPass = !obscureUnitPass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info note
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
                                'Role, status, and timestamps are set automatically.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error message
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
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(context),
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

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
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

                          final result = await _createUnit(
                            name: name,
                            email: email,
                            password: password,
                          );

                          if (!context.mounted) return;

                          if (result['success']) {
                            Navigator.pop(context);
                            _showSnackbar(
                                'Unit "$name" created successfully! ✅');
                            _loadUnits();
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
                  label:
                      Text(isSubmitting ? 'Creating...' : 'Create Unit'),
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

  // ── CREATE UNIT LOGIC ──
  Future<Map<String, dynamic>> _createUnit({
    required String name,
    required String email,
    required String password,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final currentAdmin = _auth.currentUser;
      if (currentAdmin == null) {
        return {'success': false, 'message': 'Not logged in.'};
      }

      // Create a secondary Firebase app instance so the new Auth account
      // is created there — leaving the Tech Admin session completely untouched.
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Step 1: Create the unit's Firebase Auth account in secondary instance
      final credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = credential.user!.uid;

      // Sign out of secondary instance immediately
      await secondaryAuth.signOut();

      // Step 2: Write to users collection (main app — admin still logged in)
      await _firestore.collection('users').doc(newUid).set({
        'name': name,
        'email': email,
        'role': 'unit',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Step 3: Write to units collection (doc ID = Auth UID)
      await _firestore.collection('units').doc(newUid).set({
        'name': name,
        'email': email,
        'isActive': true,
        'personnelCount': 0,
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
      // Always clean up the secondary app instance
      await secondaryApp?.delete();
    }
  }

  // ── TOGGLE ACTIVE STATUS ──
  Future<void> _toggleUnitStatus(Map<String, dynamic> unit) async {
    final newStatus = !(unit['isActive'] == true);
    try {
      await _firestore
          .collection('units')
          .doc(unit['id'])
          .update({'isActive': newStatus});
      _showSnackbar(
          'Unit marked as ${newStatus ? 'Active' : 'Inactive'}.');
      _loadUnits();
    } catch (e) {
      _showSnackbar('Error updating status: $e', isError: true);
    }
  }

  // ── CONFIRM DELETE ──
  void _confirmDelete(Map<String, dynamic> unit) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Unit'),
        content: Text(
          'Are you sure you want to delete "${unit['name']}"?\n\nThis removes the unit from Firestore. To also remove their login account, delete them manually in Firebase Console → Authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUnit(unit);
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

  Future<void> _deleteUnit(Map<String, dynamic> unit) async {
    try {
      await _firestore.collection('units').doc(unit['id']).delete();
      await _firestore.collection('users').doc(unit['id']).delete();
      _showSnackbar('Unit deleted successfully.');
      _loadUnits();
    } catch (e) {
      _showSnackbar('Error deleting unit: $e', isError: true);
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