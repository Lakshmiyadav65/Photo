// Upload abstraction for the Quick Shoot queue.
//
// The backend isn't wired yet (Firebase isn't configured and firebase_storage
// doesn't compile on the current toolchain — see pubspec note). So uploads go
// through [PhotoUploader], an interface with a [MockPhotoUploader] that
// simulates progress today. When the backend lands, drop in a
// FirebasePhotoUploader (sketch at the bottom) — nothing else changes.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_photo.dart';

/// Uploads one photo and returns its remote download URL. Reports 0..1 progress
/// via [onProgress]. Throws on failure (network, auth, etc.).
abstract interface class PhotoUploader {
  Future<String> upload(
    PendingPhoto photo, {
    void Function(double progress)? onProgress,
  });
}

/// Simulated uploader used until Firebase Storage is wired. Ramps progress over
/// ~1.2s and returns a placeholder URL. Swap for the real impl behind the same
/// interface; the controller and UI are unaffected.
class MockPhotoUploader implements PhotoUploader {
  const MockPhotoUploader();

  @override
  Future<String> upload(
    PendingPhoto photo, {
    void Function(double progress)? onProgress,
  }) async {
    // ~400ms per photo (spec) so tiles visibly flip grey → colour one by one.
    onProgress?.call(0.5);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    onProgress?.call(1);
    // Stand-in for the real R2 URL.
    return 'mock://uploaded/${photo.momentId}/${photo.id}.jpg';
  }
}

/// The active uploader. Overridden in `main.dart` with `R2PhotoUploader` once
/// Firebase is initialised; defaults to the simulated uploader otherwise.
final photoUploaderProvider =
    Provider<PhotoUploader>((_) => const MockPhotoUploader());

// ── Real implementation (wire in Phase 5b, after firebase_storage builds) ────
//
// class FirebasePhotoUploader implements PhotoUploader {
//   @override
//   Future<String> upload(PendingPhoto photo, {onProgress}) async {
//     // 1. Compress to AppConstants.maxPhotoDimensionPx @ photoJpegQuality
//     //    (flutter_image_compress) — compression happens HERE, not at capture.
//     // 2. ref = FirebaseStorage.instance
//     //        .ref('events/${photo.momentId}/photos/${photo.id}.jpg');
//     // 3. task = ref.putFile(File(compressedPath));
//     //    task.snapshotEvents.listen((s) =>
//     //        onProgress?.call(s.bytesTransferred / s.totalBytes));
//     // 4. await task; final url = await ref.getDownloadURL();
//     // 5. Write events/{momentId}/photos/{photoId} doc in Firestore.
//     // 6. return url;
//   }
// }
