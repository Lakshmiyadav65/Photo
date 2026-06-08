// Photo providers for a moment + the cross-moment "All Photos" collection — all
// streamed live from Firestore (events/{id}/photos). (Filename kept so existing
// imports stay valid; nothing here is mock anymore.)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/photo.dart';
import 'mock_moments.dart';
import 'repositories/photos_repository.dart';

/// Live photos for a moment, streamed from Firestore (events/{id}/photos),
/// newest first. Develop-locked: while the roll is Live we return an empty list
/// and never query — the rules would deny the read anyway, and this is what
/// keeps the gallery (and All Photos) hidden until reveal. The stream
/// re-subscribes automatically when [rollDevelopedProvider] flips at develop
/// time. `handleError` absorbs a device-clock-ahead race (client tries a beat
/// before the server allows) so it shows empty/locked instead of an error grid.
final momentPhotosStreamProvider =
    StreamProvider.family<List<Photo>, String>((ref, code) {
  final m = ref.watch(momentByCodeProvider(code));
  if (m == null) return Stream.value(const <Photo>[]);
  if (!ref.watch(rollDevelopedProvider(code))) {
    return Stream.value(const <Photo>[]);
  }
  return ref
      .watch(photosRepositoryProvider)
      .watchPhotos(m.id)
      .handleError((Object _) {});
});

/// Sync view of [momentPhotosStreamProvider] (empty while loading). Kept under
/// the original name so existing consumers (grid, insights, members) are
/// unchanged.
final momentPhotosProvider = Provider.family<List<Photo>, String>((ref, code) {
  return ref.watch(momentPhotosStreamProvider(code)).value ?? const <Photo>[];
});

/// The roll's cover photo — its first uploaded (oldest) shot — or null when the
/// roll has none yet. Drives the real-photo cover takeover on the dashboard.
final coverPhotoProvider = StreamProvider.family<Photo?, String>((ref, code) {
  final m = ref.watch(momentByCodeProvider(code));
  if (m == null) return Stream.value(null);
  // A locked roll shows no photo cover (the card falls back to its gradient).
  if (!ref.watch(rollDevelopedProvider(code))) return Stream.value(null);
  return ref
      .watch(photosRepositoryProvider)
      .watchCoverPhoto(m.id)
      .handleError((Object _) {});
});

/// Every photo across the signed-in user's rolls, newest first — the "All
/// Photos" grid. Aggregates each moment's live photo stream.
final allPhotosProvider = Provider<List<Photo>>((ref) {
  final moments = ref.watch(momentsProvider);
  final all = <Photo>[];
  for (final m in moments) {
    all.addAll(ref.watch(momentPhotosProvider(m.code)));
  }
  all.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  return all;
});
