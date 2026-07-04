import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class RecoveryScreen extends StatefulWidget {
  final String title;
  final String body;
  final String fieldLabel;
  final String button;
  final IconData icon;
  final bool sendsPasswordReset;

  const RecoveryScreen.password({super.key})
      : title = 'Reset password',
        body = 'Enter your email and Firebase will send a reset link.',
        fieldLabel = 'Email',
        button = 'Send reset link',
        icon = Icons.send_rounded,
        sendsPasswordReset = true;

  const RecoveryScreen.username({super.key})
      : title = 'Find username',
        body = 'Use your recovery email to preview account recovery.',
        fieldLabel = 'Recovery email',
        button = 'Find account',
        icon = Icons.search_rounded,
        sendsPasswordReset = false;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final field = TextEditingController();
  final authRepository = AuthRepository();
  bool isLoading = false;

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        children: [
          Text(widget.title, textAlign: TextAlign.center, style: AppText.title),
          const SizedBox(height: 12),
          Text(widget.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 30),
          AppCard(
            child: Column(
              children: [
                AppField(
                    label: widget.fieldLabel, value: '', controller: field),
                const SizedBox(height: 20),
                PrimaryButton(
                    label: isLoading ? 'Sending...' : widget.button,
                    icon: widget.icon,
                    onTap: isLoading ? () {} : _showRecoveryResult),
                const SizedBox(height: 18),
                LinkText('Back to sign in',
                    onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecoveryResult() async {
    final trimmedEmail = field.text.trim();
    if (trimmedEmail.isEmpty) {
      _showMessage('Enter your email address.');
      return;
    }
    if (!widget.sendsPasswordReset) {
      _showMessage('Username recovery still needs a profile lookup screen.');
      return;
    }

    setState(() => isLoading = true);
    try {
      await authRepository.sendPasswordResetEmail(trimmedEmail);
      if (!mounted) return;
      _showMessage('Password reset link sent.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message ?? 'Unable to send reset link right now.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
