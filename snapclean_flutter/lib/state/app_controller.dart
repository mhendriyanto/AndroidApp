import 'dart:async';

import 'package:flutter/material.dart';

import '../models/snap_item.dart';
import '../services/firestore_repository.dart';
import '../services/storage_repository.dart';

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

enum AppBackgroundStyle {
  cloud('Cloud', 'Bright white and pale blue', Icons.cloud_rounded,
      [Color(0xFFF8FAFC), Color(0xFFEFF6FF)]),
  frost('Frost', 'Cool blue and soft cyan', Icons.ac_unit_rounded,
      [Color(0xFFEFF6FF), Color(0xFFECFEFF)]),
  mint('Mint', 'Fresh green and clean white', Icons.spa_rounded,
      [Color(0xFFF0FDF4), Color(0xFFFFFFFF)]),
  lavender('Lavender', 'Soft violet and white', Icons.auto_awesome_rounded,
      [Color(0xFFF5F3FF), Color(0xFFFFFFFF)]),
  slate('Slate', 'Focused dark surface', Icons.dark_mode_rounded,
      [Color(0xFF0F172A), Color(0xFF1E293B)]);

  final String label;
  final String description;
  final IconData icon;
  final List<Color> colors;

  const AppBackgroundStyle(
      this.label, this.description, this.icon, this.colors);

  bool get isDark => this == AppBackgroundStyle.slate;
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

  UserProfile user;
  bool autoDeleteExpired = true;
  bool urgentAlerts = true;
  bool expiryReminders = true;
  CleanupBehavior cleanupBehavior = CleanupBehavior.autoDelete;
  DefaultSaveLocation defaultSaveLocation = DefaultSaveLocation.timers;
  AppBackgroundStyle appBackground = AppBackgroundStyle.cloud;
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
  final FirestoreRepository _firestoreRepository = FirestoreRepository();
  final StorageRepository _storageRepository = StorageRepository();
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

  void loadCloudSnaps(List<SnapItem> cloudSnaps) {
    _snaps = cloudSnaps;
    importDraft = const [];
    lastSaved = const [];
    notifyListeners();
  }

  void loadCloudFolders(List<SavedFolder> cloudFolders) {
    savedFolders = cloudFolders;
    notifyListeners();
  }

  void loadCloudTimers(List<ImportTimerOption> timers) {
    customImportTimers = timers;
    notifyListeners();
  }

  void loadCloudSettings(Map<String, dynamic> settings) {
    final cleanup = _enumByName(
        CleanupBehavior.values, settings['cleanupBehavior'], cleanupBehavior);
    cleanupBehavior = cleanup;
    autoDeleteExpired = _bool(settings['autoDeleteExpired']) ??
        cleanup == CleanupBehavior.autoDelete;
    urgentAlerts = _bool(settings['urgentAlerts']) ?? urgentAlerts;
    expiryReminders =
        _bool(settings['expiryReminders']) ?? expiryReminders;
    defaultSaveLocation = _enumByName(DefaultSaveLocation.values,
        settings['defaultSaveLocation'], defaultSaveLocation);
    appBackground = _enumByName(
        AppBackgroundStyle.values, settings['appBackground'], appBackground);
    defaultTimer =
        _enumByName(TimerPreset.values, settings['defaultTimer'], defaultTimer);
    final leadMinutes = _int(settings['notificationLeadMinutes']);
    if (leadMinutes != null && leadMinutes > 0) {
      notificationLeadTime = Duration(minutes: leadMinutes);
    }
    notifyListeners();
  }

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
    _saveSettingsToCloud();
    notifyListeners();
  }

  void toggleUrgentAlerts(bool value) {
    urgentAlerts = value;
    _saveSettingsToCloud();
    notifyListeners();
  }

  void toggleExpiryReminders(bool value) {
    expiryReminders = value;
    _saveSettingsToCloud();
    notifyListeners();
  }

  void setCleanupBehavior(CleanupBehavior value) {
    cleanupBehavior = value;
    autoDeleteExpired = value == CleanupBehavior.autoDelete;
    if (autoDeleteExpired) deleteExpiredSnaps();
    _saveSettingsToCloud();
    notifyListeners();
  }

  void setDefaultSaveLocation(DefaultSaveLocation value) {
    defaultSaveLocation = value;
    _saveSettingsToCloud();
    notifyListeners();
  }

  void setAppBackground(AppBackgroundStyle value) {
    appBackground = value;
    _saveSettingsToCloud();
    notifyListeners();
  }

  void setNotificationLeadTime(Duration value) {
    notificationLeadTime = value;
    _saveSettingsToCloud();
    notifyListeners();
  }

  void setDefaultTimer(TimerPreset timer) {
    defaultTimer = timer;
    selectedImportTimer = ImportTimerOption.fromPreset(
        timer.duration == null ? TimerPreset.thirtyMinutes : timer);
    _saveSettingsToCloud();
    notifyListeners();
  }

  void beginImport([TimerPreset? timer]) {
    final next = timer ?? defaultTimer;
    selectedImportTimer = ImportTimerOption.fromPreset(
        next.duration == null ? TimerPreset.thirtyMinutes : next);
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
          timerMinutes: selectedImportTimer.duration?.inMinutes,
          timerLabel: selectedImportTimer.label,
        )
    ];
    notifyListeners();
  }

  void selectImportTimer(ImportTimerOption timer) {
    selectedImportTimer = timer;
    importDraft = [
      for (final draft in importDraft)
        draft.copyWith(
          timerMinutes: timer.duration?.inMinutes,
          timerLabel: timer.duration == null ? null : timer.label,
        )
    ];
    notifyListeners();
  }

  void setImportDraftTimer(int index, ImportTimerOption timer) {
    final duration = timer.duration;
    if (index < 0 || index >= importDraft.length || duration == null) {
      return;
    }
    importDraft = [
      for (int itemIndex = 0; itemIndex < importDraft.length; itemIndex++)
        itemIndex == index
            ? importDraft[itemIndex].copyWith(
                timerMinutes: duration.inMinutes,
                timerLabel: timer.label,
              )
            : importDraft[itemIndex]
    ];
    if (selectedImportTimer.duration == null) {
      selectedImportTimer = timer;
    }
    notifyListeners();
  }

  void addCustomImportTimer({required String label, required int minutes}) {
    final trimmed = label.trim();
    final durationLabel = _customTimerLabel(minutes);
    final option = ImportTimerOption(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      label: _customTimerDisplayName(trimmed, durationLabel),
      subtitle: durationLabel,
      icon: Icons.timer_rounded,
      duration: Duration(minutes: minutes),
      isCustom: true,
    );
    customImportTimers = [...customImportTimers, option];
    selectedImportTimer = option;
    importDraft = [
      for (final draft in importDraft)
        draft.copyWith(
          timerMinutes: option.duration?.inMinutes,
          timerLabel: option.label,
        )
    ];
    _saveTimerToCloud(option);
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
    final durationLabel = _customTimerLabel(minutes);
    final option = ImportTimerOption(
      id: id,
      label: _customTimerDisplayName(trimmed, durationLabel),
      subtitle: durationLabel,
      icon: Icons.timer_rounded,
      duration: Duration(minutes: minutes),
      isCustom: true,
    );
    customImportTimers = [
      for (final timer in customImportTimers) timer.id == id ? option : timer
    ];
    if (selectedImportTimer.id == id || existing == null) {
      selectedImportTimer = option;
      importDraft = [
        for (final draft in importDraft)
          draft.copyWith(
            timerMinutes: option.duration?.inMinutes,
            timerLabel: option.label,
          )
      ];
    }
    _saveTimerToCloud(option);
    notifyListeners();
  }

  String _customTimerLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) return hours == 1 ? '1 hr' : '$hours hr';
    return '${hours} hr ${remainder} min';
  }

  String _customTimerDisplayName(String name, String durationLabel) {
    return name.isEmpty || name.toLowerCase() == 'custom timer'
        ? durationLabel
        : name;
  }

  List<SnapItem> saveImport() {
    final now = DateTime.now();
    final saved = <SnapItem>[];
    for (final draft in importDraft) {
      final minutes =
          draft.timerMinutes ?? selectedImportTimer.duration?.inMinutes;
      final item = SnapItem(
        id: '${draft.type.name}-${now.microsecondsSinceEpoch}-${saved.length}',
        title: draft.title,
        note: draft.imagePath == null
            ? 'Timer started just now.'
            : 'Imported from Photos.',
        type: draft.type,
        imagePath: draft.imagePath,
        createdAt: now,
        expiresAt: minutes == null ? null : now.add(Duration(minutes: minutes)),
        status: minutes == null ? SnapStatus.kept : SnapStatus.active,
      );
      saved.add(item);
    }
    _snaps = [...saved, ..._snaps];
    lastSaved = saved;
    importDraft = const [];
    _saveSnapsToCloud(saved);
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
    _saveSnapsToCloud(saved);
    notifyListeners();
    return saved;
  }

  void keepSnap(String id) => _updateSnap(
      id,
      (snap) => snap.copyWith(
          expiresAt: null,
          resumeExpiresAt: null,
          snoozedRemainingSeconds: null,
          status: SnapStatus.kept,
          note: 'Saved for later.'));

  void renameSnap(String id, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _updateSnap(id, (snap) => snap.copyWith(title: trimmed));
  }

  void setSnapTimer(String id, Duration duration, String label) {
    final now = DateTime.now();
    _updateSnap(
        id,
        (snap) => snap.copyWith(
            createdAt: now,
            expiresAt: now.add(duration),
            resumeExpiresAt: null,
            snoozedRemainingSeconds: null,
            status: SnapStatus.active,
            note: 'Timer changed to $label.'));
  }

  void deleteSnap(String id) => _updateSnap(id, (snap) {
        final updatedFolders = <SavedFolder>[];
        for (final folder in savedFolders) {
          final nextFolder = folder.copyWith(
              snapIds:
                  folder.snapIds.where((snapId) => snapId != id).toList());
          updatedFolders.add(nextFolder);
          if (nextFolder.snapIds.length != folder.snapIds.length) {
            _saveFolderToCloud(nextFolder);
          }
        }
        savedFolders = updatedFolders;
        return snap.copyWith(status: SnapStatus.deleted);
      });

  void restoreDeletedSnap(String id) => _updateSnap(
      id,
      (snap) => snap.copyWith(
          expiresAt: null,
          resumeExpiresAt: null,
          snoozedRemainingSeconds: null,
          status: SnapStatus.kept,
          note: 'Restored to Saved.'));

  void permanentlyDeleteSnap(String id) {
    SnapItem? removed;
    final remaining = <SnapItem>[];
    for (final snap in _snaps) {
      if (snap.id == id) {
        removed = snap;
      } else {
        remaining.add(snap);
      }
    }
    _snaps = remaining;
    final updatedFolders = <SavedFolder>[];
    for (final folder in savedFolders) {
      final nextFolder = folder.copyWith(
          snapIds: folder.snapIds.where((snapId) => snapId != id).toList());
      updatedFolders.add(nextFolder);
      if (nextFolder.snapIds.length != folder.snapIds.length) {
        _saveFolderToCloud(nextFolder);
      }
    }
    savedFolders = updatedFolders;
    final snap = removed;
    if (snap != null) {
      _deleteSnapFromCloud(snap);
    }
    notifyListeners();
  }

  SavedFolder createSavedFolder(String name) {
    final trimmed = name.trim();
    final folder = SavedFolder(
      id: 'folder-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.isEmpty ? 'New folder' : trimmed,
      createdAt: DateTime.now(),
    );
    savedFolders = [folder, ...savedFolders];
    _saveFolderToCloud(folder);
    notifyListeners();
    return folder;
  }

  void renameSavedFolder(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    SavedFolder? updatedFolder;
    final nextFolders = <SavedFolder>[];
    for (final folder in savedFolders) {
      if (folder.id == id) {
        updatedFolder = folder.copyWith(name: trimmed);
        nextFolders.add(updatedFolder!);
      } else {
        nextFolders.add(folder);
      }
    }
    savedFolders = nextFolders;
    if (updatedFolder != null) _saveFolderToCloud(updatedFolder!);
    notifyListeners();
  }

  void deleteSavedFolder(String id) {
    savedFolders =
        savedFolders.where((folder) => folder.id != id).toList(growable: false);
    _deleteFolderFromCloud(id);
    notifyListeners();
  }

  void addSnapToFolder({required String folderId, required String snapId}) {
    SavedFolder? updatedFolder;
    final nextFolders = <SavedFolder>[];
    for (final folder in savedFolders) {
      if (folder.id == folderId && !folder.snapIds.contains(snapId)) {
        updatedFolder = folder.copyWith(snapIds: [...folder.snapIds, snapId]);
        nextFolders.add(updatedFolder!);
      } else {
        nextFolders.add(folder);
      }
    }
    savedFolders = nextFolders;
    if (updatedFolder != null) _saveFolderToCloud(updatedFolder!);
    notifyListeners();
  }

  void removeSnapFromFolder(
      {required String folderId, required String snapId}) {
    SavedFolder? updatedFolder;
    final nextFolders = <SavedFolder>[];
    for (final folder in savedFolders) {
      if (folder.id == folderId) {
        updatedFolder = folder.copyWith(
            snapIds:
                folder.snapIds.where((itemId) => itemId != snapId).toList());
        nextFolders.add(updatedFolder!);
      } else {
        nextFolders.add(folder);
      }
    }
    savedFolders = nextFolders;
    if (updatedFolder != null) _saveFolderToCloud(updatedFolder!);
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
    _saveSnapsToCloud(_snaps
        .where(
            (snap) => expired.any((expiredSnap) => expiredSnap.id == snap.id))
        .toList());
    notifyListeners();
  }

  void snoozeSnap(String id, Duration duration) {
    final now = DateTime.now();
    _updateSnap(id, (snap) {
      if (snap.isSnoozed) return snap;
      final remaining = snap.remaining(now);
      if (remaining == null || remaining.isNegative) return snap;
      return snap.copyWith(
          expiresAt: null,
          resumeExpiresAt: snap.expiresAt,
          snoozedRemainingSeconds: remaining.inSeconds.clamp(1, 1 << 31),
          status: SnapStatus.active,
          note: 'Snoozed. Tap Unsnooze to resume the timer.');
    });
  }

  void unsnoozeSnap(String id) {
    final now = DateTime.now();
    _updateSnap(id, (snap) {
      final frozen = snap.snoozedRemainingSeconds;
      final originalExpiresAt = snap.resumeExpiresAt;
      if (frozen == null || originalExpiresAt == null) return snap;
      final total = originalExpiresAt.difference(snap.createdAt).inSeconds;
      final elapsed = (total - frozen).clamp(0, total);
      return snap.copyWith(
          createdAt: now.subtract(Duration(seconds: elapsed)),
          expiresAt: now.add(Duration(seconds: frozen)),
          resumeExpiresAt: null,
          snoozedRemainingSeconds: null,
          status: SnapStatus.active,
          note: 'Timer resumed.');
    });
  }

  void _updateSnap(String id, SnapItem Function(SnapItem snap) update) {
    SnapItem? updatedSnap;
    _snaps = [
      for (final snap in _snaps)
        if (snap.id == id) updatedSnap = update(snap) else snap
    ];
    final cloudSnap = updatedSnap;
    if (cloudSnap != null) _saveSnapToCloud(cloudSnap);
    notifyListeners();
  }

  void _saveSnapToCloud(SnapItem snap) {
    _markSyncStatus([snap.id], SnapSyncStatus.syncing);
    unawaited(_saveSnapToCloudAsync(snap));
  }

  void _saveSnapsToCloud(List<SnapItem> snaps) {
    if (snaps.isEmpty) return;
    _markSyncStatus(
        [for (final snap in snaps) snap.id], SnapSyncStatus.syncing);
    unawaited(_saveSnapsToCloudAsync(snaps));
  }

  void _saveFolderToCloud(SavedFolder folder) {
    unawaited(_firestoreRepository.saveFolder(folder).catchError((_) {
      _showCloudSyncError('Folder changes could not sync.');
    }));
  }

  void _deleteFolderFromCloud(String id) {
    unawaited(_firestoreRepository.deleteFolder(id).catchError((_) {
      _showCloudSyncError('Folder deletion could not sync.');
    }));
  }

  void _saveTimerToCloud(ImportTimerOption timer) {
    unawaited(_firestoreRepository.saveTimerPreset(timer).catchError((_) {
      _showCloudSyncError('Timer preset could not sync.');
    }));
  }

  void _deleteSnapFromCloud(SnapItem snap) {
    unawaited(_deleteSnapFromCloudAsync(snap));
  }

  Future<void> _deleteSnapFromCloudAsync(SnapItem snap) async {
    var failed = false;
    try {
      await _storageRepository.deleteSnapImage(snap);
    } catch (_) {
      failed = true;
    }
    try {
      await _firestoreRepository.removeSnap(snap.id);
    } catch (_) {
      failed = true;
    }
    if (failed) {
      _showCloudSyncError('Screenshot could not be permanently deleted.');
    }
  }

  void _saveSettingsToCloud() {
    unawaited(_firestoreRepository
        .saveAppSettings(_settingsMap())
        .catchError((_) {
      _showCloudSyncError('Settings could not sync.');
    }));
  }

  Map<String, Object?> _settingsMap() {
    return {
      'autoDeleteExpired': autoDeleteExpired,
      'urgentAlerts': urgentAlerts,
      'expiryReminders': expiryReminders,
      'cleanupBehavior': cleanupBehavior.name,
      'defaultSaveLocation': defaultSaveLocation.name,
      'appBackground': appBackground.name,
      'notificationLeadMinutes': notificationLeadTime.inMinutes,
      'defaultTimer': defaultTimer.name,
    };
  }

  T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    if (name is! String) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  bool? _bool(Object? value) {
    return value is bool ? value : null;
  }

  int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  Future<void> _saveSnapToCloudAsync(SnapItem snap) async {
    try {
      final cloudSnap = await _storageRepository.uploadSnapImageIfNeeded(snap);
      final syncedSnap = cloudSnap.copyWith(syncStatus: SnapSyncStatus.synced);
      await _firestoreRepository.saveSnap(syncedSnap);
      _replaceLocalSnapAfterCloudUpload(syncedSnap);
    } catch (_) {
      _markSyncStatus([snap.id], SnapSyncStatus.failed);
      _showCloudSyncError('Screenshot changes could not sync.');
    }
  }

  Future<void> _saveSnapsToCloudAsync(List<SnapItem> snaps) async {
    try {
      final cloudSnaps = <SnapItem>[];
      for (final snap in snaps) {
        final cloudSnap =
            await _storageRepository.uploadSnapImageIfNeeded(snap);
        cloudSnaps.add(cloudSnap.copyWith(syncStatus: SnapSyncStatus.synced));
      }
      await _firestoreRepository.saveSnaps(cloudSnaps);
      for (final snap in cloudSnaps) {
        _replaceLocalSnapAfterCloudUpload(snap);
      }
    } catch (_) {
      _markSyncStatus(
          [for (final snap in snaps) snap.id], SnapSyncStatus.failed);
      _showCloudSyncError('Some screenshots could not sync.');
    }
  }

  void _markSyncStatus(List<String> ids, SnapSyncStatus status) {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    var changed = false;
    _snaps = [
      for (final snap in _snaps)
        if (idSet.contains(snap.id) && snap.syncStatus != status)
          _markSnapSync(snap, status, () => changed = true)
        else
          snap
    ];
    if (changed) notifyListeners();
  }

  SnapItem _markSnapSync(
    SnapItem snap,
    SnapSyncStatus status,
    VoidCallback markChanged,
  ) {
    markChanged();
    return snap.copyWith(syncStatus: status);
  }

  void _showCloudSyncError(String message) {
    latestNotice = AppNotice(id: ++_noticeId, message: message);
    notifyListeners();
  }

  void _replaceLocalSnapAfterCloudUpload(SnapItem cloudSnap) {
    if (cloudSnap.imageDownloadUrl == null && cloudSnap.storagePath == null) {
      return;
    }
    var changed = false;
    _snaps = [
      for (final snap in _snaps)
        _cloudUploadReplacement(snap, cloudSnap, () => changed = true)
    ];
    if (changed) notifyListeners();
  }

  SnapItem _cloudUploadReplacement(
    SnapItem current,
    SnapItem cloudSnap,
    VoidCallback markChanged,
  ) {
    if (current.id != cloudSnap.id ||
        (current.imageDownloadUrl == cloudSnap.imageDownloadUrl &&
            current.storagePath == cloudSnap.storagePath)) {
      return current;
    }
    markChanged();
    return cloudSnap;
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
