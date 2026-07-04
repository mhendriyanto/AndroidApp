import 'package:flutter/material.dart';

import '../models/snap_item.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/mock_screenshot.dart';

class SnapDetailScreen extends StatefulWidget {
  final SnapItem item;
  const SnapDetailScreen({required this.item, super.key});

  @override
  State<SnapDetailScreen> createState() => _SnapDetailScreenState();
}

class _SnapDetailScreenState extends State<SnapDetailScreen> {
  late SnapItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: item.isKept ? 'Saved screenshot' : item.badge(DateTime.now()),
        title: item.title,
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        trailing:
            RoundIcon(icon: Icons.more_horiz_rounded, onTap: _showActionSheet),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(10),
              child: AspectRatio(
                aspectRatio: .72,
                child: ImagePreview(
                  imagePath: item.imagePath,
                  imageUrl: item.imageDownloadUrl,
                  fallback: MiniMock(type: item.type),
                ),
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.note, style: AppText.value),
                  const SizedBox(height: 12),
                  DetailRow(label: 'Timer', value: item.badge(DateTime.now())),
                  const Divider(height: 24),
                  DetailRow(
                      label: 'Status', value: item.isKept ? 'Kept' : 'Active'),
                ],
              ),
            ),
            if (!item.isKept) ...[
              PrimaryButton(
                label: 'Keep forever',
                icon: Icons.all_inclusive_rounded,
                onTap: () {
                  SnapCleanScope.of(context).keepSnap(item.id);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: item.isSnoozed ? 'Unsnooze Timer' : 'Snooze Timer',
                icon: item.isSnoozed
                    ? Icons.play_arrow_rounded
                    : Icons.schedule_rounded,
                onTap: () {
                  if (item.isSnoozed) {
                    SnapCleanScope.of(context).unsnoozeSnap(item.id);
                  } else {
                    SnapCleanScope.of(context)
                        .snoozeSnap(item.id, const Duration(hours: 1));
                  }
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Delete now',
                icon: Icons.delete_rounded,
                onTap: _confirmDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .72,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyStateCard(
                    icon: Icons.image_rounded,
                    title: item.title,
                    subtitle: item.isKept
                        ? 'Archived screenshot'
                        : 'Timer ${item.badge(DateTime.now())}'),
                DetailActionTile(
                    icon: Icons.drive_file_rename_outline_rounded,
                    label: 'Rename',
                    onTap: () {
                      Navigator.pop(context);
                      _rename();
                    }),
                DetailActionTile(
                    icon: Icons.timer_rounded,
                    label: 'Change timer',
                    onTap: () {
                      Navigator.pop(context);
                      _changeTimer();
                    }),
                DetailActionTile(
                    icon: Icons.folder_rounded,
                    label: 'Add to folder',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Choose a folder from Saved first.')),
                      );
                    }),
                DetailActionTile(
                    icon: Icons.bookmark_rounded,
                    label: 'Move to Archive',
                    onTap: () {
                      Navigator.pop(context);
                      SnapCleanScope.of(context).keepSnap(item.id);
                      setState(() {
                        item = item.copyWith(
                            expiresAt: null,
                            resumeExpiresAt: null,
                            snoozedRemainingSeconds: null,
                            status: SnapStatus.kept,
                            note: 'Saved for later.');
                      });
                    }),
                DetailActionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    danger: true,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete();
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _rename() {
    final controller = TextEditingController(text: item.title);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppField(
                label: 'Screenshot name', value: '', controller: controller),
            const SizedBox(height: 14),
            PrimaryButton(
                label: 'Save name',
                icon: Icons.check_rounded,
                onTap: () {
                  final next = controller.text.trim();
                  if (next.isNotEmpty) {
                    SnapCleanScope.of(context).renameSnap(item.id, next);
                    setState(() => item = item.copyWith(title: next));
                  }
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  void _changeTimer() {
    final options = const [
      ('10 minutes', Duration(minutes: 10)),
      ('30 minutes', Duration(minutes: 30)),
      ('1 hr', Duration(hours: 1)),
      ('Tomorrow', Duration(days: 1)),
    ];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                leading:
                    const Icon(Icons.timer_rounded, color: AppColors.brand),
                title: Text(option.$1,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                onTap: () {
                  SnapCleanScope.of(context)
                      .setSnapTimer(item.id, option.$2, option.$1);
                  final now = DateTime.now();
                  setState(() {
                    item = item.copyWith(
                        createdAt: now,
                        expiresAt: now.add(option.$2),
                        resumeExpiresAt: null,
                        snoozedRemainingSeconds: null,
                        status: SnapStatus.active,
                        note: 'Timer changed to ${option.$1}.');
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showConfirmSheet(context,
            title: 'Delete screenshot?',
            message:
                'This moves it to Recently Deleted. You can review it later.',
            confirmLabel: 'Delete',
            icon: Icons.delete_outline_rounded,
            danger: true)
        .then((confirmed) {
      if (!confirmed || !mounted) return;
      SnapCleanScope.of(context).deleteSnap(item.id);
      Navigator.pop(context);
    });
  }
}

class DetailActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const DetailActionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.danger = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.rose : AppColors.brandDark;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const DetailRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.label),
        Text(value, style: AppText.value.copyWith(fontSize: 13)),
      ],
    );
  }
}
