import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState
    extends State<AccountInformationScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _changePassword = false;

  // Read-only info
  int _personnelCount = 0;
  bool _isActive = true;

  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountInfo() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Fetch from units collection for personnelCount + isActive
      final unitDoc = await _firestore
          .collection('units')
          .doc(currentUser.uid)
          .get();

      // Fetch from users collection for name + email
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      final unitData = unitDoc.data() ?? {};
      final userData = userDoc.data() ?? {};

      setState(() {
        _nameController.text = unitData['name'] ?? userData['name'] ?? '';
        _emailController.text = unitData['email'] ?? userData['email'] ?? '';
        _personnelCount = unitData['personnelCount'] ?? 0;
        _isActive = unitData['isActive'] == true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error loading account info: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // ── Validation ──
    if (name.isEmpty || email.isEmpty) {
      setState(() => _errorMessage = 'Name and email are required.');
      return;
    }

    if (_changePassword) {
      if (_currentPasswordController.text.isEmpty) {
        setState(() => _errorMessage = 'Please enter your current password.');
        return;
      }
      if (_newPasswordController.text.isEmpty) {
        setState(() => _errorMessage = 'Please enter a new password.');
        return;
      }
      if (_newPasswordController.text.length < 6) {
        setState(() =>
            _errorMessage = 'New password must be at least 6 characters.');
        return;
      }
      if (_newPasswordController.text !=
          _confirmPasswordController.text) {
        setState(() => _errorMessage = 'New passwords do not match.');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() => _errorMessage = 'Not logged in.');
        return;
      }

      // ── Re-authenticate if changing password or email ──
      if (_changePassword ||
          email != currentUser.email) {
        if (_currentPasswordController.text.isEmpty) {
          setState(() {
            _errorMessage =
                'Please enter your current password to update email or password.';
            _isSaving = false;
            // ── auto-expand password section ──
            _changePassword = true;
          });
          return;
        }

        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: _currentPasswordController.text,
        );

        await currentUser.reauthenticateWithCredential(credential);
      }

      // ── Update email in Firebase Auth ──
      if (email != currentUser.email) {
        await currentUser.verifyBeforeUpdateEmail(email);
      }

      // ── Update password in Firebase Auth ──
      if (_changePassword &&
          _newPasswordController.text.isNotEmpty) {
        await currentUser.updatePassword(_newPasswordController.text);
      }

      // ── Update name + email in users collection ──
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'name': name,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ── Update name + email in units collection ──
      await _firestore
          .collection('units')
          .doc(currentUser.uid)
          .update({
        'name': name,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ── Clear password fields on success ──
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _successMessage = email != currentUser.email
            ? 'Changes saved! A verification email has been sent to $email. Please verify it to complete the email change.'
            : 'Account information updated successfully! ✅';
        _changePassword = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Current password is incorrect.';
          break;
        case 'email-already-in-use':
          message = 'This email is already used by another account.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'requires-recent-login':
          message =
              'Please enter your current password to make this change.';
          break;
        default:
          message = e.message ?? 'Authentication error.';
      }
      setState(() => _errorMessage = message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error saving changes: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── HEADER ──
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'View and update your account details',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // ── READ-ONLY INFO CARDS ──
                  Row(
                    children: [
                      _buildInfoCard(
                        icon: Icons.people,
                        label: 'Personnel Count',
                        value: '$_personnelCount',
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoCard(
                        icon: _isActive
                            ? Icons.check_circle
                            : Icons.cancel,
                        label: 'Account Status',
                        value: _isActive ? 'Active' : 'Inactive',
                        color: _isActive ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── EDITABLE FIELDS CARD ──
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            'Edit Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Changes to email require your current password for verification.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          // Name
                          _fieldLabel('Unit Name'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                                'Enter unit name',
                                icon: Icons.business),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          _fieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                                'Enter email address',
                                icon: Icons.email_outlined),
                          ),
                          const SizedBox(height: 24),

                          // ── CHANGE PASSWORD TOGGLE ──
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(
                                () => _changePassword = !_changePassword),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _changePassword
                                    ? AppTheme.primaryBlue.withOpacity(0.07)
                                    : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _changePassword
                                      ? AppTheme.primaryBlue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                    color: _changePassword
                                        ? AppTheme.primaryBlue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _changePassword
                                          ? 'Cancel password change'
                                          : 'Change password',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _changePassword
                                            ? AppTheme.primaryBlue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _changePassword
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: _changePassword
                                        ? AppTheme.primaryBlue
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── PASSWORD FIELDS (shown when toggled) ──
                          if (_changePassword) ...[
                            const SizedBox(height: 20),

                            _fieldLabel('Current Password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrentPass,
                              decoration: _inputDecoration(
                                'Enter current password',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrentPass
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureCurrentPass =
                                          !_obscureCurrentPass),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _fieldLabel('New Password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: _obscureNewPass,
                              decoration: _inputDecoration(
                                'Min. 6 characters',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPass
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureNewPass =
                                          !_obscureNewPass),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _fieldLabel('Confirm New Password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPass,
                              decoration: _inputDecoration(
                                'Re-enter new password',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPass
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirmPass =
                                          !_obscureConfirmPass),
                                ),
                              ),
                            ),
                          ],

                          // ── current password required note
                          // (shown when email changed but password toggle is off)
                          if (!_changePassword) ...[
                            const SizedBox(height: 20),
                            _fieldLabel('Current Password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrentPass,
                              decoration: _inputDecoration(
                                'Required only if changing email',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrentPass
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureCurrentPass =
                                          !_obscureCurrentPass),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── ERROR MESSAGE ──
                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                          color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── SUCCESS MESSAGE ──
                          if (_successMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _successMessage,
                                      style: const TextStyle(
                                          color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── SAVE BUTTON ──
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveChanges,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isSaving ? 'Saving...' : 'Save Changes',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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

  // ── READ-ONLY INFO CARD ──
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  InputDecoration _inputDecoration(String hint,
      {required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, size: 18, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}