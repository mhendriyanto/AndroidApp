import 'package:flutter/material.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../auth/sign_in_screen.dart';
import '../tabs/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _signOut(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SnapCleanScope.of(context).user;
    return Scaffold(
      body: AppPage(
        eyebrow: 'Account',
        title: 'Profile',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  Row(children: [
                    const ProfileBlock(),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(user.email, style: AppText.label)
                        ]))
                  ]),
                  const SizedBox(height: 16),
                  SecondaryButton(
                      label: 'Edit profile',
                      icon: Icons.edit_rounded,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()))),
                ],
              ),
            ),
            const SectionHeader(title: 'Account', action: ''),
            AppCard(
              child: Column(
                children: [
                  StaticSettingsRowButton(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal information',
                    subtitle: 'Name, email, and username',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen())),
                  ),
                  const Divider(height: 24),
                  StaticSettingsRowButton(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sign-in & security',
                    subtitle: 'Password and device access preview',
                    onTap: () => _showPreviewOnly(context),
                  ),
                  const Divider(height: 24),
                  StaticSettingsRowButton(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Cleanup reminders and alerts',
                    onTap: () => _showPreviewOnly(context),
                  ),
                  const Divider(height: 24),
                  StaticSettingsRowButton(
                    icon: Icons.shield_outlined,
                    title: 'Privacy',
                    subtitle: 'Photo access and local data rules',
                    onTap: () => _showPreviewOnly(context),
                  ),
                  const Divider(height: 24),
                  StaticSettingsRowButton(
                    icon: Icons.storage_rounded,
                    title: 'Data & storage',
                    subtitle: 'Recently deleted and cache controls',
                    onTap: () => _showPreviewOnly(context),
                  ),
                  const Divider(height: 24),
                  StaticSettingsRowButton(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & support',
                    subtitle: 'FAQ and contact preview',
                    onTap: () => _showPreviewOnly(context),
                  ),
                  const Divider(height: 24),
                  StaticSettingsRowButton(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    subtitle: 'End this session',
                    onTap: () => _signOut(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreviewOnly(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview only for now.')),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController? name;
  TextEditingController? email;
  TextEditingController? username;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (name != null) return;
    final user = SnapCleanScope.of(context).user;
    name = TextEditingController(text: user.name);
    email = TextEditingController(text: user.email);
    username = TextEditingController(text: user.username);
  }

  @override
  void dispose() {
    name?.dispose();
    email?.dispose();
    username?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Account',
        title: 'Edit profile',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            AppCard(
                child: Column(children: [
              const ProfileBlock(),
              const SizedBox(height: 16),
              SecondaryButton(
                  label: 'Change photo',
                  icon: Icons.camera_alt_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Photo picker preview only.'))))
            ])),
            const SectionHeader(title: 'Details', action: ''),
            AppCard(
                child: Column(children: [
              AppField(label: 'Name', value: '', controller: name),
              const SizedBox(height: 12),
              AppField(label: 'Email', value: '', controller: email),
              const SizedBox(height: 12),
              AppField(label: 'Username', value: '', controller: username)
            ])),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save changes',
              icon: Icons.check_rounded,
              onTap: () {
                SnapCleanScope.of(context).updateProfile(UserProfile(
                    name: name!.text.trim(),
                    email: email!.text.trim(),
                    username: username!.text.trim()));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class StaticSettingsRowButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const StaticSettingsRowButton(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              StaticSettingsRow(icon: icon, title: title, subtitle: subtitle),
        ),
      ),
    );
  }
}
