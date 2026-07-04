import 'package:flutter/material.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snap_widgets.dart';
import 'active_screen.dart';
import '../snap_detail_screen.dart';

class ExpiringScreen extends StatefulWidget {
  const ExpiringScreen({super.key});

  @override
  State<ExpiringScreen> createState() => _ExpiringScreenState();
}

class _ExpiringScreenState extends State<ExpiringScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final tabs = _tabs(controller);
    final urgent = _filtered(controller, tabs);
    return AppPage(
      eyebrow: 'Deletes on app open',
      title: 'Expiring',
      child: Column(
        children: [
          const CleanedStrip(),
          const SizedBox(height: 14),
          Segmented(
              labels: [for (final tab in tabs) tab.label],
              index: filter,
              onChanged: (next) => setState(() => filter = next)),
          SectionHeader(title: 'Review now', action: '${urgent.length} urgent'),
          if (urgent.isEmpty)
            const Column(
              children: [
                SectionHeader(title: 'After cleanup', action: ''),
                EmptyState(),
              ],
            )
          else
            for (final item in urgent)
              SnapItemCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SnapDetailScreen(item: item)),
                ),
                actions: Row(
                  children: [
                    Expanded(
                        child: MiniAction(
                            label: 'Keep',
                            icon: Icons.all_inclusive_rounded,
                            onTap: () => controller.keepSnap(item.id))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: MiniAction(
                            label: item.isSnoozed ? 'Unsnooze' : 'Snooze',
                            icon: item.isSnoozed
                                ? Icons.play_arrow_rounded
                                : Icons.schedule_rounded,
                            onTap: item.isSnoozed
                                ? () => controller.unsnoozeSnap(item.id)
                                : () => controller.snoozeSnap(
                                    item.id, const Duration(hours: 1)))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: MiniAction(
                            label: 'Delete',
                            icon: Icons.delete_rounded,
                            danger: true,
                            onTap: () => controller.deleteSnap(item.id))),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  List<_ExpiringFilterTab> _tabs(AppController controller) {
    return [
      const _ExpiringFilterTab(label: 'All'),
      const _ExpiringFilterTab(
          label: '10 min', max: Duration(minutes: 10)),
      const _ExpiringFilterTab(
          label: '30 min',
          min: Duration(minutes: 10),
          max: Duration(minutes: 30)),
      const _ExpiringFilterTab(
          label: '1 hr',
          min: Duration(minutes: 30),
          max: Duration(hours: 1)),
      for (final timer in controller.customImportTimers)
        if (timer.duration != null)
          _ExpiringFilterTab(
              label: timer.label,
              min: _rangeStartFor(timer.duration!),
              max: timer.duration),
      const _ExpiringFilterTab(
          label: 'Today', min: Duration(hours: 1), today: true),
    ];
  }

  List<SnapItem> _filtered(
      AppController controller, List<_ExpiringFilterTab> tabs) {
    final now = DateTime.now();
    final tab = tabs[filter.clamp(0, tabs.length - 1)];
    if (tab.today) {
      return controller.activeSnaps.where((item) {
        final left = item.remaining(now);
        final expiresAt = item.expiresAt;
        if (expiresAt == null || expiresAt.isBefore(now)) return false;
        if (!_isAfterMin(left, tab.min)) return false;
        return expiresAt.isBefore(_startOfTomorrow(now));
      }).toList();
    }
    final max = tab.max;
    if (max == null) return controller.expiringSnaps;
    return controller.expiringSnaps.where((item) {
      final left = item.remaining(now);
      return _isInRange(left, min: tab.min, max: max);
    }).toList();
  }

  bool _isInRange(Duration? left, {Duration? min, required Duration max}) {
    if (left == null || left.isNegative) return false;
    if (!_isAfterMin(left, min)) return false;
    return left <= max;
  }

  bool _isAfterMin(Duration? left, Duration? min) {
    if (left == null || left.isNegative) return false;
    return min == null || left > min;
  }

  DateTime _startOfTomorrow(DateTime now) {
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  Duration? _rangeStartFor(Duration duration) {
    if (duration <= const Duration(minutes: 10)) return null;
    if (duration <= const Duration(minutes: 30)) {
      return const Duration(minutes: 10);
    }
    if (duration <= const Duration(hours: 1)) {
      return const Duration(minutes: 30);
    }
    return const Duration(hours: 1);
  }
}

class _ExpiringFilterTab {
  final String label;
  final Duration? min;
  final Duration? max;
  final bool today;

  const _ExpiringFilterTab(
      {required this.label, this.min, this.max, this.today = false});
}

class MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;
  const MiniAction(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.danger = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.rose : AppColors.brandDark;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
          foregroundColor: color,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          side: BorderSide(
              color:
                  danger ? const Color(0xFFFFCCD5) : const Color(0xFFA5F3FC)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }
}

class CleanedStrip extends StatelessWidget {
  const CleanedStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFBBF7D0))),
      child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.check_rounded, color: Color(0xFF047857), size: 18),
              SizedBox(width: 8),
              Text('4 cleaned',
                  style: TextStyle(
                      color: Color(0xFF047857), fontWeight: FontWeight.w900))
            ]),
            Text('9:41 AM',
                style: TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF047857), size: 28)),
          const SizedBox(height: 12),
          const Text('All clean', style: AppText.value),
          const SizedBox(height: 4),
          const Text('No expired screenshots left.',
              style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
