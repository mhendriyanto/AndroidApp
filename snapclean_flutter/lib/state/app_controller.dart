import 'dart:async';

import 'package:flutter/material.dart';

import '../models/snap_item.dart';

class AppController extends ChangeNotifier {
  AppController.seeded()
      : user = const UserProfile(
            name: 'Maya Chen',
            email: 'maya@example.com',
            username: 'maya.clean') {
    final now = DateTime.now();
    _snaps = [
      SnapItem(
          id: 'order',
          title: 'Order confirmation',
          note: 'Delete unless still needed.',
          type: MockType.receipt,
          createdAt: now.subtract(const Duration(minutes: 22)),
          expiresAt: now.add(const Duration(minutes: 8)),
          status: SnapStatus.active),
      SnapItem(
          id: 'chat',
          title: 'Message thread',
          note: 'Temporary reply note.',
          type: MockType.chat,
          createdAt: now.subtract(const Duration(minutes: 17)),
          expiresAt: now.add(const Duration(minutes: 43)),
          status: SnapStatus.active),
      SnapItem(
          id: 'chart',
          title: 'Analytics chart',
          note: 'Review later.',
          type: MockType.chart,
          createdAt: now.subtract(const Duration(hours: 2)),
          expiresAt: now.add(const Duration(hours: 8)),
          status: SnapStatus.active),
      SnapItem(
          id: 'travel',
          title: 'Travel QR code',
          note: 'Saved for trip.',
          type: MockType.travel,
          createdAt: now.subtract(const Duration(days: 1)),
          expiresAt: null,
          status: SnapStatus.kept),
    ];
    _startExpiryWatcher();
  }

  UserProfile user;
  bool autoDeleteExpired = true;
  bool urgentAlerts = true;
  bool expiryReminders = true;
  TimerPreset defaultTimer = TimerPreset.oneHour;
  ImportTimerOption selectedImportTimer =
      ImportTimerOption.fromPreset(TimerPreset.thirtyMinutes);

  late List<SnapItem> _snaps;
  List<ImportDraftItem> importDraft = const [];
  List<ImportTimerOption> customImportTimers = const [];
  List<SnapItem> lastSaved = const [];
  AppNotice? latestNotice;
  Timer? _expiryWatcher;
  int _noticeId = 0;

  List<ImportTimerOption> get importTimerOptions => [
        ...[
          TimerPreset.keep,
          TimerPreset.thirtyMinutes,
          TimerPreset.oneHour,
          TimerPreset.forever
        ].map(ImportTimerOption.fromPreset),
        ...customImportTimers,
      ];

  List<SnapItem> get snaps => List.unmodifiable(
      _snaps.where((snap) => snap.status != SnapStatus.deleted));
  List<SnapItem> get activeSnaps =>
      snaps.where((snap) => snap.status == SnapStatus.active).toList();
  List<SnapItem> get keptSnaps => snaps.where((snap) => snap.isKept).toList();
  List<SnapItem> get expiringSnaps =>
      activeSnaps.where((snap) => snap.expiresSoon(DateTime.now())).toList();

  int get cleanedCount =>
      _snaps.where((snap) => snap.status == SnapStatus.deleted).length + 18;
  int get keptCount => keptSnaps.length + 5;
  String get spaceSaved => '${430 + cleanedCount * 8}MB';

  void signIn(String email) {
    user = user.copyWith(email: email);
    notifyListeners();
  }

  void createAccount({required String username, required String email}) {
    user = user.copyWith(username: username, email: email);
    notifyListeners();
  }

  void updateProfile(UserProfile next) {
    user = next;
    notifyListeners();
  }

  void toggleAutoDelete(bool value) {
    autoDeleteExpired = value;
    if (value) deleteExpiredSnaps();
    notifyListeners();
  }

  void toggleUrgentAlerts(bool value) {
    urgentAlerts = value;
    notifyListeners();
  }

  void toggleExpiryReminders(bool value) {
    expiryReminders = value;
    notifyListeners();
  }

  void setDefaultTimer(TimerPreset timer) {
    defaultTimer = timer;
    selectedImportTimer = ImportTimerOption.fromPreset(
        timer.duration == null ? TimerPreset.thirtyMinutes : timer);
    notifyListeners();
  }

  void beginImport([TimerPreset? timer]) {
    final next = timer ?? defaultTimer;
    selectedImportTimer = ImportTimerOption.fromPreset(
        next.duration == null ? TimerPreset.thirtyMinutes : next);
    notifyListeners();
  }

  void useSampleImport() {
    importDraft = const [
      ImportDraftItem(type: MockType.receipt, title: 'Order confirmation'),
      ImportDraftItem(type: MockType.chat, title: 'Chat snippet'),
      ImportDraftItem(type: MockType.chart, title: 'Analytics chart'),
    ];
    notifyListeners();
  }

  void setImportDraftFromPaths(List<String> imagePaths) {
    final types = MockType.values;
    importDraft = [
      for (int index = 0; index < imagePaths.length; index++)
        ImportDraftItem(
          type: types[index % types.length],
          title: 'Imported image ${index + 1}',
          imagePath: imagePaths[index],
        )
    ];
    notifyListeners();
  }

  void selectImportTimer(ImportTimerOption timer) {
    selectedImportTimer = timer;
    notifyListeners();
  }

  void addCustomImportTimer({required String label, required int minutes}) {
    final trimmed = label.trim();
    final option = ImportTimerOption(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      label: trimmed.isEmpty ? _customTimerLabel(minutes) : trimmed,
      subtitle: _customTimerLabel(minutes),
      icon: Icons.timer_rounded,
      duration: Duration(minutes: minutes),
      isCustom: true,
    );
    customImportTimers = [...customImportTimers, option];
    selectedImportTimer = option;
    notifyListeners();
  }

  void updateCustomImportTimer({
    required String id,
    required String label,
    required int minutes,
  }) {
    final trimmed = label.trim();
    ImportTimerOption? existing;
    for (final timer in customImportTimers) {
      if (timer.id == id) {
        existing = timer;
        break;
      }
    }
    final option = ImportTimerOption(
      id: id,
      label: trimmed.isEmpty ? _customTimerLabel(minutes) : trimmed,
      subtitle: _customTimerLabel(minutes),
      icon: Icons.timer_rounded,
      duration: Duration(minutes: minutes),
      isCustom: true,
    );
    customImportTimers = [
      for (final timer in customImportTimers) timer.id == id ? option : timer
    ];
    if (selectedImportTimer.id == id || existing == null) {
      selectedImportTimer = option;
    }
    notifyListeners();
  }

  String _customTimerLabel(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) return hours == 1 ? '1 hour' : '$hours hours';
    return '${hours}h ${remainder}m';
  }

  List<SnapItem> saveImport() {
    final now = DateTime.now();
    final saved = <SnapItem>[];
    for (final draft in importDraft) {
      final item = SnapItem(
        id: '${draft.type.name}-${now.microsecondsSinceEpoch}-${saved.length}',
        title: draft.title,
        note: draft.imagePath == null
            ? 'Timer started just now.'
            : 'Imported from this emulator.',
        type: draft.type,
        imagePath: draft.imagePath,
        createdAt: now,
        expiresAt: selectedImportTimer.duration == null
            ? null
            : now.add(selectedImportTimer.duration!),
        status: selectedImportTimer.duration == null
            ? SnapStatus.kept
            : SnapStatus.active,
      );
      saved.add(item);
    }
    _snaps = [...saved, ..._snaps];
    lastSaved = saved;
    importDraft = const [];
    notifyListeners();
    return saved;
  }

  void keepSnap(String id) => _updateSnap(
      id,
      (snap) => snap.copyWith(
          expiresAt: null, status: SnapStatus.kept, note: 'Saved for later.'));

  void deleteSnap(String id) =>
      _updateSnap(id, (snap) => snap.copyWith(status: SnapStatus.deleted));

  void deleteExpiredSnaps([DateTime? timestamp]) {
    if (!autoDeleteExpired) return;
    final now = timestamp ?? DateTime.now();
    final expired = _snaps
        .where((snap) =>
            snap.status == SnapStatus.active &&
            snap.expiresAt != null &&
            !snap.expiresAt!.isAfter(now))
        .toList();
    if (expired.isEmpty) return;

    _snaps = [
      for (final snap in _snaps)
        expired.any((item) => item.id == snap.id)
            ? snap.copyWith(status: SnapStatus.deleted)
            : snap
    ];
    latestNotice = AppNotice(
      id: ++_noticeId,
      message: expired.length == 1
          ? '${expired.first.title} expired and was deleted.'
          : '${expired.length} expired screenshots were deleted.',
    );
    notifyListeners();
  }

  void snoozeSnap(String id, Duration duration) {
    _updateSnap(
        id,
        (snap) => snap.copyWith(
            expiresAt: DateTime.now().add(duration),
            status: SnapStatus.active,
            note:
                'Snoozed for ${duration.inMinutes >= 60 ? '${duration.inHours}h' : '${duration.inMinutes}m'}.'));
  }

  void _updateSnap(String id, SnapItem Function(SnapItem snap) update) {
    _snaps = [for (final snap in _snaps) snap.id == id ? update(snap) : snap];
    notifyListeners();
  }

  void _startExpiryWatcher() {
    _expiryWatcher?.cancel();
    _expiryWatcher =
        Timer.periodic(const Duration(seconds: 1), (_) => deleteExpiredSnaps());
  }

  @override
  void dispose() {
    _expiryWatcher?.cancel();
    super.dispose();
  }
}

class AppNotice {
  final int id;
  final String message;

  const AppNotice({required this.id, required this.message});
}

class SnapCleanScope extends InheritedNotifier<AppController> {
  final AppController controller;

  const SnapCleanScope(
      {required this.controller, required super.child, super.key})
      : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SnapCleanScope>();
    assert(scope != null, 'SnapCleanScope not found');
    return scope!.controller;
  }
}
