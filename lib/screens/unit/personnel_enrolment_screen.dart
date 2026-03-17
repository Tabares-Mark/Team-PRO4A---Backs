import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../app_theme.dart';
import '../../firebase_options.dart';

class PersonnelEnrolmentScreen extends StatefulWidget {
  final bool isReadOnly;
  const PersonnelEnrolmentScreen({super.key, this.isReadOnly = false});

  @override
  State<PersonnelEnrolmentScreen> createState() =>
      _PersonnelEnrolmentScreenState();
}

class _PersonnelEnrolmentScreenState
    extends State<PersonnelEnrolmentScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _personnel = [];
  bool _isLoading = true;
  String? _unitDocId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    if (!mounted) return;
    setState(() => _unitDocId = currentUser.uid);

    // ✅ Viewer Admin loads ALL personnel, Unit loads only their own
    if (widget.isReadOnly) {
      await _loadAllPersonnel();
    } else {
      await _loadPersonnel(currentUser.uid);
    }
  }

  // ── Used by Unit role ──
  Future<void> _loadPersonnel(String unitId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'personnel')
          .where('unitId', isEqualTo: unitId)
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _personnel = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error loading personnel: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Used by Viewer Admin role ──      ✅ NEW
  Future<void> _loadAllPersonnel() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'personnel')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _personnel = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error loading personnel: $e', isError: true);
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
                      'Personnel Enrolment',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_personnel.length} personnel enrolled',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                if (!widget.isReadOnly)
                  ElevatedButton.icon(
                    onPressed: () => _showAddPersonnelDialog(),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Personnel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

            // ── PERSONNEL LIST ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _personnel.isEmpty
                      ? _buildEmptyState()
                      : _buildPersonnelList(),
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
          Icon(Icons.people_outline,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No personnel enrolled yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isReadOnly
                ? 'No personnel have been enrolled yet.'
                : 'Click "Add Personnel" to enrol your first member.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonnelList() {
    return ListView.separated(
      itemCount: _personnel.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final person = _personnel[index];
        final isActive = person['isActive'] == true;

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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Personnel Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            person['name'] ?? 'Unnamed',
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
                      if ((person['position'] ?? '').isNotEmpty)
                        Text(
                          person['position'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        person['email'] ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                      if ((person['phone'] ?? '').isNotEmpty)
                        Text(
                          person['phone'],
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),

                if (!widget.isReadOnly)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'toggle') {
                        _togglePersonnelStatus(person);
                      } else if (value == 'delete') {
                        _confirmDelete(person);
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

  // ── ADD PERSONNEL DIALOG ──
  void _showAddPersonnelDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
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
                  Icon(Icons.person_add, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Add Personnel'),
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
                        'Creates a mobile login account and enrolls the personnel under your unit.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      _dialogLabel('Full Name *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration:
                            _inputDecoration('e.g. Juan dela Cruz'),
                      ),
                      const SizedBox(height: 16),
                      _dialogLabel('Position / Role Title *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: positionController,
                        decoration: _inputDecoration(
                            'e.g. Department Secretary'),
                      ),
                      const SizedBox(height: 16),
                      _dialogLabel('Email *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            _inputDecoration('e.g. juan@school.edu'),
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
                      const SizedBox(height: 16),
                      _dialogLabel('Phone Number'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration:
                            _inputDecoration('e.g. 09171234567'),
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
                                'Role, unit assignment, status, and timestamps are set automatically.',
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
                          final phone = phoneController.text.trim();
                          final position =
                              positionController.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty ||
                              position.isEmpty) {
                            setDialogState(() => errorMessage =
                                'Name, position, email and password are required.');
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

                          final result = await _createPersonnel(
                            name: name,
                            email: email,
                            password: password,
                            phone: phone,
                            position: position,
                          );

                          if (!dialogContext.mounted) return;

                          if (result['success']) {
                            Navigator.pop(dialogContext);
                            _showSnackbar(
                                '$name enrolled successfully! ✅');
                            if (_unitDocId != null) {
                              _loadPersonnel(_unitDocId!);
                            }
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
                      isSubmitting ? 'Enrolling...' : 'Enrol Personnel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

  // ── CREATE PERSONNEL LOGIC ──
  Future<Map<String, dynamic>> _createPersonnel({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String position,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final currentUnit = _auth.currentUser;
      if (currentUnit == null) {
        return {'success': false, 'message': 'Not logged in.'};
      }

      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);

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
        'phone': phone,
        'position': position,
        'role': 'personnel',
        'unitId': currentUnit.uid,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('units')
          .doc(currentUnit.uid)
          .update({
        'personnelCount': FieldValue.increment(1),
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
  Future<void> _togglePersonnelStatus(
      Map<String, dynamic> person) async {
    final newStatus = !(person['isActive'] == true);
    try {
      await _firestore
          .collection('users')
          .doc(person['id'])
          .update({'isActive': newStatus});
      if (!mounted) return;
      _showSnackbar(
          '${person['name']} marked as ${newStatus ? 'Active' : 'Inactive'}.');
      if (_unitDocId != null) _loadPersonnel(_unitDocId!);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error updating status: $e', isError: true);
    }
  }

  // ── CONFIRM DELETE ──
  void _confirmDelete(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Remove Personnel'),
        content: Text(
          'Are you sure you want to remove "${person['name']}"?\n\nThis removes them from Firestore and decrements your unit\'s personnel count. Their login account remains in Firebase Auth.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deletePersonnel(person);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePersonnel(Map<String, dynamic> person) async {
    try {
      await _firestore
          .collection('users')
          .doc(person['id'])
          .delete();

      if (_unitDocId != null) {
        await _firestore
            .collection('units')
            .doc(_unitDocId!)
            .update({
          'personnelCount': FieldValue.increment(-1),
        });
      }

      if (!mounted) return;
      _showSnackbar('${person['name']} removed successfully.');
      if (_unitDocId != null) _loadPersonnel(_unitDocId!);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error removing personnel: $e', isError: true);
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