import 'dart:io';

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
          AccountCard(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          const SettingsGroupLabel('Cleanup'),
          SettingsGroup(children: [
            SettingsLinkRow(
                icon: Icons.delete_sweep_rounded,
                label: 'Cleanup behavior',
                value: controller.cleanupBehavior.label,
                onTap: () => _open(context, const CleanupBehaviorScreen())),
            SettingsRow(
                icon: Icons.priority_high_rounded,
                title: 'Urgent alerts',
                subtitle: 'Highlight screenshots under 30 minutes',
                value: controller.urgentAlerts,
                onChanged: controller.toggleUrgentAlerts,
                onInfoTap: () => _open(context, const UrgentAlertsScreen())),
          ]),
          const SettingsGroupLabel('Defaults'),
          SettingsGroup(children: [
            SettingsLinkRow(
                icon: controller.defaultTimer.icon,
                label: 'Default timer',
                value: controller.defaultTimer.label,
                onTap: () => _open(context, const DefaultTimerScreen())),
            SettingsLinkRow(
                icon: Icons.folder_copy_rounded,
                label: 'Default import location',
                value: controller.defaultSaveLocation.label,
                onTap: () => _open(context, const SaveLocationScreen())),
            SettingsLinkRow(
                icon: Icons.photo_library_rounded,
                label: 'Import source',
                value: 'Photos picker',
                onTap: () => _open(context, const ImportSourceScreen())),
          ]),
          const SettingsGroupLabel('Notifications'),
          SettingsGroup(children: [
            SettingsRow(
                icon: Icons.notifications_none_rounded,
                title: 'Expiry reminders',
                subtitle:
                    'Notify ${_durationLabel(controller.notificationLeadTime)} before cleanup',
                value: controller.expiryReminders,
                onChanged: controller.toggleExpiryReminders,
                onInfoTap: () => _open(context, const ExpiryRemindersScreen())),
            SettingsLinkRow(
                icon: Icons.schedule_send_rounded,
                label: 'Reminder lead time',
                value: _durationLabel(controller.notificationLeadTime),
                onTap: () => _open(context, const ReminderLeadTimeScreen())),
          ]),
          const SettingsGroupLabel('Privacy & Permissions'),
          SettingsGroup(children: [
            StaticSettingsRow(
                icon: Icons.photo_size_select_actual_rounded,
                title: 'Photo access',
                subtitle: 'Picker access for selected screenshots',
                onTap: () => _open(context, const PhotoAccessScreen())),
            StaticSettingsRow(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle: 'Manage cleanup and reminder alerts',
                onTap: () => _open(context, const NotificationAccessScreen())),
            StaticSettingsRow(
                icon: Icons.lock_outline_rounded,
                title: 'Local storage',
                subtitle: 'Local copies stay on this device',
                onTap: () => _open(context, const LocalStorageScreen())),
          ]),
          const SettingsGroupLabel('Storage'),
          SettingsGroup(children: [
            StaticSettingsRow(
                icon: Icons.storage_rounded,
                title: 'Cache cleanup',
                subtitle: 'Remove temporary local copies',
                onTap: () => _open(context, const CacheCleanupScreen())),
            StaticSettingsRow(
                icon: Icons.restore_from_trash_rounded,
                title: 'Recently deleted',
                subtitle:
                    '${controller.deletedSnaps.length} items ready for review',
                onTap: () => _open(context, const RecentlyDeletedScreen())),
          ]),
          const SettingsGroupLabel('Appearance'),
          SettingsGroup(children: [
            StaticSettingsRow(
                icon: Icons.contrast_rounded,
                title: 'Theme',
                subtitle: controller.appBackground.label,
                onTap: () => _open(context, const ThemeSettingsScreen())),
          ]),
          const SettingsGroupLabel('About'),
          SettingsGroup(children: [
            StaticSettingsRow(
                icon: Icons.info_outline_rounded,
                title: 'About SnapClean',
                subtitle: 'Version 1.0',
                onTap: () => _open(context, const AboutSnapCleanScreen())),
            StaticSettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                subtitle: 'Data and screenshot handling',
                onTap: () => _open(context, const PrivacyPolicyScreen())),
          ]),
        ],
      ),
    );
  }

  static String _durationLabel(Duration duration) {
    if (duration.inMinutes < 60) return '${duration.inMinutes} min';
    return duration.inHours == 1 ? '1 hr' : '${duration.inHours} hr';
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class CleanupBehaviorScreen extends StatelessWidget {
  const CleanupBehaviorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    return SettingsDetailPage(
      title: 'Cleanup',
      icon: Icons.delete_sweep_rounded,
      summary: 'Choose what happens when screenshot timers expire.',
      children: [
        SettingsGroup(children: [
          for (final behavior in CleanupBehavior.values)
            OptionSettingsRow(
              icon: Icons.delete_sweep_rounded,
              title: behavior.label,
              subtitle: behavior.description,
              selected: behavior == controller.cleanupBehavior,
              onTap: () => controller.setCleanupBehavior(behavior),
            ),
        ]),
        const SettingsNoteCard(
            icon: Icons.verified_user_rounded,
            title: 'Clear user control',
            subtitle:
                'Cleanup choices are visible and easy to change before publishing.'),
      ],
    );
  }
}

class UrgentAlertsScreen extends StatelessWidget {
  const UrgentAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    return SettingsDetailPage(
      title: 'Urgent Alerts',
      icon: Icons.priority_high_rounded,
      summary: 'Highlight screenshots that need attention soon.',
      children: [
        SettingsGroup(children: [
          SettingsRow(
              icon: Icons.priority_high_rounded,
              title: 'Highlight urgent screenshots',
              subtitle: 'Use stronger styling under 30 minutes',
              value: controller.urgentAlerts,
              onChanged: controller.toggleUrgentAlerts),
        ]),
        const SettingsNoteCard(
            icon: Icons.timer_rounded,
            title: 'Urgent window',
            subtitle:
                'Screenshots under 30 minutes are presented with warning states.'),
      ],
    );
  }
}

class DefaultTimerScreen extends StatelessWidget {
  const DefaultTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    const timers = [
      TimerPreset.tenMinutes,
      TimerPreset.thirtyMinutes,
      TimerPreset.oneHour,
      TimerPreset.tomorrow,
      TimerPreset.forever,
    ];
    return SettingsDetailPage(
      title: 'Default Timer',
      icon: controller.defaultTimer.icon,
      summary: 'Set the timer selected first during import.',
      children: [
        SettingsGroup(children: [
          for (final timer in timers)
            OptionSettingsRow(
              icon: timer.icon,
              title: timer.label,
              subtitle: timer.subtitle,
              selected: timer == controller.defaultTimer,
              onTap: () => controller.setDefaultTimer(timer),
            ),
        ]),
      ],
    );
  }
}

class SaveLocationScreen extends StatelessWidget {
  const SaveLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    return SettingsDetailPage(
      title: 'Import Location',
      icon: Icons.folder_copy_rounded,
      summary: 'Choose where new imports should go by default.',
      children: [
        SettingsGroup(children: [
          for (final location in DefaultSaveLocation.values)
            OptionSettingsRow(
              icon: Icons.folder_copy_rounded,
              title: location.label,
              subtitle: location.description,
              selected: location == controller.defaultSaveLocation,
              onTap: () => controller.setDefaultSaveLocation(location),
            ),
        ]),
      ],
    );
  }
}

class ImportSourceScreen extends StatelessWidget {
  const ImportSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailPage(
      title: 'Import Source',
      icon: Icons.photo_library_rounded,
      summary: 'Manage the places screenshots can be imported from.',
      children: [
        SettingsGroup(children: [
          StaticSettingsRow(
              icon: Icons.photo_library_rounded,
              title: 'Photos picker',
              subtitle: 'Choose screenshots from your device'),
        ]),
      ],
    );
  }
}

class ExpiryRemindersScreen extends StatelessWidget {
  const ExpiryRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    return SettingsDetailPage(
      title: 'Expiry Reminders',
      icon: Icons.notifications_none_rounded,
      summary: 'Control reminders before screenshots are cleaned up.',
      children: [
        SettingsGroup(children: [
          SettingsRow(
              icon: Icons.notifications_none_rounded,
              title: 'Enable reminders',
              subtitle:
                  'Notify ${SettingsScreen._durationLabel(controller.notificationLeadTime)} before cleanup',
              value: controller.expiryReminders,
              onChanged: controller.toggleExpiryReminders),
        ]),
        const SettingsNoteCard(
            icon: Icons.schedule_send_rounded,
            title: 'Reminder Behavior',
            subtitle: 'Reminder settings control upcoming cleanup alerts.'),
      ],
    );
  }
}

class ReminderLeadTimeScreen extends StatelessWidget {
  const ReminderLeadTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final options = const [
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 30),
      Duration(hours: 1),
    ];
    return SettingsDetailPage(
      title: 'Lead Time',
      icon: Icons.schedule_send_rounded,
      summary: 'Pick how early reminders should appear.',
      children: [
        SettingsGroup(children: [
          for (final option in options)
            OptionSettingsRow(
              icon: Icons.schedule_send_rounded,
              title: SettingsScreen._durationLabel(option),
              subtitle: 'Warn before the screenshot expires',
              selected: option == controller.notificationLeadTime,
              onTap: () => controller.setNotificationLeadTime(option),
            ),
        ]),
      ],
    );
  }
}

class PhotoAccessScreen extends StatelessWidget {
  const PhotoAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailPage(
      title: 'Photo Access',
      icon: Icons.photo_size_select_actual_rounded,
      summary: 'SnapClean uses explicit picker-based access.',
      children: [
        SettingsGroup(children: [
          StaticSettingsRow(
              icon: Icons.check_circle_outline_rounded,
              title: 'Limited access',
              subtitle: 'Only selected images are imported'),
          StaticSettingsRow(
              icon: Icons.visibility_off_outlined,
              title: 'No gallery scanning',
              subtitle: 'The app does not scan the full library'),
        ]),
      ],
    );
  }
}

class NotificationAccessScreen extends StatelessWidget {
  const NotificationAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailPage(
      title: 'Notifications',
      icon: Icons.notifications_active_rounded,
      summary: 'Review timer and cleanup communication.',
      children: [
        SettingsGroup(children: [
          StaticSettingsRow(
              icon: Icons.notifications_none_rounded,
              title: 'Expiry reminders',
              subtitle: 'Controlled by reminder settings'),
          StaticSettingsRow(
              icon: Icons.delete_outline_rounded,
              title: 'Cleanup notices',
              subtitle: 'Shown after expired screenshots are removed'),
        ]),
      ],
    );
  }
}

class LocalStorageScreen extends StatelessWidget {
  const LocalStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailPage(
      title: 'Local Storage',
      icon: Icons.lock_outline_rounded,
      summary: 'Review how local copies are handled on this device.',
      children: [
        SettingsGroup(children: [
          StaticSettingsRow(
              icon: Icons.phone_android_rounded,
              title: 'On-device data',
              subtitle: 'Local copies help screenshots load quickly'),
          StaticSettingsRow(
              icon: Icons.cloud_done_rounded,
              title: 'Account sync',
              subtitle: 'Saved screenshots can sync with your account'),
        ]),
      ],
    );
  }
}

class CacheCleanupScreen extends StatelessWidget {
  const CacheCleanupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailPage(
      title: 'Cache Cleanup',
      icon: Icons.storage_rounded,
      summary: 'Review temporary local storage.',
      children: [
        const SettingsGroup(children: [
          StaticSettingsRow(
              icon: Icons.image_outlined,
              title: 'Local image copies',
              subtitle: 'Temporary local image copies'),
          StaticSettingsRow(
              icon: Icons.cleaning_services_rounded,
              title: 'Cleanup status',
              subtitle: 'No extra cleanup needed right now'),
        ]),
        PrimaryButton(
          label: 'Run cleanup check',
          icon: Icons.check_rounded,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache looks clean.')),
          ),
        ),
      ],
    );
  }
}

class RecentlyDeletedScreen extends StatelessWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final deleted = controller.deletedSnaps;
    return SettingsDetailPage(
      title: 'Recently Deleted',
      icon: Icons.restore_from_trash_rounded,
      summary: 'Review screenshots removed during cleanup.',
      children: [
        if (deleted.isEmpty)
          const SettingsNoteCard(
              icon: Icons.check_circle_rounded,
              title: 'Nothing deleted',
              subtitle: 'Deleted screenshots will appear here.')
        else
          SettingsGroup(children: [
            for (final item in deleted.take(8))
              StaticSettingsRow(
                  icon: Icons.image_outlined,
                  title: item.title,
                  subtitle: 'Tap to restore or delete forever',
                  onTap: () => _openDeletedActions(context, item)),
          ]),
      ],
    );
  }

  void _openDeletedActions(BuildContext context, SnapItem item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyStateCard(
              icon: Icons.restore_from_trash_rounded,
              title: item.title,
              subtitle: 'Restore this screenshot or delete it permanently.',
            ),
            PrimaryButton(
              label: 'Restore To Saved',
              icon: Icons.restore_rounded,
              onTap: () {
                Navigator.pop(sheetContext);
                _restore(context, item);
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Delete Forever',
              icon: Icons.delete_forever_rounded,
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmPermanentDelete(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _restore(BuildContext context, SnapItem item) {
    SnapCleanScope.of(context).restoreDeletedSnap(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} restored to Saved.')),
    );
  }

  void _confirmPermanentDelete(BuildContext context, SnapItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete forever?'),
        content: Text(
            '"${item.title}" will be permanently removed from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              SnapCleanScope.of(context).permanentlyDeleteSnap(item.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.title} deleted forever.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    return SettingsDetailPage(
      title: 'Theme',
      icon: Icons.contrast_rounded,
      summary: 'Change the app background used across SnapClean.',
      children: [
        SettingsGroup(children: [
          for (final style in AppBackgroundStyle.values)
            BackgroundOptionRow(
              style: style,
              selected: style == controller.appBackground,
              onTap: () => controller.setAppBackground(style),
            ),
        ]),
        const SettingsNoteCard(
          icon: Icons.palette_rounded,
          title: 'Background Applied',
          subtitle: 'Your selected background appears across app screens.',
        ),
      ],
    );
  }
}

class BackgroundOptionRow extends StatelessWidget {
  final AppBackgroundStyle style;
  final bool selected;
  final VoidCallback onTap;
  const BackgroundOptionRow(
      {required this.style,
      required this.selected,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: style.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? AppColors.brand : AppColors.line,
                  width: selected ? 2 : 1),
            ),
            child: Icon(style.icon,
                color: style.isDark ? Colors.white : AppColors.brandDark,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(style.label, style: AppText.value),
              const SizedBox(height: 3),
              Text(style.description, style: AppText.label),
            ]),
          ),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.mint : const Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class AboutSnapCleanScreen extends StatelessWidget {
  const AboutSnapCleanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailPage(
      title: 'About',
      icon: Icons.info_outline_rounded,
      summary: 'SnapClean helps users manage temporary screenshots.',
      children: [
        SettingsGroup(children: [
          StaticSettingsRow(
              icon: Icons.verified_rounded,
              title: 'SnapClean',
              subtitle: 'Version 1.0'),
          StaticSettingsRow(
              icon: Icons.timer_rounded,
              title: 'Core workflow',
              subtitle: 'Import, timer, archive, and cleanup'),
          StaticSettingsRow(
              icon: Icons.cloud_done_rounded,
              title: 'Account sync',
              subtitle: 'Screenshots and folders save to your account'),
        ]),
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailPage(
      title: 'Privacy',
      icon: Icons.privacy_tip_outlined,
      summary: 'How SnapClean handles selected screenshots.',
      children: [
        SettingsNoteCard(
          icon: Icons.lock_outline_rounded,
          title: 'User-selected images',
          subtitle:
              'Only screenshots you choose enter SnapClean.',
        ),
        SettingsGroup(children: [
          StaticSettingsRow(
              icon: Icons.photo_library_rounded,
              title: 'Selected images',
              subtitle: 'Only user-selected images enter the app'),
          StaticSettingsRow(
              icon: Icons.delete_sweep_rounded,
              title: 'Cleanup timers',
              subtitle: 'Timers control when screenshots are cleaned up'),
          StaticSettingsRow(
              icon: Icons.cloud_done_rounded,
              title: 'Account storage',
              subtitle: 'Saved screenshots can sync with your account'),
        ]),
      ],
    );
  }
}

class SettingsDetailPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String summary;
  final List<Widget> children;
  const SettingsDetailPage(
      {required this.title,
      required this.icon,
      required this.summary,
      required this.children,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Settings',
        title: title,
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            SettingsHeroCard(icon: icon, title: title, summary: summary),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingsHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  const SettingsHeroCard(
      {required this.icon,
      required this.title,
      required this.summary,
      super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: AppColors.brandDark, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(summary, style: AppText.label),
            ]),
          ),
        ],
      ),
    );
  }
}

class OptionSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  const OptionSettingsRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.selected,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SettingIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_titleCase(title), style: AppText.value),
                const SizedBox(height: 3),
                Text(subtitle, style: AppText.label),
              ])),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.mint : const Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class SettingsNoteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const SettingsNoteCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      super.key});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
        icon: icon, title: title, subtitle: subtitle, color: AppColors.brand);
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
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D0F172A), blurRadius: 24, offset: Offset(0, 12))
          ],
        ),
        child: Row(
          children: [
            const ProfileBlock(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(user.email, style: AppText.label),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class SettingsGroupLabel extends StatelessWidget {
  final String label;
  const SettingsGroupLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(),
            style: AppText.label.copyWith(
                fontSize: 11,
                letterSpacing: .5,
                fontWeight: FontWeight.w900,
                color: AppColors.subtle)),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int index = 0; index < children.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: children[index],
            ),
            if (index != children.length - 1)
              const Divider(height: 1, indent: 66),
          ],
        ],
      ),
    );
  }
}

class ProfileBlock extends StatelessWidget {
  final String? imagePath;
  const ProfileBlock({this.imagePath, super.key});

  @override
  Widget build(BuildContext context) {
    final avatarImagePath =
        imagePath ?? SnapCleanScope.of(context).user.avatarImagePath;
    return Container(
      width: 78,
      height: 78,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              colors: [Color(0xFFCFFAFE), Color(0xFFF0FDFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: avatarImagePath == null || avatarImagePath.isEmpty
          ? const Icon(Icons.person_rounded,
              color: AppColors.brandDark, size: 44)
          : Image.file(
              File(avatarImagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                  color: AppColors.brandDark, size: 44),
            ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onInfoTap;
  const SettingsRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged,
      this.onInfoTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onInfoTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SettingIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_titleCase(title), style: AppText.value),
                const SizedBox(height: 3),
                Text(subtitle, style: AppText.label)
              ])),
          GestureDetector(
              onTap: () => onChanged(!value),
              child: SettingsSwitch(value: value)),
        ],
      ),
    );
  }
}

class StaticSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const StaticSettingsRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(children: [
        SettingIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_titleCase(title), style: AppText.value),
          const SizedBox(height: 3),
          Text(subtitle, style: AppText.label)
        ])),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1))
      ]),
    );
  }
}

class SettingsLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const SettingsLinkRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SettingIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(child: Text(_titleCase(label), style: AppText.value)),
          Text(value, style: AppText.label),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const SettingsActionRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(children: [
        SettingIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_titleCase(title), style: AppText.value),
          const SizedBox(height: 3),
          Text(subtitle, style: AppText.label)
        ])),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1))
      ]),
    );
  }
}

class SettingIcon extends StatelessWidget {
  final IconData icon;
  const SettingIcon({required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(icon);
    return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: color, size: 20));
  }

  Color _colorFor(IconData icon) {
    if (icon == Icons.delete_sweep_rounded ||
        icon == Icons.restore_from_trash_rounded ||
        icon == Icons.delete_outline_rounded ||
        icon == Icons.restart_alt_rounded) {
      return AppColors.rose;
    }
    if (icon == Icons.lock_outline_rounded ||
        icon == Icons.privacy_tip_outlined ||
        icon == Icons.shield_outlined ||
        icon == Icons.check_circle_outline_rounded) {
      return AppColors.mint;
    }
    if (icon == Icons.storage_rounded ||
        icon == Icons.cleaning_services_rounded) {
      return AppColors.amber;
    }
    if (icon == Icons.contrast_rounded ||
        icon == Icons.dark_mode_rounded ||
        icon == Icons.light_mode_rounded) {
      return AppColors.lavender;
    }
    return AppColors.brandDark;
  }
}

class SettingsSwitch extends StatelessWidget {
  final bool value;
  const SettingsSwitch({required this.value, super.key});

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

String _titleCase(String value) {
  return value.split(' ').map((word) {
    if (word.isEmpty) return word;
    if (word == word.toUpperCase()) return word;
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}
