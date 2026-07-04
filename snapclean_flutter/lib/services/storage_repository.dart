import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../models/snap_item.dart';
import 'auth_repository.dart';

class StorageRepository {
  StorageRepository({
    FirebaseStorage? storage,
    AuthRepository? authRepository,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _authRepository = authRepository ?? AuthRepository();

  final FirebaseStorage _storage;
  final AuthRepository _authRepository;

  String requireUserId([String? uid]) {
    final resolvedUid = uid ?? _authRepository.currentUserId;
    if (resolvedUid == null) {
      throw StateError('A signed-in user is required for Storage access.');
    }
    return resolvedUid;
  }

  Future<SnapItem> uploadSnapImageIfNeeded(SnapItem snap, {String? uid}) async {
    if (snap.imageDownloadUrl != null && snap.storagePath != null) {
      return snap;
    }

    final localPath = snap.imagePath;
    if (localPath == null || localPath.isEmpty) return snap;

    final file = File(localPath);
    if (!file.existsSync()) return snap;

    final userId = requireUserId(uid);
    final storagePath = snap.storagePath ??
        'users/$userId/screenshots/${snap.id.replaceAll('/', '_')}.jpg';
    final ref = _storage.ref(storagePath);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final downloadUrl = await ref.getDownloadURL();

    return snap.copyWith(
      imageDownloadUrl: downloadUrl,
      storagePath: storagePath,
    );
  }

  Future<void> deleteSnapImage(SnapItem snap, {String? uid}) async {
    final path = snap.storagePath;
    if (path == null || path.isEmpty) return;
    requireUserId(uid);
    await _storage.ref(path).delete();
  }
}
