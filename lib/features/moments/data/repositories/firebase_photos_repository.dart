import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/activity.dart';
import '../../domain/photo.dart';
import '../models/activity_data.dart';
import '../models/photo_data.dart';
import 'photos_repository.dart';

/// Firestore-backed [PhotosRepository]. Photo metadata lives at
/// `events/{eventId}/photos/{photoId}`; the bytes are in Cloudflare R2. Each
/// add/delete also bumps the parent event's `photoCount` + `lastActiveAt` in the
/// SAME batch (the rules' member counter-bump allowance covers this).
class FirebasePhotosRepository implements PhotosRepository {
  FirebasePhotosRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _event(String eventId) =>
      _db.collection('events').doc(eventId);

  CollectionReference<Map<String, dynamic>> _photos(String eventId) =>
      _event(eventId).collection('photos');

  CollectionReference<Map<String, dynamic>> _activity(String eventId) =>
      _event(eventId).collection('activity');

  @override
  Stream<List<Photo>> watchPhotos(String eventId) {
    return _photos(eventId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((qs) => [
              for (final d in qs.docs)
                PhotoData.fromMap(d.data(), d.id).toPhoto(eventId: eventId),
            ]);
  }

  @override
  Stream<Photo?> watchCoverPhoto(String eventId) {
    return _photos(eventId)
        .orderBy('uploadedAt') // ascending → first uploaded (oldest) shot
        .limit(1)
        .snapshots()
        .map((qs) => qs.docs.isEmpty
            ? null
            : PhotoData.fromMap(qs.docs.first.data(), qs.docs.first.id)
                .toPhoto(eventId: eventId));
  }

  @override
  Future<void> addPhoto({
    required String eventId,
    required PhotoData photo,
  }) async {
    final batch = _db.batch();
    batch.set(_photos(eventId).doc(photo.id), photo.toMap());
    batch.update(_event(eventId), {
      'photoCount': FieldValue.increment(1),
      'lastActiveAt': Timestamp.now(),
    });
    await batch.commit();

    // Log the upload to the activity feed — best-effort, AFTER the core write
    // (NOT in the batch). The feed is a nicety; a hiccup here (or rules not yet
    // deployed) must never sink the upload. actorId == uploaderId == the signed-
    // in uid, which the activity create rule requires.
    try {
      await _activity(eventId).add(
        ActivityData(
          type: ActivityType.uploaded,
          actorId: photo.uploaderId,
          actorName: photo.uploaderName,
          at: photo.uploadedAt ?? DateTime.now(),
        ).toMap(),
      );
    } catch (_) {
      // Activity is non-critical — swallow.
    }
  }

  @override
  Future<void> toggleFavorite({
    required String eventId,
    required String photoId,
    required bool favorite,
  }) {
    return _photos(eventId).doc(photoId).update({'favorite': favorite});
  }

  @override
  Future<void> deletePhoto({
    required String eventId,
    required String photoId,
  }) async {
    final batch = _db.batch();
    batch.delete(_photos(eventId).doc(photoId));
    batch.update(_event(eventId), {
      'photoCount': FieldValue.increment(-1),
      'lastActiveAt': Timestamp.now(),
    });
    await batch.commit();
  }
}
