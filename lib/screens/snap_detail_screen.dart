import 'package:flutter/material.dart';

import '../models/snap_item.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/mock_screenshot.dart';

class SnapDetailScreen extends StatelessWidget {
  final SnapItem item;
  const SnapDetailScreen({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: item.isKept ? 'Saved screenshot' : item.badge(DateTime.now()),
        title: item.title,
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(10),
              child: AspectRatio(
                aspectRatio: .72,
                child: ImagePreview(
                  imagePath: item.imagePath,
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
                label: 'Snooze 1 hour',
                icon: Icons.schedule_rounded,
                onTap: () {
                  SnapCleanScope.of(context)
                      .snoozeSnap(item.id, const Duration(hours: 1));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Delete now',
                icon: Icons.delete_rounded,
                onTap: () {
                  SnapCleanScope.of(context).deleteSnap(item.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
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
