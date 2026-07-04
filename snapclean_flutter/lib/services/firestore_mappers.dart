import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/snap_item.dart';

class FirestoreMappers {
  static Map<String, Object?> snapToMap(SnapItem snap) {
    return {
      'title': snap.title,
      'note': snap.note,
      'type': snap.type.name,
      'localImagePath': snap.imagePath,
      'createdAt': Timestamp.fromDate(snap.createdAt),
      'expiresAt': _timestampOrNull(snap.expiresAt),
      'resumeExpiresAt': _timestampOrNull(snap.resumeExpiresAt),
      'status': snap.status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static SnapItem snapFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return SnapItem(
      id: document.id,
      title: _string(data['title'], fallback: 'Untitled screenshot'),
      note: _string(data['note']),
      type: _enumByName(MockType.values, data['type'], MockType.receipt),
      imagePath: _nullableString(data['localImagePath']),
      createdAt: _dateTime(data['createdAt']),
      expiresAt: _nullableDateTime(data['expiresAt']),
      resumeExpiresAt: _nullableDateTime(data['resumeExpiresAt']),
      status: _enumByName(SnapStatus.values, data['status'], SnapStatus.active),
    );
  }

  static Map<String, Object?> folderToMap(SavedFolder folder) {
    return {
      'name': folder.name,
      'createdAt': Timestamp.fromDate(folder.createdAt),
      'snapIds': folder.snapIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static SavedFolder folderFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return SavedFolder(
      id: document.id,
      name: _string(data['name'], fallback: 'New folder'),
      createdAt: _dateTime(data['createdAt']),
      snapIds: _stringList(data['snapIds']),
    );
  }

  static Map<String, Object?> userProfileToMap(UserProfile profile) {
    return {
      'name': profile.name,
      'email': profile.email,
      'username': profile.username,
      'avatarImagePath': profile.avatarImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static UserProfile userProfileFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return UserProfile(
      name: _string(data['name'], fallback: 'SnapClean User'),
      email: _string(data['email']),
      username: _string(data['username']),
      avatarImagePath: _nullableString(data['avatarImagePath']),
    );
  }

  static Map<String, Object?> timerOptionToMap(ImportTimerOption timer) {
    return {
      'label': timer.label,
      'subtitle': timer.subtitle,
      'minutes': timer.duration?.inMinutes,
      'isCustom': timer.isCustom,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Timestamp? _timestampOrNull(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  static DateTime _dateTime(Object? value) {
    return _nullableDateTime(value) ?? DateTime.now();
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    if (name is! String) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value is String) return value;
    return fallback;
  }

  static String? _nullableString(Object? value) {
    if (value is String) return value;
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}
