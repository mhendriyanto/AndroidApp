import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MockType { receipt, chat, chart, travel }

enum TimerPreset {
  keep('Keep', 'No timer', Icons.bookmark_rounded, null),
  thirtyMinutes(
      '30 minutes', 'Quick use', Icons.bolt_rounded, Duration(minutes: 30)),
  oneHour('1 hour', 'Temporary', Icons.schedule_rounded, Duration(hours: 1)),
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
}

enum SnapStatus { active, kept, deleted }

class SnapItem {
  final String id;
  final String title;
  final String note;
  final MockType type;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final SnapStatus status;

  const SnapItem({
    required this.id,
    required this.title,
    required this.note,
    required this.type,
    this.imagePath,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  SnapItem copyWith({
    String? title,
    String? note,
    MockType? type,
    String? imagePath,
    DateTime? createdAt,
    DateTime? expiresAt,
    SnapStatus? status,
  }) {
    return SnapItem(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
    );
  }

  bool get isTimed => expiresAt != null;
  bool get isKept => status == SnapStatus.kept || expiresAt == null;

  Duration? remaining(DateTime now) => expiresAt?.difference(now);

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
      return '${seconds ~/ 60}m ${seconds % 60}s';
    }
    if (left.inMinutes < 60) return '${left.inMinutes.clamp(1, 59)}m';
    if (left.inHours < 24) return '${left.inHours}h';
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

  const ImportDraftItem({
    required this.type,
    required this.title,
    this.imagePath,
  });
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

class UserProfile {
  final String name;
  final String email;
  final String username;

  const UserProfile(
      {required this.name, required this.email, required this.username});

  UserProfile copyWith({String? name, String? email, String? username}) {
    return UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        username: username ?? this.username);
  }
}
