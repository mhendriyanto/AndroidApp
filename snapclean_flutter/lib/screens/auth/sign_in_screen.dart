import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_repository.dart';
import '../../services/firestore_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/logo.dart';
import '../main_shell.dart';
import 'recovery_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final TextEditingController email;
  late final TextEditingController password;
  final authRepository = AuthRepository();
  final firestoreRepository = FirestoreRepository();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    email = TextEditingController();
    password = TextEditingController();
  }

  @override
  void dispose() {
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
          const SizedBox(height: 30),
          AppCard(
            child: Column(
              children: [
                AppField(label: 'Username/Email', value: '', controller: email),
                const SizedBox(height: 12),
                AppField(
                    label: 'Password',
                    value: '',
                    controller: password,
                    obscure: true),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: isLoading ? 'Signing in...' : 'Sign in',
                  icon: Icons.lock_rounded,
                  onTap: isLoading ? () {} : _signIn,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LinkText('Forgot password?',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RecoveryScreen.password()))),
                    const SizedBox(width: 28),
                    LinkText('Forgot username?',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RecoveryScreen.username()))),
                  ],
                ),
                const SizedBox(height: 18),
                LinkText('Create account',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen()))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    final account = email.text.trim();
    final enteredPassword = password.text;
    if (account.isEmpty || enteredPassword.isEmpty) {
      _showMessage('Enter your username or email and password.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final resolvedEmail = await _resolveEmail(account);
      final credential = await authRepository.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: enteredPassword,
      );
      if (!mounted) return;
      final profile = await firestoreRepository.getUserProfile(
        uid: credential.user?.uid,
      );
      if (!mounted) return;
      if (profile == null) {
        final fallbackUsername = credential.user?.displayName ?? resolvedEmail;
        await _backfillUsernameLookup(
          username: fallbackUsername,
          email: resolvedEmail,
          uid: credential.user?.uid,
        );
        SnapCleanScope.of(context).createAccount(
          username: fallbackUsername,
          email: resolvedEmail,
        );
      } else {
        await _backfillUsernameLookup(
          username: profile.username,
          email: profile.email,
          uid: credential.user?.uid,
        );
        SnapCleanScope.of(context).updateProfile(profile);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to sign in right now.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String> _resolveEmail(String account) async {
    if (account.contains('@')) return account;
    final resolvedEmail = await firestoreRepository.emailForUsername(account);
    if (resolvedEmail == null || resolvedEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account was found for this username.',
      );
    }
    return resolvedEmail;
  }

  Future<void> _backfillUsernameLookup({
    required String username,
    required String email,
    required String? uid,
  }) async {
    if (uid == null || username.contains('@')) return;
    try {
      await firestoreRepository.reserveUsername(
        username: username,
        email: email,
        uid: uid,
      );
    } catch (_) {
      // A failed backfill should not block a successful email/password login.
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account was found for that username or email.',
      'wrong-password' || 'invalid-credential' => 'Email or password is wrong.',
      'network-request-failed' => 'Check your connection and try again.',
      _ => error.message ?? 'Unable to sign in right now.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
