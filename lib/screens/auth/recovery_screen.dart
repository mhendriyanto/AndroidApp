import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class RecoveryScreen extends StatelessWidget {
  final String title;
  final String body;
  final String fieldLabel;
  final String button;
  final IconData icon;

  const RecoveryScreen.password({super.key})
      : title = 'Reset password',
        body = "Enter your email. We'll show a local-only success state.",
        fieldLabel = 'Email',
        button = 'Send reset link',
        icon = Icons.send_rounded;

  const RecoveryScreen.username({super.key})
      : title = 'Find username',
        body = 'Use your recovery email to preview account recovery.',
        fieldLabel = 'Recovery email',
        button = 'Find account',
        icon = Icons.search_rounded;

  @override
  Widget build(BuildContext context) {
    final field = TextEditingController(text: 'maya@example.com');
    return AuthShell(
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: AppText.title),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 30),
          AppCard(
            child: Column(
              children: [
                AppField(label: fieldLabel, value: '', controller: field),
                const SizedBox(height: 20),
                PrimaryButton(label: button, icon: icon, onTap: () => _showRecoveryResult(context)),
                const SizedBox(height: 18),
                LinkText('Back to sign in', onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecoveryResult(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recovery flow previewed locally.')));
  }
}
