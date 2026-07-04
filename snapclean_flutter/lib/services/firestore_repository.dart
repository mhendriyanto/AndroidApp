import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/snap_item.dart';
import 'auth_repository.dart';
import 'firebase_collections.dart';
import 'firestore_mappers.dart';

class FirestoreRepository {
  FirestoreRepository({
    FirebaseFirestore? firestore,
    AuthRepository? authRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authRepository = authRepository ?? AuthRepository();

  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  String requireUserId([String? uid]) {
    final resolvedUid = uid ?? _authRepository.currentUserId;
    if (resolvedUid == null) {
      throw StateError('A signed-in user is required for Firestore access.');
    }
    return resolvedUid;
  }

  DocumentReference<Map<String, dynamic>> userRef(String uid) {
    return _firestore.doc(FirestorePaths.user(uid));
  }

  DocumentReference<Map<String, dynamic>> usernameRef(String username) {
    return _firestore.doc(FirestorePaths.username(normalizeUsername(username)));
  }

  CollectionReference<Map<String, dynamic>> screenshotsRef(String uid) {
    return _firestore.collection(FirestorePaths.screenshots(uid));
  }

  CollectionReference<Map<String, dynamic>> foldersRef(String uid) {
    return _firestore.collection(FirestorePaths.folders(uid));
  }

  DocumentReference<Map<String, dynamic>> appSettingsRef(String uid) {
    return _firestore.doc(FirestorePaths.appSettings(uid));
  }

  CollectionReference<Map<String, dynamic>> timerPresetsRef(String uid) {
    return _firestore.collection(FirestorePaths.timerPresets(uid));
  }

  CollectionReference<Map<String, dynamic>> activityRef(String uid) {
    return _firestore.collection(FirestorePaths.activity(uid));
  }

  Future<void> upsertUserProfile(UserProfile profile, {String? uid}) {
    final userId = requireUserId(uid);
    return userRef(userId).set(
      {
        ...FirestoreMappers.userProfileToMap(profile),
        'usernameLower': normalizeUsername(profile.username),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> reserveUsername({
    required String username,
    required String email,
    String? uid,
  }) {
    final userId = requireUserId(uid);
    return usernameRef(username).set({
      'uid': userId,
      'email': email.trim(),
      'username': username.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> emailForUsername(String username) async {
    final document = await usernameRef(username).get();
    final data = document.data();
    final email = data?['email'];
    return email is String ? email : null;
  }

  Stream<UserProfile?> watchUserProfile({String? uid}) {
    final userId = requireUserId(uid);
    return userRef(userId).snapshots().map((document) {
      if (!document.exists) return null;
      return FirestoreMappers.userProfileFromDocument(document);
    });
  }

  Future<UserProfile?> getUserProfile({String? uid}) async {
    final userId = requireUserId(uid);
    final document = await userRef(userId).get();
    if (!document.exists) return null;
    return FirestoreMappers.userProfileFromDocument(document);
  }

  Future<void> saveSnap(SnapItem snap, {String? uid}) {
    final userId = requireUserId(uid);
    return screenshotsRef(userId).doc(snap.id).set(
      {
        ...FirestoreMappers.snapToMap(snap),
        'createdAt': Timestamp.fromDate(snap.createdAt),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveSnaps(List<SnapItem> snaps, {String? uid}) async {
    if (snaps.isEmpty) return;
    final userId = requireUserId(uid);
    final batch = _firestore.batch();
    for (final snap in snaps) {
      batch.set(
        screenshotsRef(userId).doc(snap.id),
        FirestoreMappers.snapToMap(snap),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Stream<List<SnapItem>> watchSnaps({String? uid}) {
    final userId = requireUserId(uid);
    return screenshotsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(FirestoreMappers.snapFromDocument).toList());
  }

  Future<void> markSnapDeleted(String snapId, {String? uid}) {
    final userId = requireUserId(uid);
    return screenshotsRef(userId).doc(snapId).set(
      {
        'status': SnapStatus.deleted.name,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeSnap(String snapId, {String? uid}) {
    final userId = requireUserId(uid);
    return screenshotsRef(userId).doc(snapId).delete();
  }

  Future<void> saveFolder(SavedFolder folder, {String? uid}) {
    final userId = requireUserId(uid);
    return foldersRef(userId).doc(folder.id).set(
          FirestoreMappers.folderToMap(folder),
          SetOptions(merge: true),
        );
  }

  Stream<List<SavedFolder>> watchFolders({String? uid}) {
    final userId = requireUserId(uid);
    return foldersRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(FirestoreMappers.folderFromDocument).toList());
  }

  Future<void> deleteFolder(String folderId, {String? uid}) {
    final userId = requireUserId(uid);
    return foldersRef(userId).doc(folderId).delete();
  }

  Future<void> saveAppSettings(
    Map<String, Object?> settings, {
    String? uid,
  }) {
    final userId = requireUserId(uid);
    return appSettingsRef(userId).set(
      {
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveTimerPreset(ImportTimerOption timer, {String? uid}) {
    final userId = requireUserId(uid);
    return timerPresetsRef(userId).doc(timer.id).set(
          FirestoreMappers.timerOptionToMap(timer),
          SetOptions(merge: true),
        );
  }

  Future<void> logActivity(
    String type,
    Map<String, Object?> payload, {
    String? uid,
  }) {
    final userId = requireUserId(uid);
    return activityRef(userId).add({
      'type': type,
      'payload': payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }
}
