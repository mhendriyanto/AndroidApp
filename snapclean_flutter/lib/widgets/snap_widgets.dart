import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/snap_item.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'mock_screenshot.dart';

class SnapItemCard extends StatefulWidget {
  final SnapItem item;
  final VoidCallback? onTap;
  final Widget? actions;
  const SnapItemCard({required this.item, this.onTap, this.actions, super.key});

  @override
  State<SnapItemCard> createState() => _SnapItemCardState();
}

class _SnapItemCardState extends State<SnapItemCard> {
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant SnapItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.expiresAt != widget.item.expiresAt ||
        oldWidget.item.snoozedRemainingSeconds !=
            widget.item.snoozedRemainingSeconds ||
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
    if (widget.item.isSnoozed) return false;
    final left = widget.item.remaining(DateTime.now());
    return widget.item.status == SnapStatus.active &&
        left != null &&
        !left.isNegative &&
        left.inSeconds < 600;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final progress = widget.item.progress(now);
    final badgeKind = widget.item.isKept
        ? BadgeKind.keep
        : widget.item.progressColor(now) == AppColors.rose
            ? BadgeKind.danger
            : widget.item.progressColor(now) == AppColors.amber
                ? BadgeKind.warn
                : BadgeKind.normal;
    return GestureDetector(
      onTap: widget.onTap,
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MiniShot(
                    type: widget.item.type,
                    imagePath: widget.item.imagePath,
                    imageUrl: widget.item.imageDownloadUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(widget.item.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.18,
                                      fontWeight: FontWeight.w900))),
                          BadgePill(
                              label: widget.item.badge(now), kind: badgeKind),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(widget.item.note,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.42,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted)),
                      const SizedBox(height: 8),
                      SyncStatusPill(status: widget.item.syncStatus),
                      if (progress != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFEFF6FF),
                              color: widget.item.progressColor(now)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (widget.actions != null) ...[
              const SizedBox(height: 12),
              widget.actions!
            ],
          ],
        ),
      ),
    );
  }
}

class SyncStatusPill extends StatelessWidget {
  final SnapSyncStatus status;
  const SyncStatusPill({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    return BadgePill(
      label: switch (status) {
        SnapSyncStatus.pending => 'Pending sync',
        SnapSyncStatus.syncing => 'Uploading',
        SnapSyncStatus.synced => 'Synced',
        SnapSyncStatus.failed => 'Sync failed',
      },
      icon: switch (status) {
        SnapSyncStatus.pending => Icons.cloud_queue_rounded,
        SnapSyncStatus.syncing => Icons.cloud_upload_rounded,
        SnapSyncStatus.synced => Icons.cloud_done_rounded,
        SnapSyncStatus.failed => Icons.cloud_off_rounded,
      },
      kind: switch (status) {
        SnapSyncStatus.failed => BadgeKind.danger,
        SnapSyncStatus.synced => BadgeKind.keep,
        _ => BadgeKind.normal,
      },
    );
  }
}

class HeroClean extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final IconData badgeIcon;
  final bool urgent;
  const HeroClean(
      {required this.badge,
      required this.title,
      required this.subtitle,
      required this.badgeIcon,
      this.urgent = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 278),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
            colors: urgent
                ? const [Color(0xFF4C0519), AppColors.rose, Color(0xFFF97316)]
                : const [
                    Color(0xFF0F172A),
                    AppColors.brandDark,
                    Color(0xFF22D3EE)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: const [
          BoxShadow(
              color: Color(0x220891B2), blurRadius: 22, offset: Offset(0, 12))
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: GridPattern()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BadgePill(
                        label: badge,
                        icon: badgeIcon,
                        kind: urgent ? BadgeKind.danger : BadgeKind.keep),
                    const SizedBox(height: 10),
                    Text(title, style: AppText.hero),
                    const SizedBox(height: 8),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 124,
                height: 214,
                child: Stack(
                  children: [
                    Positioned(
                        left: 0,
                        top: 8,
                        child: FloatingMock(angle: -.14, faded: true)),
                    Positioned(
                        right: 0, top: 40, child: FloatingMock(angle: .12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GridPattern extends StatelessWidget {
  const GridPattern({super.key});

  @override
  Widget build(BuildContext context) =>
      const RepaintBoundary(child: CustomPaint(painter: GridPatternPainter()));
}

class GridPatternPainter extends CustomPainter {
  const GridPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.08)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FloatingMock extends StatelessWidget {
  final double angle;
  final bool faded;
  const FloatingMock({this.angle = 0, this.faded = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: faded ? .72 : 1,
        child: Container(
          width: 108,
          height: 166,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x22111827),
                    blurRadius: 14,
                    offset: Offset(0, 8))
              ]),
          child: const MiniMock(type: MockType.receipt),
        ),
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  final List<(String, String)> items;
  const MetricRow({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: MetricBox(value: items[i].$1, label: items[i].$2)),
            if (i != items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class MetricBox extends StatelessWidget {
  final String value;
  final String label;
  const MetricBox({required this.value, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(label, style: AppText.label.copyWith(fontSize: 11))
      ]),
    );
  }
}

class DonutCard extends StatelessWidget {
  final int total;
  final List<TimerMixSegment> segments;
  const DonutCard({required this.total, required this.segments, super.key});

  @override
  Widget build(BuildContext context) {
    final safeSegments =
        segments.where((segment) => segment.count > 0).toList();
    return AppCard(
      child: Column(
        children: [
          SizedBox(
              width: 154,
              height: 154,
              child: RepaintBoundary(
                child: CustomPaint(
                    painter: DonutPainter(segments: safeSegments),
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text('$total',
                              style: const TextStyle(
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w900)),
                          const Text('shots', style: AppText.label)
                        ]))),
              )),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            childAspectRatio: 5.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final segment in segments)
                LegendItem(
                    color: segment.color,
                    label: '${segment.label} (${segment.count})'),
            ],
          ),
        ],
      ),
    );
  }
}

class TimerMixSegment {
  final Color color;
  final String label;
  final int count;
  const TimerMixSegment(
      {required this.color, required this.label, required this.count});
}

class DonutPainter extends CustomPainter {
  final List<TimerMixSegment> segments;
  const DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.butt;
    if (segments.isEmpty) {
      paint.color = const Color(0xFFE2E8F0);
      canvas.drawArc(rect.deflate(12), -math.pi / 2, math.pi * 2, false, paint);
      return;
    }
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.count);
    double start = -math.pi / 2;
    for (final segment in segments) {
      paint.color = segment.color;
      final sweep = math.pi * 2 * (segment.count / total);
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const LegendItem({required this.color, required this.label, super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: AppText.label)
      ]);
}
