import 'dart:async';

import 'package:flutter/material.dart';

import '../models/snap_item.dart';

enum CleanupBehavior {
  autoDelete('Auto-delete', 'Delete expired screenshots automatically'),
  askFirst('Ask first', 'Confirm before removing expired screenshots'),
  reviewLater('Review later', 'Move expired screenshots to recently deleted');

  final String label;
  final String description;

  const CleanupBehavior(this.label, this.description);
}

enum DefaultSaveLocation {
  timers('Timers', 'Start with a countdown'),
  saved('Saved', 'Keep imports by default'),
  lastUsed('Last used', 'Reuse the most recent choice');

  final String label;
  final String description;

  const DefaultSaveLocation(this.label, this.description);
}

class AppController extends ChangeNotifier {
  AppController.seeded()
      : user = const UserProfile(
            name: 'Maya Chen',
            email: 'maya@example.com',
            username: 'maya.clean') {
    _snaps = const [];
    _startExpiryWatcher();
  }

  List<SnapItem> _sampleSnaps(DateTime now) {
    return [
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
  }

  UserProfile user;
  bool autoDeleteExpired = true;
  bool urgentAlerts = true;
  bool expiryReminders = true;
  CleanupBehavior cleanupBehavior = CleanupBehavior.autoDelete;
  DefaultSaveLocation defaultSaveLocation = DefaultSaveLocation.timers;
  Duration notificationLeadTime = const Duration(minutes: 30);
  TimerPreset defaultTimer = TimerPreset.oneHour;
  ImportTimerOption selectedImportTimer =
      ImportTimerOption.fromPreset(TimerPreset.thirtyMinutes);

  late List<SnapItem> _snaps;
  List<ImportDraftItem> importDraft = const [];
  List<ImportTimerOption> customImportTimers = const [];
  List<SavedFolder> savedFolders = const [];
  List<SnapItem> lastSaved = const [];
  AppNotice? latestNotice;
  Timer? _expiryWatcher;
  int _noticeId = 0;

  List<ImportTimerOption> get importTimerOptions => [
        ...[
          TimerPreset.tenMinutes,
          TimerPreset.thirtyMinutes,
          TimerPreset.oneHour,
        ].map(ImportTimerOption.fromPreset),
        ...customImportTimers,
      ];

  List<SnapItem> get snaps => List.unmodifiable(
      _snaps.where((snap) => snap.status != SnapStatus.deleted));
  List<SnapItem> get activeSnaps =>
      snaps.where((snap) => snap.status == SnapStatus.active).toList();
  List<SnapItem> get keptSnaps => snaps.where((snap) => snap.isKept).toList();
  List<SnapItem> get deletedSnaps =>
      _snaps.where((snap) => snap.status == SnapStatus.deleted).toList();
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
    cleanupBehavior =
        value ? CleanupBehavior.autoDelete : CleanupBehavior.askFirst;
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

  void setCleanupBehavior(CleanupBehavior value) {
    cleanupBehavior = value;
    autoDeleteExpired = value == CleanupBehavior.autoDelete;
    if (autoDeleteExpired) deleteExpiredSnaps();
    notifyListeners();
  }

  void setDefaultSaveLocation(DefaultSaveLocation value) {
    defaultSaveLocation = value;
    notifyListeners();
  }

  void setNotificationLeadTime(Duration value) {
    notificationLeadTime = value;
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

  List<SnapItem> saveArchivedImages(List<String> imagePaths) {
    final now = DateTime.now();
    final types = MockType.values;
    final saved = [
      for (int index = 0; index < imagePaths.length; index++)
        SnapItem(
          id: 'archive-${now.microsecondsSinceEpoch}-$index',
          title: 'Archived image ${index + 1}',
          note: 'Imported into Archive.',
          type: types[index % types.length],
          imagePath: imagePaths[index],
          createdAt: now,
          expiresAt: null,
          status: SnapStatus.kept,
        )
    ];
    if (saved.isEmpty) return const [];
    _snaps = [...saved, ..._snaps];
    lastSaved = saved;
    notifyListeners();
    return saved;
  }

  List<SnapItem> saveSampleArchive() {
    final now = DateTime.now();
    final saved = const [
      ImportDraftItem(type: MockType.receipt, title: 'Archived receipt'),
      ImportDraftItem(type: MockType.travel, title: 'Archived QR code'),
    ].asMap().entries.map((entry) {
      final index = entry.key;
      final draft = entry.value;
      return SnapItem(
        id: 'archive-sample-${now.microsecondsSinceEpoch}-$index',
        title: draft.title,
        note: 'Imported into Archive.',
        type: draft.type,
        createdAt: now,
        expiresAt: null,
        status: SnapStatus.kept,
      );
    }).toList();
    _snaps = [...saved, ..._snaps];
    lastSaved = saved;
    notifyListeners();
    return saved;
  }

  void keepSnap(String id) => _updateSnap(
      id,
      (snap) => snap.copyWith(
          expiresAt: null,
          resumeExpiresAt: null,
          status: SnapStatus.kept,
          note: 'Saved for later.'));

  void renameSnap(String id, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _updateSnap(id, (snap) => snap.copyWith(title: trimmed));
  }

  void deleteSnap(String id) => _updateSnap(id, (snap) {
        savedFolders = [
          for (final folder in savedFolders)
            folder.copyWith(
                snapIds:
                    folder.snapIds.where((snapId) => snapId != id).toList())
        ];
        return snap.copyWith(status: SnapStatus.deleted);
      });

  SavedFolder createSavedFolder(String name) {
    final trimmed = name.trim();
    final folder = SavedFolder(
      id: 'folder-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.isEmpty ? 'New folder' : trimmed,
      createdAt: DateTime.now(),
    );
    savedFolders = [folder, ...savedFolders];
    notifyListeners();
    return folder;
  }

  void renameSavedFolder(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    savedFolders = [
      for (final folder in savedFolders)
        folder.id == id ? folder.copyWith(name: trimmed) : folder
    ];
    notifyListeners();
  }

  void deleteSavedFolder(String id) {
    savedFolders =
        savedFolders.where((folder) => folder.id != id).toList(growable: false);
    notifyListeners();
  }

  void addSnapToFolder({required String folderId, required String snapId}) {
    savedFolders = [
      for (final folder in savedFolders)
        if (folder.id == folderId)
          folder.snapIds.contains(snapId)
              ? folder
              : folder.copyWith(snapIds: [...folder.snapIds, snapId])
        else
          folder
    ];
    notifyListeners();
  }

  void removeSnapFromFolder(
      {required String folderId, required String snapId}) {
    savedFolders = [
      for (final folder in savedFolders)
        folder.id == folderId
            ? folder.copyWith(
                snapIds:
                    folder.snapIds.where((itemId) => itemId != snapId).toList())
            : folder
    ];
    notifyListeners();
  }

  List<SnapItem> snapsInFolder(String folderId) {
    SavedFolder? folder;
    for (final item in savedFolders) {
      if (item.id == folderId) {
        folder = item;
        break;
      }
    }
    if (folder == null) return const [];
    final snapIds = folder.snapIds;
    return keptSnaps
        .where((snap) => snapIds.contains(snap.id))
        .toList(growable: false);
  }

  void deleteExpiredSnaps([DateTime? timestamp]) {
    if (!autoDeleteExpired || cleanupBehavior != CleanupBehavior.autoDelete) {
      return;
    }
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
            resumeExpiresAt: snap.resumeExpiresAt ?? snap.expiresAt,
            status: SnapStatus.active,
            note:
                'Snoozed for ${duration.inMinutes >= 60 ? '${duration.inHours}h' : '${duration.inMinutes}m'}.'));
  }

  void unsnoozeSnap(String id) {
    _updateSnap(
        id,
        (snap) => snap.resumeExpiresAt == null
            ? snap
            : snap.copyWith(
                expiresAt: snap.resumeExpiresAt,
                resumeExpiresAt: null,
                status: SnapStatus.active,
                note: 'Timer resumed.'));
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

  void resetDemoData() {
    _snaps = _sampleSnaps(DateTime.now());
    importDraft = const [];
    savedFolders = const [];
    lastSaved = const [];
    latestNotice = AppNotice(
        id: ++_noticeId, message: 'Demo data has been reset for preview.');
    notifyListeners();
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
