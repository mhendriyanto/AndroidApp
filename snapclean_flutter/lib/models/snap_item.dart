import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MockType { receipt, chat, chart, travel }

enum TimerPreset {
  keep('Keep', 'No timer', Icons.bookmark_rounded, null),
  tenMinutes('10 minutes', 'Very quick', Icons.flash_on_rounded,
      Duration(minutes: 10)),
  thirtyMinutes(
      '30 minutes', 'Quick use', Icons.bolt_rounded, Duration(minutes: 30)),
  oneHour('1 hr', 'Temporary', Icons.schedule_rounded, Duration(hours: 1)),
  tonight(
      'Tonight', 'Later today', Icons.dark_mode_rounded, Duration(hours: 8)),
  tomorrow('Tomorrow', 'Review later', Icons.calendar_today_rounded,
      Duration(days: 1)),
  forever('Forever', 'Save', Icons.all_inclusive_rounded, null);

  final String label;
  final String subtitle;
  final IconData icon;
  final Duration? duration;

  const TimerPreset(this.label, this.subtitle, this.icon, this.duration);

  String get shortLabel {
    return switch (this) {
      TimerPreset.tenMinutes => '10 min',
      TimerPreset.thirtyMinutes => '30 min',
      _ => label,
    };
  }
}

enum SnapStatus { active, kept, deleted }

enum SnapSyncStatus { pending, syncing, synced, failed }

const Object _unset = Object();

class SnapItem {
  final String id;
  final String title;
  final String note;
  final MockType type;
  final String? imagePath;
  final String? imageDownloadUrl;
  final String? storagePath;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? resumeExpiresAt;
  final int? snoozedRemainingSeconds;
  final SnapStatus status;
  final SnapSyncStatus syncStatus;

  const SnapItem({
    required this.id,
    required this.title,
    required this.note,
    required this.type,
    this.imagePath,
    this.imageDownloadUrl,
    this.storagePath,
    required this.createdAt,
    required this.expiresAt,
    this.resumeExpiresAt,
    this.snoozedRemainingSeconds,
    required this.status,
    this.syncStatus = SnapSyncStatus.pending,
  });

  SnapItem copyWith({
    String? title,
    String? note,
    MockType? type,
    String? imagePath,
    String? imageDownloadUrl,
    String? storagePath,
    DateTime? createdAt,
    Object? expiresAt = _unset,
    Object? resumeExpiresAt = _unset,
    Object? snoozedRemainingSeconds = _unset,
    SnapStatus? status,
    SnapSyncStatus? syncStatus,
  }) {
    return SnapItem(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      imageDownloadUrl: imageDownloadUrl ?? this.imageDownloadUrl,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt == _unset ? this.expiresAt : expiresAt as DateTime?,
      resumeExpiresAt: resumeExpiresAt == _unset
          ? this.resumeExpiresAt
          : resumeExpiresAt as DateTime?,
      snoozedRemainingSeconds: snoozedRemainingSeconds == _unset
          ? this.snoozedRemainingSeconds
          : snoozedRemainingSeconds as int?,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  bool get isTimed => expiresAt != null;
  bool get isKept => status == SnapStatus.kept;
  bool get isSnoozed => snoozedRemainingSeconds != null;

  Duration? remaining(DateTime now) {
    final frozen = snoozedRemainingSeconds;
    if (frozen != null) return Duration(seconds: frozen);
    return expiresAt?.difference(now);
  }

  bool expiresSoon(DateTime now) {
    final left = remaining(now);
    return status == SnapStatus.active && left != null && left.inMinutes <= 60;
  }

  String badge(DateTime now) {
    if (status == SnapStatus.deleted) return 'Deleted';
    if (isKept) return 'Keep';
    final left = remaining(now);
    if (left == null) return 'Keep';
    if (left.isNegative) return 'Expired';
    if (left.inSeconds < 600) {
      final seconds = left.inSeconds.clamp(1, 599);
      return '${seconds ~/ 60} min ${seconds % 60}s';
    }
    final displayMinutes = (left.inSeconds / 60).ceil();
    if (displayMinutes < 60) return '$displayMinutes min';
    if (displayMinutes < 24 * 60) {
      final hours = displayMinutes ~/ 60;
      final remainder = displayMinutes % 60;
      if (remainder == 0) return hours == 1 ? '1 hr' : '$hours hr';
      return '$hours hr $remainder min';
    }
    return 'Tomorrow';
  }

  Color progressColor(DateTime now) {
    final left = remaining(now);
    if (left == null) return AppColors.brand;
    if (left.inMinutes <= 15) return AppColors.rose;
    if (left.inMinutes <= 60) return AppColors.amber;
    return AppColors.brand;
  }

  double? progress(DateTime now) {
    if (isSnoozed) {
      final originalExpiresAt = resumeExpiresAt;
      final frozen = snoozedRemainingSeconds;
      if (originalExpiresAt == null || frozen == null) return null;
      final total = originalExpiresAt.difference(createdAt).inSeconds;
      if (total <= 0) return 1;
      final elapsed = total - frozen;
      return (elapsed / total).clamp(0, 1);
    }
    if (expiresAt == null) return null;
    final total = expiresAt!.difference(createdAt).inSeconds;
    if (total <= 0) return 1;
    final elapsed = now.difference(createdAt).inSeconds;
    return (elapsed / total).clamp(0, 1);
  }
}

class ImportDraftItem {
  final MockType type;
  final String? imagePath;
  final String title;
  final int? timerMinutes;
  final String? timerLabel;

  const ImportDraftItem({
    required this.type,
    required this.title,
    this.imagePath,
    this.timerMinutes,
    this.timerLabel,
  });

  ImportDraftItem copyWith({
    MockType? type,
    String? imagePath,
    String? title,
    Object? timerMinutes = _unset,
    Object? timerLabel = _unset,
  }) {
    return ImportDraftItem(
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      timerMinutes:
          timerMinutes == _unset ? this.timerMinutes : timerMinutes as int?,
      timerLabel: timerLabel == _unset ? this.timerLabel : timerLabel as String?,
    );
  }
}

class ImportTimerOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Duration? duration;
  final bool isCustom;

  const ImportTimerOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.duration,
    this.isCustom = false,
  });

  factory ImportTimerOption.fromPreset(TimerPreset preset) {
    return ImportTimerOption(
      id: preset.name,
      label: preset.label,
      subtitle: preset.subtitle,
      icon: preset.icon,
      duration: preset.duration,
    );
  }
}

class SavedFolder {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> snapIds;

  const SavedFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.snapIds = const [],
  });

  SavedFolder copyWith({
    String? name,
    DateTime? createdAt,
    List<String>? snapIds,
  }) {
    return SavedFolder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      snapIds: snapIds ?? this.snapIds,
    );
  }
}

class UserProfile {
  final String name;
  final String email;
  final String username;
  final String? avatarImagePath;

  const UserProfile({
    required this.name,
    required this.email,
    required this.username,
    this.avatarImagePath,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? username,
    String? avatarImagePath,
  }) {
    return UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        username: username ?? this.username,
        avatarImagePath: avatarImagePath ?? this.avatarImagePath);
  }
}
