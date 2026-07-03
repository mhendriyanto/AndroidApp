import 'package:flutter/material.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../user/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    return AppPage(
      eyebrow: 'Preferences',
      title: 'Settings',
      child: Column(
        children: [
          const SectionHeader(title: 'Account', action: ''),
          AccountCard(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          const SectionHeader(title: 'Cleanup', action: ''),
          AppCard(
            child: Column(
              children: [
                SettingsRow(
                    icon: Icons.delete_rounded,
                    title: 'Auto-delete expired',
                    subtitle: 'On app open',
                    value: controller.autoDeleteExpired,
                    onChanged: controller.toggleAutoDelete),
                const Divider(height: 24),
                SettingsRow(
                    icon: Icons.notifications_rounded,
                    title: 'Urgent alerts',
                    subtitle: 'Under 30 minutes',
                    value: controller.urgentAlerts,
                    onChanged: controller.toggleUrgentAlerts),
              ],
            ),
          ),
          SectionHeader(
              title: 'Defaults',
              action: 'Edit',
              onAction: () => _chooseDefault(context)),
          AppCard(
            child: Column(
              children: [
                SimpleRow(
                    label: 'Default timer',
                    value: controller.defaultTimer.label,
                    icon: controller.defaultTimer.icon),
                const Divider(height: 24),
                const SimpleRow(label: 'Import source', value: 'Photos picker'),
              ],
            ),
          ),
          const SectionHeader(title: 'Notifications', action: ''),
          AppCard(
              child: SettingsRow(
                  icon: Icons.notifications_rounded,
                  title: 'Expiry reminders',
                  subtitle: '30 minutes before',
                  value: controller.expiryReminders,
                  onChanged: controller.toggleExpiryReminders)),
          const SectionHeader(title: 'Storage', action: ''),
          const AppCard(
              child: StaticSettingsRow(
                  icon: Icons.storage_rounded,
                  title: 'Cache cleanup',
                  subtitle: 'Remove local copies')),
          const SectionHeader(title: 'Appearance', action: ''),
          const AppCard(
              child: StaticSettingsRow(
                  icon: Icons.contrast_rounded,
                  title: 'Theme',
                  subtitle: 'System default')),
        ],
      ),
    );
  }

  void _chooseDefault(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final timer in const [
              TimerPreset.thirtyMinutes,
              TimerPreset.oneHour,
              TimerPreset.tomorrow,
              TimerPreset.forever
            ])
              ListTile(
                leading: Icon(timer.icon, color: AppColors.brand),
                title: Text(timer.label,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(timer.subtitle),
                trailing: timer == controller.defaultTimer
                    ? const Icon(Icons.check_rounded, color: AppColors.mint)
                    : null,
                onTap: () {
                  controller.setDefaultTimer(timer);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  final VoidCallback onTap;
  const AccountCard({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final user = SnapCleanScope.of(context).user;
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
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
                ])),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class ProfileBlock extends StatelessWidget {
  const ProfileBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              colors: [Color(0xFFCFFAFE), Color(0xFFF0FDFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: const Icon(Icons.person_rounded,
          color: AppColors.brandDark, size: 44),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SettingsRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SettingIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.value),
          const SizedBox(height: 3),
          Text(subtitle, style: AppText.label)
        ])),
        GestureDetector(
            onTap: () => onChanged(!value),
            child: PrototypeSwitch(value: value)),
      ],
    );
  }
}

class StaticSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const StaticSettingsRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SettingIcon(icon: icon),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppText.value),
        const SizedBox(height: 3),
        Text(subtitle, style: AppText.label)
      ])),
      const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1))
    ]);
  }
}

class SettingIcon extends StatelessWidget {
  final IconData icon;
  const SettingIcon({required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: const Color(0xFFECFEFF),
            borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: AppColors.brandDark, size: 20));
  }
}

class PrototypeSwitch extends StatelessWidget {
  final bool value;
  const PrototypeSwitch({required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: value ? AppColors.brand : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(999)),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x2E0F172A),
                      blurRadius: 5,
                      offset: Offset(0, 2))
                ])),
      ),
    );
  }
}

class SimpleRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  const SimpleRow(
      {required this.label, required this.value, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.label),
        icon == null
            ? Text(value, style: AppText.value.copyWith(fontSize: 13))
            : BadgePill(label: value, icon: icon),
      ],
    );
  }
}
