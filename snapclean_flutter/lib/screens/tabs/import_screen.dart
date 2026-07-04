import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mock_screenshot.dart';
import '../../widgets/snap_widgets.dart';
import '../snap_detail_screen.dart';

const int customTimerDropdownValue = -1;

class ImportScreen extends StatelessWidget {
  final VoidCallback onViewActive;
  final VoidCallback onViewSaved;
  final VoidCallback onClose;
  final VoidCallback onSystemPickerOpening;
  const ImportScreen(
      {required this.onViewActive,
      required this.onViewSaved,
      required this.onClose,
      required this.onSystemPickerOpening,
      super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final draft = controller.importDraft;
    final timerOptions = _timerOptions(controller);
    final canChoosePerScreenshotTimer = draft.isNotEmpty;
    return AppPage(
      eyebrow: 'Photos',
      title: 'Import',
      leading: RoundIcon(icon: Icons.chevron_left_rounded, onTap: onClose),
      child: Column(
        children: [
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
                    'Tap Add screenshot to choose images from your device.',
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
          if (canChoosePerScreenshotTimer) ...[
            SectionHeader(
                title: 'Timers For Each Screenshot',
                action: '${draft.length} choices'),
            for (int index = 0; index < draft.length; index++)
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: SmallSquareMock(
                        type: draft[index].type,
                        imagePath: draft[index].imagePath,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Screenshot ${index + 1}',
                              style: AppText.value.copyWith(fontSize: 15)),
                          const SizedBox(height: 8),
                          _PerScreenshotTimerMenu(
                            value: _timerMinutesForDraft(
                                controller, draft[index], timerOptions),
                            options: timerOptions,
                            onChanged: (minutes) {
                              if (minutes == customTimerDropdownValue) {
                                _openCustomDraftTimer(
                                    context, controller, index);
                                return;
                              }
                              final timer = _timerForMinutes(
                                  timerOptions, minutes);
                              if (timer != null) {
                                controller.setImportDraftTimer(index, timer);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          SectionHeader(
              title: 'Save',
              action:
                  controller.selectedImportTimer.id == TimerPreset.forever.name
                      ? 'Selected'
                      : ''),
          ForeverOptionCard(
            active:
                controller.selectedImportTimer.id == TimerPreset.forever.name,
            onTap: () => controller.selectImportTimer(
                ImportTimerOption.fromPreset(TimerPreset.forever)),
          ),
          const SizedBox(height: 20),
          if (draft.isNotEmpty)
            ImportReviewCard(
              subtitle: _reviewSubtitle(controller, draft),
            ),
          PrimaryButton(
            label: controller.selectedImportTimer.id == TimerPreset.forever.name
                ? 'Save'
                : draft.length == 1
                    ? 'Save Timer'
                    : 'Save Timers',
            icon: controller.selectedImportTimer.id == TimerPreset.forever.name
                ? Icons.bookmark_rounded
                : Icons.hourglass_bottom_rounded,
            onTap: draft.isEmpty
                ? () => _openImageImport(context)
                : () {
                    final saveToArchive = controller.selectedImportTimer.id ==
                        TimerPreset.forever.name;
                    final saved = controller.saveImport();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => saveToArchive
                                ? SaveScreenshotScreen(
                                    saved: saved, onViewSaved: onViewSaved)
                                : TimerSetScreen(
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
      MaterialPageRoute(
          builder: (_) => ImageImportScreen(
              onSystemPickerOpening: onSystemPickerOpening)),
    );
  }

  List<ImportTimerOption> _timerOptions(AppController controller) {
    final optionsByMinutes = <int, ImportTimerOption>{};
    for (final timer in [
      ...controller.importTimerOptions,
      controller.selectedImportTimer,
    ]) {
      final minutes = timer.duration?.inMinutes;
      if (minutes != null) optionsByMinutes.putIfAbsent(minutes, () => timer);
    }
    for (final draft in controller.importDraft) {
      final minutes = draft.timerMinutes;
      if (minutes != null) {
        optionsByMinutes.putIfAbsent(
          minutes,
          () => ImportTimerOption(
            id: 'draft-$minutes',
            label: _durationLabel(minutes),
            subtitle: 'Selected timer',
            icon: Icons.timer_rounded,
            duration: Duration(minutes: minutes),
          ),
        );
      }
    }
    final options = optionsByMinutes.values.toList();
    options.sort((a, b) => a.duration!.compareTo(b.duration!));
    return options;
  }

  int _timerMinutesForDraft(
    AppController controller,
    ImportDraftItem draft,
    List<ImportTimerOption> timerOptions,
  ) {
    final minutes = draft.timerMinutes ??
        controller.selectedImportTimer.duration?.inMinutes ??
        timerOptions.first.duration!.inMinutes;
    return timerOptions.any((timer) => timer.duration!.inMinutes == minutes)
        ? minutes
        : timerOptions.first.duration!.inMinutes;
  }

  ImportTimerOption? _timerForMinutes(
      List<ImportTimerOption> timerOptions, int minutes) {
    for (final timer in timerOptions) {
      if (timer.duration?.inMinutes == minutes) return timer;
    }
    return null;
  }

  void _openCustomDraftTimer(
    BuildContext context,
    AppController controller,
    int draftIndex,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _CustomDraftTimerDialog(
        onSave: (totalMinutes) {
          controller.setImportDraftTimer(
            draftIndex,
            ImportTimerOption(
              id: 'draft-custom-$draftIndex-$totalMinutes',
              label: _durationLabel(totalMinutes),
              subtitle: 'Custom timer',
              icon: Icons.timer_rounded,
              duration: Duration(minutes: totalMinutes),
            ),
          );
        },
      ),
    );
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) return hours == 1 ? '1 hr' : '$hours hr';
    return '$hours hr $remainder min';
  }

  String _reviewSubtitle(
      AppController controller, List<ImportDraftItem> draft) {
    if (controller.selectedImportTimer.duration == null) {
      return '${draft.length} images, saved forever';
    }
    final timerLabels = {
      for (final item in draft)
        item.timerLabel ?? controller.selectedImportTimer.label
    };
    if (timerLabels.length == 1) {
      return '${draft.length} images, ${timerLabels.first}';
    }
    return '${draft.length} images, custom timers assigned';
  }
}

class ForeverOptionCard extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const ForeverOptionCard(
      {required this.active, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: active ? null : const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.bookmark_rounded,
                  color: active ? Colors.white : AppColors.brand, size: 23),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Archive', style: AppText.value),
                  SizedBox(height: 3),
                  Text('Save to the Saved tab with no countdown.',
                      style: AppText.label),
                ],
              ),
            ),
            Icon(
              active ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: active ? AppColors.mint : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomDraftTimerDialog extends StatefulWidget {
  final ValueChanged<int> onSave;
  const _CustomDraftTimerDialog({
    required this.onSave,
  });

  @override
  State<_CustomDraftTimerDialog> createState() =>
      _CustomDraftTimerDialogState();
}

class _CustomDraftTimerDialogState extends State<_CustomDraftTimerDialog> {
  late final TextEditingController hours;
  late final TextEditingController minutes;

  @override
  void initState() {
    super.initState();
    hours = TextEditingController();
    minutes = TextEditingController();
  }

  @override
  void dispose() {
    hours.dispose();
    minutes.dispose();
    super.dispose();
  }

  void _save() {
    final totalMinutes = _customTimerMinutes(hours.text, minutes.text);
    if (totalMinutes == null || totalMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid timer. Minutes must be 0 to 59.')),
      );
      return;
    }
    widget.onSave(totalMinutes);
    Navigator.pop(context);
  }

  int? _customTimerMinutes(String hoursText, String minutesText) {
    final hourAmount =
        int.tryParse(hoursText.trim().isEmpty ? '0' : hoursText.trim());
    final minuteAmount =
        int.tryParse(minutesText.trim().isEmpty ? '0' : minutesText.trim());
    if (hourAmount == null || minuteAmount == null) return null;
    if (hourAmount < 0 || minuteAmount < 0 || minuteAmount >= 60) return null;
    return hourAmount * 60 + minuteAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(title: 'Custom Timer', action: ''),
            Row(
              children: [
                Expanded(
                  child: AppField(
                    label: 'Hours',
                    value: '',
                    controller: hours,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppField(
                    label: 'Minutes',
                    value: '',
                    controller: minutes,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Use Timer',
                    icon: Icons.check_rounded,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTimerOptionCard extends StatelessWidget {
  final bool active;
  final ImportTimerOption? timer;
  final VoidCallback onTap;
  const CustomTimerOptionCard(
      {required this.active,
      required this.timer,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: active ? null : const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.timer_rounded,
                  color: active ? Colors.white : AppColors.brand, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom Timer', style: AppText.value),
                  const SizedBox(height: 3),
                  Text(
                    active && timer != null
                        ? '${timer!.label} for this import only.'
                        : 'Choose a one-time timer for selected screenshots.',
                    style: AppText.label,
                  ),
                ],
              ),
            ),
            Icon(
              active ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: active ? AppColors.mint : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
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
          StepDot(
              label: '1',
              title: 'Images',
              active: !selectedImages,
              done: selectedImages),
          const StepLine(),
          StepDot(
              label: '2',
              title: 'Timer',
              active: selectedImages && !selectedTimer,
              done: selectedTimer),
          const StepLine(),
          StepDot(
              label: '3',
              title: 'Review',
              active: selectedTimer,
              done: selectedImages && selectedTimer),
        ],
      ),
    );
  }
}

class StepDot extends StatelessWidget {
  final String label;
  final String title;
  final bool active;
  final bool done;
  const StepDot(
      {required this.label,
      required this.title,
      this.active = false,
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
              color: done || active ? AppColors.brand : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 17)
                  : Text(label,
                      style: TextStyle(
                          color: active ? Colors.white : AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 6),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(
                  color:
                      done || active ? AppColors.brandDark : AppColors.muted)),
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
  final String subtitle;
  const ImportReviewCard({required this.subtitle, super.key});

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
                Text(subtitle, style: AppText.label),
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

class OneTimeTimerScreen extends StatefulWidget {
  const OneTimeTimerScreen({super.key});

  @override
  State<OneTimeTimerScreen> createState() => _OneTimeTimerScreenState();
}

class _OneTimeTimerScreenState extends State<OneTimeTimerScreen> {
  TextEditingController? hours;
  TextEditingController? minutes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (minutes != null) return;
    final selected = SnapCleanScope.of(context).selectedImportTimer;
    final totalMinutes = selected.id.startsWith('one-time-')
        ? selected.duration?.inMinutes ?? 45
        : 45;
    hours = TextEditingController(text: '${totalMinutes ~/ 60}');
    minutes = TextEditingController(text: '${totalMinutes % 60}');
  }

  @override
  void dispose() {
    hours?.dispose();
    minutes?.dispose();
    super.dispose();
  }

  void _save() {
    final totalMinutes = _totalMinutes();
    if (totalMinutes == null || totalMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid timer. Minutes must be 0 to 59.')),
      );
      return;
    }
    SnapCleanScope.of(context).selectImportTimer(ImportTimerOption(
      id: 'one-time-${DateTime.now().microsecondsSinceEpoch}',
      label: _timerLabel(totalMinutes),
      subtitle: 'This import only',
      icon: Icons.timer_rounded,
      duration: Duration(minutes: totalMinutes),
    ));
    Navigator.pop(context);
  }

  int? _totalMinutes() {
    final hourAmount = int.tryParse(hours!.text.trim().isEmpty
        ? '0'
        : hours!.text.trim());
    final minuteAmount = int.tryParse(minutes!.text.trim().isEmpty
        ? '0'
        : minutes!.text.trim());
    if (hourAmount == null || minuteAmount == null) return null;
    if (hourAmount < 0 || minuteAmount < 0 || minuteAmount >= 60) return null;
    return hourAmount * 60 + minuteAmount;
  }

  String _timerLabel(int amount) {
    if (amount < 60) return '$amount min';
    final hours = amount ~/ 60;
    final remainder = amount % 60;
    if (remainder == 0) return hours == 1 ? '1 hr' : '$hours hr';
    return '$hours hr $remainder min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Import timer',
        title: 'Custom Timer',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppField(
                            label: 'Hours',
                            value: '',
                            controller: hours,
                            keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppField(
                            label: 'Minutes',
                            value: '',
                            controller: minutes,
                            keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PrimaryButton(
                label: 'Use Custom Timer',
                icon: Icons.check_rounded,
                onTap: _save),
          ],
        ),
      ),
    );
  }
}

class _AddTimerScreenState extends State<AddTimerScreen> {
  late final TextEditingController name;
  late final TextEditingController hours;
  late final TextEditingController minutes;

  @override
  void initState() {
    super.initState();
    final timer = widget.timer;
    final totalMinutes = timer?.duration?.inMinutes ?? 90;
    name = TextEditingController(
        text: timer?.isCustom == true ? timer?.label ?? '' : '');
    hours = TextEditingController(text: '${totalMinutes ~/ 60}');
    minutes = TextEditingController(text: '${totalMinutes % 60}');
  }

  @override
  void dispose() {
    name.dispose();
    hours.dispose();
    minutes.dispose();
    super.dispose();
  }

  void _save() {
    final amount = _totalMinutes();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid timer. Minutes must be 0 to 59.')),
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

  int? _totalMinutes() {
    final hourAmount =
        int.tryParse(hours.text.trim().isEmpty ? '0' : hours.text.trim());
    final minuteAmount = int.tryParse(
        minutes.text.trim().isEmpty ? '0' : minutes.text.trim());
    if (hourAmount == null || minuteAmount == null) return null;
    if (hourAmount < 0 || minuteAmount < 0 || minuteAmount >= 60) return null;
    return hourAmount * 60 + minuteAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Import timer',
        title: widget.timer == null ? 'New Timer' : 'Edit Timer',
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
                  Row(
                    children: [
                      Expanded(
                        child: AppField(
                            label: 'Hours',
                            value: '',
                            controller: hours,
                            keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppField(
                            label: 'Minutes',
                            value: '',
                            controller: minutes,
                            keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
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
  final VoidCallback onSystemPickerOpening;
  const ImageImportScreen({required this.onSystemPickerOpening, super.key});

  @override
  State<ImageImportScreen> createState() => _ImageImportScreenState();
}

class _ImageImportScreenState extends State<ImageImportScreen> {
  static const _imageImportChannel = MethodChannel('snapclean/image_import');
  bool picking = false;

  Future<void> _pickImages() async {
    setState(() => picking = true);
    widget.onSystemPickerOpening();
    try {
      final images = await _imageImportChannel.invokeListMethod<String>(
        'pickImages',
        {'maxItems': 50},
      );
      if (!mounted) return;
      if (images == null || images.isEmpty) {
        setState(() => picking = false);
        return;
      }
      SnapCleanScope.of(context).setImportDraftFromPaths(images);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => picking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Photo picker is unavailable right now. Check photo access and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Photos',
        title: 'Add images',
        scrollable: !picking,
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: SizedBox(
          height: picking ? MediaQuery.sizeOf(context).height - 178 : null,
          child: LoadingOverlay(
            visible: picking,
            title: 'Opening image picker',
            subtitle: 'Choose screenshots from your device.',
            child: Column(
              children: [
                const EmptyStateCard(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Choose screenshots to add',
                  subtitle:
                      'Pick one screenshot or select several if Android allows it. Repeat this step to add more.',
                ),
                PrimaryButton(
                  label: picking ? 'Opening picker' : 'Choose Image',
                  icon: Icons.add_photo_alternate_rounded,
                  onTap: picking ? () {} : _pickImages,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimerSetScreen extends StatefulWidget {
  final List<SnapItem> saved;
  final VoidCallback onViewActive;
  const TimerSetScreen(
      {required this.saved, required this.onViewActive, super.key});

  @override
  State<TimerSetScreen> createState() => _TimerSetScreenState();
}

class _TimerSetScreenState extends State<TimerSetScreen> {
  late final List<TextEditingController> names;
  late List<SnapItem> saved;
  bool naming = true;

  @override
  void initState() {
    super.initState();
    saved = widget.saved;
    names = [for (final _ in saved) TextEditingController()];
  }

  @override
  void dispose() {
    for (final controller in names) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveNames() {
    final controller = SnapCleanScope.of(context);
    final renamed = <SnapItem>[];
    for (int index = 0; index < saved.length; index++) {
      final item = saved[index];
      final trimmed = names[index].text.trim();
      if (trimmed.isEmpty || trimmed == item.title) {
        renamed.add(item);
        continue;
      }
      controller.renameSnap(item.id, trimmed);
      renamed.add(item.copyWith(title: trimmed));
    }
    setState(() {
      saved = renamed;
      naming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        eyebrow: 'Saved',
        title: 'Timer Set',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            if (naming) ...[
              SectionHeader(
                  title: saved.length == 1
                      ? 'Name Screenshot'
                      : 'Name Screenshots',
                  action: ''),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        saved.length == 1
                            ? 'Would you like to name this screenshot?'
                            : 'Give each screenshot its own name.',
                        style: AppText.value),
                    const SizedBox(height: 10),
                    for (int index = 0; index < saved.length; index++) ...[
                      AppField(
                          label: 'Screenshot ${index + 1}',
                          value: '',
                          controller: names[index]),
                      if (index != saved.length - 1) const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Cancel',
                            icon: Icons.close_rounded,
                            onTap: () => setState(() => naming = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label:
                                saved.length == 1 ? 'Save Name' : 'Save Names',
                            icon: Icons.check_rounded,
                            onTap: _saveNames,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
                widget.onViewActive();
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

class _PerScreenshotTimerMenu extends StatelessWidget {
  final int value;
  final List<ImportTimerOption> options;
  final ValueChanged<int> onChanged;
  const _PerScreenshotTimerMenu({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: [
            for (final timer in options)
              DropdownMenuItem<int>(
                value: timer.duration!.inMinutes,
                child: Row(
                  children: [
                    Icon(timer.icon, color: AppColors.brand, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        timer.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.value.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            const DropdownMenuItem<int>(
              value: customTimerDropdownValue,
              child: Row(
                children: [
                  Icon(Icons.add_alarm_rounded,
                      color: AppColors.brand, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Custom Timer',
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class SaveScreenshotScreen extends StatefulWidget {
  final List<SnapItem> saved;
  final VoidCallback onViewSaved;
  const SaveScreenshotScreen(
      {required this.saved, required this.onViewSaved, super.key});

  @override
  State<SaveScreenshotScreen> createState() => _SaveScreenshotScreenState();
}

class _SaveScreenshotScreenState extends State<SaveScreenshotScreen> {
  late final List<TextEditingController> names;
  late final TextEditingController folderName;
  late List<SnapItem> saved;
  String? selectedFolderId;
  bool naming = true;

  @override
  void initState() {
    super.initState();
    saved = widget.saved;
    names = [for (final _ in saved) TextEditingController()];
    folderName = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in names) {
      controller.dispose();
    }
    folderName.dispose();
    super.dispose();
  }

  void _saveNames() {
    final controller = SnapCleanScope.of(context);
    final renamed = <SnapItem>[];
    for (int index = 0; index < saved.length; index++) {
      final item = saved[index];
      final trimmed = names[index].text.trim();
      if (trimmed.isEmpty || trimmed == item.title) {
        renamed.add(item);
        continue;
      }
      controller.renameSnap(item.id, trimmed);
      renamed.add(item.copyWith(title: trimmed));
    }
    setState(() {
      saved = renamed;
      naming = false;
    });
  }

  void _assignToFolder(SavedFolder? folder) {
    final controller = SnapCleanScope.of(context);
    final previousFolderId = selectedFolderId;
    if (previousFolderId != null && previousFolderId != folder?.id) {
      for (final item in saved) {
        controller.removeSnapFromFolder(
            folderId: previousFolderId, snapId: item.id);
      }
    }
    if (folder == null) {
      setState(() => selectedFolderId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved in Archive.')),
      );
      return;
    }
    for (final item in saved) {
      controller.addSnapToFolder(folderId: folder.id, snapId: item.id);
    }
    setState(() => selectedFolderId = folder.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to ${folder.name}.')),
    );
  }

  void _createFolder(BuildContext sheetContext) {
    final controller = SnapCleanScope.of(context);
    final folder = controller.createSavedFolder(folderName.text);
    folderName.clear();
    Navigator.pop(sheetContext);
    _assignToFolder(folder);
  }

  void _showCreateFolderSheet() {
    folderName.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
        ),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Create Folder', style: AppText.title),
              const SizedBox(height: 14),
              AppField(label: 'Folder Name', value: '', controller: folderName),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create Folder',
                icon: Icons.create_new_folder_rounded,
                onTap: () => _createFolder(sheetContext),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final folders = controller.savedFolders;
    final selectedFolder = _selectedFolder(folders);

    return Scaffold(
      body: AppPage(
        eyebrow: 'Saved',
        title: 'Save Screenshot',
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            if (naming) ...[
              SectionHeader(
                  title: saved.length == 1
                      ? 'Name Screenshot'
                      : 'Name Screenshots',
                  action: ''),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        saved.length == 1
                            ? 'Would you like to name this screenshot?'
                            : 'Give each screenshot its own name.',
                        style: AppText.value),
                    const SizedBox(height: 10),
                    for (int index = 0; index < saved.length; index++) ...[
                      AppField(
                          label: 'Screenshot ${index + 1}',
                          value: '',
                          controller: names[index]),
                      if (index != saved.length - 1) const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Cancel',
                            icon: Icons.close_rounded,
                            onTap: () => setState(() => naming = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label:
                                saved.length == 1 ? 'Save Name' : 'Save Names',
                            icon: Icons.check_rounded,
                            onTap: _saveNames,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            SectionHeader(
              title: 'Send To Folder',
              action: '',
            ),
            if (folders.isEmpty)
              EmptyStateCard(
                icon: Icons.folder_rounded,
                title: 'No folders yet',
                subtitle:
                    'Keep these in Archive, or create a folder for this saved set.',
                actionLabel: 'Create Folder',
                actionIcon: Icons.create_new_folder_rounded,
                onAction: _showCreateFolderSheet,
              )
            else
              FolderDropdownCard(
                folders: folders,
                selectedFolder: selectedFolder,
                onArchive: () => _assignToFolder(null),
                onFolder: _assignToFolder,
                onCreateFolder: _showCreateFolderSheet,
              ),
            SectionHeader(
                title: 'Saved Screenshots', action: '${saved.length} shots'),
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
              label: 'View Saved',
              icon: Icons.bookmark_rounded,
              onTap: () {
                Navigator.pop(context);
                widget.onViewSaved();
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
                label: 'Import Another',
                icon: Icons.add_rounded,
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  SavedFolder? _selectedFolder(List<SavedFolder> folders) {
    for (final folder in folders) {
      if (folder.id == selectedFolderId) return folder;
    }
    return null;
  }
}

class FolderDropdownCard extends StatelessWidget {
  final List<SavedFolder> folders;
  final SavedFolder? selectedFolder;
  final VoidCallback onArchive;
  final ValueChanged<SavedFolder> onFolder;
  final VoidCallback onCreateFolder;
  const FolderDropdownCard(
      {required this.folders,
      required this.selectedFolder,
      required this.onArchive,
      required this.onFolder,
      required this.onCreateFolder,
      super.key});

  @override
  Widget build(BuildContext context) {
    final folder = selectedFolder;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: PopupMenuButton<String>(
        tooltip: 'Choose folder',
        color: Colors.white,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onSelected: (value) {
          if (value == 'archive') {
            onArchive();
            return;
          }
          if (value == 'create') {
            onCreateFolder();
            return;
          }
          for (final folder in folders) {
            if (folder.id == value) {
              onFolder(folder);
              return;
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'archive',
            child: FolderMenuRow(
              icon: Icons.bookmark_rounded,
              title: 'Archive',
              subtitle: 'Saved with no folder',
              selected: folder == null,
            ),
          ),
          for (final item in folders)
            PopupMenuItem(
              value: item.id,
              child: FolderMenuRow(
                icon: Icons.folder_rounded,
                title: item.name,
                subtitle: '${item.snapIds.length} saved',
                selected: item.id == folder?.id,
              ),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'create',
            child: FolderMenuRow(
              icon: Icons.create_new_folder_rounded,
              title: 'Create Folder',
              subtitle: 'Add another folder',
              selected: false,
            ),
          ),
        ],
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                  folder == null
                      ? Icons.bookmark_rounded
                      : Icons.folder_rounded,
                  color: AppColors.brand),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folder?.name ?? 'Archive', style: AppText.value),
                  const SizedBox(height: 3),
                  Text(
                    folder == null
                        ? 'Tap to choose a folder.'
                        : 'Tap to change folder.',
                    style: AppText.label,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}

class FolderMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  const FolderMenuRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.selected,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brand, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(subtitle, style: AppText.label),
            ],
          ),
        ),
        if (selected)
          const Icon(Icons.check_circle_rounded,
              color: AppColors.mint, size: 18),
      ],
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
          gradient: const LinearGradient(
              colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
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
