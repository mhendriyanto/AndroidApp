import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: 'maya@example.com');
    password = TextEditingController(text: 'password123');
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
                  label: 'Sign in',
                  icon: Icons.lock_rounded,
                  onTap: () {
                    SnapCleanScope.of(context).signIn(email.text.trim());
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const MainShell()));
                  },
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
}
