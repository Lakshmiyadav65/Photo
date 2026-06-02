// Riverpod wiring for the Quick Shoot queue. The repository is a provider so
// it (and its in-memory revision stream) is a single shared instance, and the
// per-moment pending list is a StreamProvider.family the UI watches.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_photo.dart';
import '../repositories/photo_queue_repository.dart';

final photoQueueRepositoryProvider =
    Provider<PhotoQueueRepository>((_) => PhotoQueueRepository());

/// Outstanding (pending / uploading / failed) photos for a moment, newest write
/// re-querying via the repository's revision stream.
final pendingPhotosProvider =
    StreamProvider.family<List<PendingPhoto>, String>((ref, momentId) {
  return ref
      .watch(photoQueueRepositoryProvider)
      .watchPendingForMoment(momentId);
});

/// Convenience count for the banner / badges. 0 while loading.
final pendingCountProvider = Provider.family<int, String>((ref, momentId) {
  return ref.watch(pendingPhotosProvider(momentId)).value?.length ?? 0;
});

/// Every non-cancelled local photo (pending → uploaded) for a moment, newest
/// first — drives the moment grid where greyed pending tiles turn full colour
/// as they upload.
final localPhotosProvider =
    StreamProvider.family<List<PendingPhoto>, String>((ref, momentId) {
  return ref.watch(photoQueueRepositoryProvider).watchAllForMoment(momentId);
});
