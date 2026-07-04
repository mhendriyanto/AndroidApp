import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/snap_item.dart';
import '../../services/auth_repository.dart';
import '../../services/firestore_repository.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/logo.dart';
import '../main_shell.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final authRepository = AuthRepository();
  final firestoreRepository = FirestoreRepository();
  bool isLoading = false;

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandHeader(),
          const SizedBox(height: 28),
          const Text('Sign up',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          const Text('Start cleaning screenshot clutter.',
              style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 30),
          AppCard(
            child: Column(
              children: [
                AppField(label: 'Username', value: '', controller: username),
                const SizedBox(height: 12),
                AppField(label: 'Email', value: '', controller: email),
                const SizedBox(height: 12),
                AppField(
                    label: 'Password',
                    value: '',
                    controller: password,
                    obscure: true),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: isLoading ? 'Creating account...' : 'Create account',
                  icon: Icons.person_add_alt_1_rounded,
                  showIcon: false,
                  onTap: isLoading ? () {} : _createAccount,
                ),
                const SizedBox(height: 18),
                LinkText('Already have one? Sign in',
                    onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccount() async {
    final trimmedUsername = username.text.trim();
    final trimmedEmail = email.text.trim();
    final enteredPassword = password.text;
    if (trimmedUsername.isEmpty ||
        trimmedEmail.isEmpty ||
        enteredPassword.isEmpty) {
      _showMessage('Enter a username, email, and password.');
      return;
    }
    if (enteredPassword.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final existingEmail =
          await firestoreRepository.emailForUsername(trimmedUsername);
      if (existingEmail != null) {
        if (!mounted) return;
        _showMessage('That username is already taken.');
        return;
      }
      final credential = await authRepository.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: enteredPassword,
      );
      await authRepository.updateDisplayName(trimmedUsername);
      final profile = UserProfile(
        name: trimmedUsername,
        email: trimmedEmail,
        username: trimmedUsername,
      );
      await firestoreRepository.upsertUserProfile(
        profile,
        uid: credential.user?.uid,
      );
      await firestoreRepository.reserveUsername(
        username: trimmedUsername,
        email: trimmedEmail,
        uid: credential.user?.uid,
      );
      if (!mounted) return;
      SnapCleanScope.of(context).createAccount(
        username: trimmedUsername,
        email: trimmedEmail,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to create the account right now.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'An account already exists for this email.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Use a stronger password.',
      'network-request-failed' => 'Check your connection and try again.',
      _ => error.message ?? 'Unable to create the account right now.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
