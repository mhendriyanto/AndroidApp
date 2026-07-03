import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mock_screenshot.dart';
import '../../widgets/snap_widgets.dart';
import '../snap_detail_screen.dart';

class ImportScreen extends StatelessWidget {
  final VoidCallback onViewActive;
  const ImportScreen({required this.onViewActive, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final draft = controller.importDraft;
    return AppPage(
      eyebrow: 'From Photos',
      title: 'Import',
      leading: RoundIcon(icon: Icons.close_rounded, onTap: () {}),
      child: Column(
        children: [
          ImportSteps(
            selectedImages: draft.isNotEmpty,
            selectedTimer: controller.selectedImportTimer.duration != null ||
                controller.selectedImportTimer.label == 'Keep',
          ),
          GestureDetector(
            onTap: () => _openImageImport(context),
            child: const GoogleAddBox(),
          ),
          SectionHeader(
              title: 'Selected',
              action: draft.isEmpty ? 'None' : '${draft.length} shots'),
          if (draft.isEmpty)
            const AppCard(
                child: Text(
                    'Tap Add screenshot to choose images from this emulator.',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.muted)))
          else
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final item in draft)
                  SmallSquareMock(type: item.type, imagePath: item.imagePath),
              ],
            ),
          SectionHeader(
              title: 'Choose timer',
              action: controller.selectedImportTimer.label),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final timer in controller.importTimerOptions)
                TimerTile(
                  icon: timer.icon,
                  title: timer.label,
                  subtitle: timer.subtitle,
                  active: timer.id == controller.selectedImportTimer.id,
                  onTap: timer.isCustom
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AddTimerScreen(timer: timer)),
                          )
                      : () => controller.selectImportTimer(timer),
                ),
              TimerTile(
                icon: Icons.add_rounded,
                title: 'Custom',
                subtitle: 'Add timer',
                active: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTimerScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (draft.isNotEmpty)
            ImportReviewCard(
              count: draft.length,
              timer: controller.selectedImportTimer,
            ),
          PrimaryButton(
            label: 'Save timer',
            icon: Icons.hourglass_bottom_rounded,
            onTap: draft.isEmpty
                ? () => _openImageImport(context)
                : () {
                    final saved = controller.saveImport();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TimerSetScreen(
                                saved: saved, onViewActive: onViewActive)));
                  },
          ),
        ],
      ),
    );
  }

  void _openImageImport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImageImportScreen()),
    );
  }
}

class ImportSteps extends StatelessWidget {
  final bool selectedImages;
  final bool selectedTimer;
  const ImportSteps(
      {required this.selectedImages, required this.selectedTimer, super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          StepDot(label: '1', title: 'Images', done: selectedImages),
          const StepLine(),
          StepDot(label: '2', title: 'Timer', done: selectedTimer),
          const StepLine(),
          StepDot(label: '3', title: 'Review', done: selectedImages),
        ],
      ),
    );
  }
}

class StepDot extends StatelessWidget {
  final String label;
  final String title;
  final bool done;
  const StepDot(
      {required this.label,
      required this.title,
      required this.done,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: done ? AppColors.brand : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(done ? Icons.check_rounded : Icons.circle,
                  color: done ? Colors.white : AppColors.muted,
                  size: done ? 17 : 8),
            ),
          ),
          const SizedBox(height: 6),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(
                  color: done ? AppColors.brandDark : AppColors.muted)),
        ],
      ),
    );
  }
}

class StepLine extends StatelessWidget {
  const StepLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 22, height: 2, color: AppColors.line);
  }
}

class ImportReviewCard extends StatelessWidget {
  final int count;
  final ImportTimerOption timer;
  const ImportReviewCard({required this.count, required this.timer, super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.fact_check_rounded,
                color: AppColors.brandDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ready to save', style: AppText.value),
                const SizedBox(height: 3),
                Text('$count images, ${timer.label}', style: AppText.label),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.mint),
        ],
      ),
    );
  }
}

class AddTimerScreen extends StatefulWidget {
  final ImportTimerOption? timer;
  const AddTimerScreen({this.timer, super.key});

  @override
  State<AddTimerScreen> createState() => _AddTimerScreenState();
}

class _AddTimerScreenState extends State<AddTimerScreen> {
  late final TextEditingController name;
  late final TextEditingController minutes;

  @override
  void initState() {
    super.initState();
    final timer = widget.timer;
    name = TextEditingController(text: timer?.label ?? 'Custom timer');
    minutes =
        TextEditingController(text: '${timer?.duration?.inMinutes ?? 90}');
  }

  @override
  void dispose() {
    name.dispose();
    minutes.dispose();
    super.dispose();
  }

  void _save() {
    final amount = int.tryParse(minutes.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a timer longer than 0 minutes.')),
      );
      return;
    }
    final timer = widget.timer;
    if (timer == null) {
      SnapCleanScope.of(context)
          .addCustomImportTimer(label: name.text, minutes: amount);
    } else {
      SnapCleanScope.of(context).updateCustomImportTimer(
          id: timer.id, label: name.text, minutes: amount);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Import timer',
        title: widget.timer == null ? 'New timer' : 'Edit timer',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  AppField(label: 'Name', value: '', controller: name),
                  const SizedBox(height: 12),
                  AppField(label: 'Minutes', value: '', controller: minutes),
                ],
              ),
            ),
            PrimaryButton(
                label: widget.timer == null ? 'Add timer' : 'Save timer',
                icon: Icons.check_rounded,
                onTap: _save),
          ],
        ),
      ),
    );
  }
}

class ImageImportScreen extends StatefulWidget {
  const ImageImportScreen({super.key});

  @override
  State<ImageImportScreen> createState() => _ImageImportScreenState();
}

class _ImageImportScreenState extends State<ImageImportScreen> {
  bool picking = false;

  Future<void> _pickImages() async {
    setState(() => picking = true);
    try {
      final images = await ImagePicker().pickMultiImage(imageQuality: 88);
      if (!mounted) return;
      if (images.isEmpty) {
        setState(() => picking = false);
        return;
      }
      SnapCleanScope.of(context)
          .setImportDraftFromPaths(images.map((image) => image.path).toList());
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => picking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open the emulator image picker.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    return Scaffold(
      body: AppPage(
        eyebrow: 'Emulator photos',
        title: 'Add images',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                        color: Color(0xFFECFEFF), shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library_rounded,
                        color: AppColors.brand, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose screenshots or photos',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Selected images stay local in this test app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          height: 1.4)),
                ],
              ),
            ),
            PrimaryButton(
              label: picking ? 'Opening picker' : 'Choose from emulator',
              icon: Icons.add_photo_alternate_rounded,
              onTap: picking ? () {} : _pickImages,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Use sample screenshots',
              icon: Icons.auto_awesome_rounded,
              onTap: () {
                controller.useSampleImport();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TimerSetScreen extends StatelessWidget {
  final List<SnapItem> saved;
  final VoidCallback onViewActive;
  const TimerSetScreen(
      {required this.saved, required this.onViewActive, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Saved',
        title: 'Timer set',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            HeroClean(
              badge: saved.first.badge(DateTime.now()),
              title: saved.first.isKept
                  ? 'Saved forever.'
                  : 'Deletes automatically.',
              subtitle: saved.first.isKept
                  ? 'This screenshot has no timer.'
                  : 'SnapClean will remove it when the timer expires.',
              badgeIcon: saved.first.isKept
                  ? Icons.all_inclusive_rounded
                  : Icons.check_rounded,
            ),
            SectionHeader(
                title: 'Saved screenshots', action: '${saved.length} shots'),
            for (final item in saved)
              SnapItemCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SnapDetailScreen(item: item)),
                ),
              ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'View active',
              icon: Icons.photo_library_rounded,
              onTap: () {
                Navigator.pop(context);
                onViewActive();
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
                label: 'Import another',
                icon: Icons.add_rounded,
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class GoogleAddBox extends StatelessWidget {
  const GoogleAddBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228,
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFFECFEFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF67E8F9), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D0F172A), blurRadius: 30, offset: Offset(0, 12))
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.brand, size: 30)),
          const SizedBox(height: 14),
          const Text('Add screenshot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Choose from Photos',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted)),
        ],
      ),
    );
  }
}

class TimerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  const TimerTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.active,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: active ? const Color(0xFFECFEFF) : Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
                color: active ? const Color(0xFF67E8F9) : AppColors.line),
            boxShadow: active
                ? const [
                    BoxShadow(
                        color: Color(0x1F0891B2),
                        blurRadius: 22,
                        offset: Offset(0, 10))
                  ]
                : null),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.brand),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900)),
                Text(subtitle, style: AppText.label)
              ])
            ]),
      ),
    );
  }
}
