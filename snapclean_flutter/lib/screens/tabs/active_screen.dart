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
  String query = '';
  bool selecting = false;
  final selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final tabs = _tabs(controller);
    final items = _search(_filtered(controller, tabs));
    final urgent = controller.activeSnaps.where((item) {
      final left = item.remaining(DateTime.now());
      return left != null &&
          !left.isNegative &&
          left <= const Duration(minutes: 10);
    }).length;
    return AppPage(
      eyebrow: 'Timed cleanup queue',
      title: 'Timers',
      trailing: RoundIcon(
          icon: Icons.sort_rounded, onTap: () => setState(() => filter = 0)),
      child: Column(
        children: [
          AppSearchBar(
              hint: 'Search timed screenshots',
              onChanged: (value) => setState(() => query = value)),
          const SizedBox(height: 14),
          StatStrip(items: [
            StatTileData(
                value: '${controller.activeSnaps.length}',
                label: 'active',
                icon: Icons.hourglass_bottom_rounded,
                color: AppColors.brand),
            StatTileData(
                value: '$urgent',
                label: 'under 10 min',
                icon: Icons.priority_high_rounded,
                color: urgent == 0 ? AppColors.subtle : AppColors.rose),
            StatTileData(
                value: '${controller.customImportTimers.length}',
                label: 'custom',
                icon: Icons.tune_rounded,
                color: AppColors.lavender),
          ]),
          const SizedBox(height: 14),
          Segmented(
              labels: [for (final tab in tabs) tab.label],
              index: filter,
              onChanged: (next) => setState(() {
                    filter = next;
                    selectedIds.clear();
                  })),
          SectionHeader(
              title: 'Screenshots',
              action: selecting ? 'Cancel' : 'Select',
              onAction: () => setState(() {
                    selecting = !selecting;
                    selectedIds.clear();
                  })),
          if (selecting)
            BatchActionBar(
              count: selectedIds.length,
              primaryLabel: 'Keep',
              primaryIcon: Icons.all_inclusive_rounded,
              onPrimary: selectedIds.isEmpty
                  ? null
                  : () {
                      for (final id in selectedIds.toList()) {
                        controller.keepSnap(id);
                      }
                      setState(() {
                        selecting = false;
                        selectedIds.clear();
                      });
                    },
              secondaryLabel: 'Delete',
              secondaryIcon: Icons.delete_outline_rounded,
              onSecondary: selectedIds.isEmpty
                  ? null
                  : () => _confirmBatchDelete(context, controller),
            )
          else
            SectionHeader(title: 'Shown', action: '${items.length} items'),
          if (items.isEmpty)
            EmptyStateCard(
              icon: query.trim().isEmpty
                  ? Icons.hourglass_empty_rounded
                  : Icons.search_off_rounded,
              title: query.trim().isEmpty
                  ? 'No active timers'
                  : 'No results found',
              subtitle: query.trim().isEmpty
                  ? 'Use the plus button to import screenshots and set a timer.'
                  : 'Try searching by screenshot name, note, or timer group.',
            )
          else
            for (final item in items)
              SnapItemCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SnapDetailScreen(item: item)),
                ),
                actions: Row(
                  children: [
                    if (selecting)
                      Expanded(
                        child: CheckboxListTile(
                          value: selectedIds.contains(item.id),
                          onChanged: (_) => _toggleSelected(item.id),
                          title: const Text('Select'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else ...[
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
                              onTap: () => _confirmDelete(context, item.id))),
                    ],
                  ],
                ),
              ),
        ],
      ),
    );
  }

  List<SnapItem> _search(List<SnapItem> items) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return items;
    return items
        .where((item) =>
            item.title.toLowerCase().contains(term) ||
            item.note.toLowerCase().contains(term) ||
            item.badge(DateTime.now()).toLowerCase().contains(term))
        .toList();
  }

  void _confirmDelete(BuildContext context, String id) {
    showConfirmSheet(context,
            title: 'Delete screenshot?',
            message:
                'This moves it to Recently Deleted. You can review it later.',
            confirmLabel: 'Delete',
            icon: Icons.delete_outline_rounded,
            danger: true)
        .then((confirmed) {
      if (!confirmed || !mounted) return;
      SnapCleanScope.of(context).deleteSnap(id);
    });
  }

  void _confirmBatchDelete(BuildContext context, AppController controller) {
    showConfirmSheet(context,
            title: 'Delete selected?',
            message:
                '${selectedIds.length} screenshots will move to Recently Deleted.',
            confirmLabel: 'Delete',
            icon: Icons.delete_outline_rounded,
            danger: true)
        .then((confirmed) {
      if (!confirmed || !mounted) return;
      for (final id in selectedIds.toList()) {
        controller.deleteSnap(id);
      }
      setState(() {
        selecting = false;
        selectedIds.clear();
      });
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!selectedIds.add(id)) selectedIds.remove(id);
    });
  }

  List<_TimerFilterTab> _tabs(AppController controller) {
    return [
      const _TimerFilterTab(label: 'All'),
      const _TimerFilterTab(label: '10 min', max: Duration(minutes: 10)),
      const _TimerFilterTab(
          label: '30 min',
          min: Duration(minutes: 10),
          max: Duration(minutes: 30)),
      const _TimerFilterTab(
          label: '1 hr',
          min: Duration(minutes: 30),
          max: Duration(hours: 1)),
      for (final timer in controller.customImportTimers)
        if (timer.duration != null)
          _TimerFilterTab(
              label: timer.label,
              min: _rangeStartFor(timer.duration!),
              max: timer.duration),
      const _TimerFilterTab(
          label: 'Today', min: Duration(hours: 1), today: true),
    ];
  }

  List<SnapItem> _filtered(
      AppController controller, List<_TimerFilterTab> tabs) {
    final now = DateTime.now();
    final tab = tabs[filter.clamp(0, tabs.length - 1)];
    if (tab.today) {
      return controller.activeSnaps.where((item) {
        final left = item.remaining(now);
        return _isAfterMin(left, tab.min);
      }).toList();
    }
    final max = tab.max;
    if (max == null) return controller.activeSnaps;
    return controller.activeSnaps.where((item) {
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

class _TimerFilterTab {
  final String label;
  final Duration? min;
  final Duration? max;
  final bool today;

  const _TimerFilterTab(
      {required this.label, this.min, this.max, this.today = false});
}

class BatchActionBar extends StatelessWidget {
  final int count;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback? onSecondary;
  const BatchActionBar(
      {required this.count,
      required this.primaryLabel,
      required this.primaryIcon,
      required this.onPrimary,
      required this.secondaryLabel,
      required this.secondaryIcon,
      required this.onSecondary,
      super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('$count selected', style: AppText.value)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon, size: 18),
                  label: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: Icon(secondaryIcon, size: 18),
                  label: Text(secondaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0F2FE))),
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
                      width: 96,
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
