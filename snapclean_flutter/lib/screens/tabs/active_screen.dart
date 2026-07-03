import 'package:flutter/material.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snap_widgets.dart';
import '../snap_detail_screen.dart';

class ActiveScreen extends StatefulWidget {
  const ActiveScreen({super.key});

  @override
  State<ActiveScreen> createState() => _ActiveScreenState();
}

class _ActiveScreenState extends State<ActiveScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final tabs = _tabs(controller);
    final items = _filtered(controller.activeSnaps, tabs);
    return AppPage(
      eyebrow: 'With timers',
      title: 'Active',
      trailing: RoundIcon(
          icon: Icons.sort_rounded, onTap: () => setState(() => filter = 0)),
      child: Column(
        children: [
          Segmented(
              labels: [for (final tab in tabs) tab.label],
              index: filter,
              onChanged: (next) => setState(() => filter = next)),
          SectionHeader(title: 'Timers', action: '${items.length} active'),
          if (items.isEmpty)
            const AppCard(
                child: Text('No screenshots match this filter.',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.muted)))
          else
            for (final item in items)
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

  List<_TimerFilterTab> _tabs(AppController controller) {
    return [
      const _TimerFilterTab(label: 'All'),
      const _TimerFilterTab(label: '30m', duration: Duration(minutes: 30)),
      const _TimerFilterTab(label: '1h', duration: Duration(hours: 1)),
      for (final timer in controller.customImportTimers)
        if (timer.duration != null)
          _TimerFilterTab(label: timer.label, duration: timer.duration),
      const _TimerFilterTab(label: 'Forever', forever: true),
    ];
  }

  List<SnapItem> _filtered(List<SnapItem> items, List<_TimerFilterTab> tabs) {
    final now = DateTime.now();
    final tab = tabs[filter.clamp(0, tabs.length - 1)];
    if (tab.forever) return items.where((item) => item.isKept).toList();
    final duration = tab.duration;
    if (duration == null) return items;
    return items.where((item) {
      final left = item.remaining(now);
      return left != null && !left.isNegative && left <= duration;
    }).toList();
  }
}

class _TimerFilterTab {
  final String label;
  final Duration? duration;
  final bool forever;

  const _TimerFilterTab(
      {required this.label, this.duration, this.forever = false});
}

class Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const Segmented(
      {required this.labels,
      required this.index,
      required this.onChanged,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(16)),
      child: labels.length <= 4
          ? Row(children: [
              for (int i = 0; i < labels.length; i++)
                Expanded(
                    child: _SegmentButton(
                        label: labels[i],
                        active: i == index,
                        onTap: () => onChanged(i)))
            ])
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (int i = 0; i < labels.length; i++)
                  SizedBox(
                      width: 104,
                      child: _SegmentButton(
                          label: labels[i],
                          active: i == index,
                          onTap: () => onChanged(i)))
              ]),
            ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SegmentButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: active
              ? const [
                  BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 12,
                      offset: Offset(0, 5))
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: active ? AppColors.ink : AppColors.muted),
        ),
      ),
    );
  }
}
