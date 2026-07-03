import 'package:flutter/material.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snap_widgets.dart';
import '../snap_detail_screen.dart';
import '../user/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onActive;
  const HomeScreen({required this.onImport, required this.onActive, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final expiring = controller.expiringSnaps;
    return AppPage(
      eyebrow: '${controller.activeSnaps.length} active timers',
      title: 'Home',
      trailing: ProfileAvatar(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
      child: Column(
        children: [
          HeroClean(
            badge: expiring.isEmpty
                ? 'All clear'
                : '${expiring.first.badge(DateTime.now())} left',
            title: expiring.isEmpty
                ? 'No urgent screenshots.'
                : '${expiring.length} shots expire soon.',
            subtitle: expiring.isEmpty
                ? 'Import screenshots when you need temporary storage.'
                : 'Review, keep, or let them delete.',
            badgeIcon:
                expiring.isEmpty ? Icons.check_rounded : Icons.schedule_rounded,
            urgent: expiring.isNotEmpty,
          ),
          MetricRow(items: [
            ('${controller.cleanedCount}', 'cleaned'),
            (controller.spaceSaved, 'space saved'),
            ('${controller.keptCount}', 'kept')
          ]),
          SectionHeader(
              title: 'Quick timers',
              action: 'Add',
              onAction: () => _startImport(context, controller.defaultTimer)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final timer in const [
                  TimerPreset.thirtyMinutes,
                  TimerPreset.oneHour,
                  TimerPreset.tonight,
                  TimerPreset.tomorrow,
                  TimerPreset.forever
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(timer.icon,
                          size: 15,
                          color: timer == controller.defaultTimer
                              ? AppColors.brandDark
                              : AppColors.muted),
                      label: Text(
                          timer.label == '30 minutes' ? '30 min' : timer.label),
                      onPressed: () => _startImport(context, timer),
                      backgroundColor: timer == controller.defaultTimer
                          ? const Color(0xFFECFEFF)
                          : Colors.white,
                      side: BorderSide(
                          color: timer == controller.defaultTimer
                              ? const Color(0xFFA5F3FC)
                              : AppColors.line),
                      labelStyle: TextStyle(
                          color: timer == controller.defaultTimer
                              ? AppColors.brandDark
                              : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w900),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
              ],
            ),
          ),
          SectionHeader(
              title: 'Expiring now', action: 'Review all', onAction: onActive),
          if (expiring.isEmpty)
            const AppCard(
                child: Text('No screenshots need review right now.',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.muted)))
          else
            for (final item in expiring.take(2))
              SnapItemCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SnapDetailScreen(item: item)),
                ),
              ),
        ],
      ),
    );
  }

  void _startImport(BuildContext context, TimerPreset timer) {
    SnapCleanScope.of(context).beginImport(timer);
    onImport();
  }
}
