import 'package:flutter/material.dart';

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
                  label: 'Create account',
                  icon: Icons.person_add_alt_1_rounded,
                  onTap: () {
                    SnapCleanScope.of(context).createAccount(
                        username: username.text.trim(),
                        email: email.text.trim());
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const MainShell()));
                  },
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
}
