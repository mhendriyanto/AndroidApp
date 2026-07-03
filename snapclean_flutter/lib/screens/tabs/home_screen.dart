import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mock_screenshot.dart';
import '../../widgets/snap_widgets.dart';
import '../snap_detail_screen.dart';
import '../user/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onActive;
  const HomeScreen({required this.onActive, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final now = DateTime.now();
    final saved = controller.keptSnaps.length;
    final expiring = controller.activeSnaps.where((item) {
      final left = item.remaining(now);
      return left != null &&
          !left.isNegative &&
          left <= const Duration(minutes: 10);
    }).toList();
    final recent = [
      ...expiring,
      ...controller.activeSnaps.where((item) => !expiring.contains(item)),
      ...controller.keptSnaps,
    ];
    return AppPage(
      eyebrow: '',
      title: 'Home',
      trailing: ProfileAvatar(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
      child: Column(
        children: [
          AppSearchBar(onTap: onActive),
          const SizedBox(height: 16),
          SectionHeader(
              title: 'Current Timer Mix',
              action: '${recent.length} shots',
              onAction: onActive),
          DonutCard(
            total: recent.length,
            segments: _timerMix(controller, now),
          ),
          StatStrip(items: [
            StatTileData(
                value: '${controller.activeSnaps.length}',
                label: 'timed',
                icon: Icons.timer_rounded,
                color: AppColors.brand),
            StatTileData(
                value: '$saved',
                label: 'saved',
                icon: Icons.bookmark_rounded,
                color: AppColors.mint),
            StatTileData(
                value: '${expiring.length}',
                label: 'urgent',
                icon: Icons.priority_high_rounded,
                color: expiring.isEmpty ? AppColors.subtle : AppColors.rose),
          ]),
          SectionHeader(
              title: 'Recents',
              action: '${recent.length} docs',
              onAction: onActive),
          if (recent.isEmpty)
            EmptyStateCard(
              icon: Icons.add_photo_alternate_rounded,
              title: 'No screenshots yet',
              subtitle:
                  'Import screenshots to start timers, archive what matters, and keep cleanup organized.',
              actionLabel: 'Open timers',
              actionIcon: Icons.timer_rounded,
              onAction: onActive,
            )
          else
            for (final item in recent.take(4))
              RecentDocRow(
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

  List<TimerMixSegment> _timerMix(AppController controller, DateTime now) {
    var under30 = 0;
    var under60 = 0;
    var later = 0;
    for (final item in controller.activeSnaps) {
      final left = item.remaining(now);
      if (left == null || left.isNegative) continue;
      if (left <= const Duration(minutes: 30)) {
        under30++;
      } else if (left <= const Duration(hours: 1)) {
        under60++;
      } else {
        later++;
      }
    }
    return [
      TimerMixSegment(color: AppColors.rose, label: '30m', count: under30),
      TimerMixSegment(color: AppColors.amber, label: '1h', count: under60),
      TimerMixSegment(color: AppColors.brand, label: 'Later', count: later),
      TimerMixSegment(
          color: AppColors.mint,
          label: 'Forever',
          count: controller.keptSnaps.length),
    ];
  }
}

class RecentDocRow extends StatefulWidget {
  final SnapItem item;
  final VoidCallback onTap;
  const RecentDocRow({required this.item, required this.onTap, super.key});

  @override
  State<RecentDocRow> createState() => _RecentDocRowState();
}

class _RecentDocRowState extends State<RecentDocRow> {
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant RecentDocRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.expiresAt != widget.item.expiresAt ||
        oldWidget.item.status != widget.item.status) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    ticker?.cancel();
    ticker = null;
    if (!_shouldTick()) return;
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_shouldTick()) {
        _syncTicker();
        return;
      }
      setState(() {});
    });
  }

  bool _shouldTick() {
    final left = widget.item.remaining(DateTime.now());
    return widget.item.status == SnapStatus.active &&
        left != null &&
        !left.isNegative &&
        left.inSeconds < 600;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return GestureDetector(
      onTap: widget.onTap,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            MiniShot(type: widget.item.type, imagePath: widget.item.imagePath),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(
                      '${widget.item.createdAt.month.toString().padLeft(2, '0')}/${widget.item.createdAt.day.toString().padLeft(2, '0')}  |  1 page',
                      style: AppText.label),
                  const SizedBox(height: 10),
                  BadgePill(
                      label: widget.item.badge(now),
                      kind: widget.item.isKept
                          ? BadgeKind.keep
                          : widget.item.progressColor(now) == AppColors.rose
                              ? BadgeKind.danger
                              : BadgeKind.normal),
                ],
              ),
            ),
            const Icon(Icons.more_vert_rounded, color: AppColors.subtle),
          ],
        ),
      ),
    );
  }
}
