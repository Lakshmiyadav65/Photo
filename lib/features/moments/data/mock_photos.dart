// Deterministic mock photos for a moment, derived from its members + count.
// Uploaders are weighted so the host shoots the most (drives "most prolific"
// in insights), and round-robin interleaved so the grid looks naturally mixed.
// Replaced by an events/<code>/photos stream in Phase 5.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/moment.dart';
import '../domain/photo.dart';
import 'mock_moments.dart';

List<Photo> photosForMoment(Moment m) {
  if (m.members.isEmpty || m.photoCount == 0) return const [];

  // Heavier weight for earlier members (host first) → a clear contributor order.
  final weights = [for (var i = 0; i < m.memberCount; i++) m.memberCount - i + 1];
  final totalWeight = weights.fold<int>(0, (a, b) => a + b);

  final counts = [
    for (final w in weights) (m.photoCount * w / totalWeight).floor(),
  ];
  var assigned = counts.fold<int>(0, (a, b) => a + b);
  var i = 0;
  while (assigned < m.photoCount) {
    counts[i % m.memberCount]++;
    assigned++;
    i++;
  }

  // Round-robin interleave so consecutive grid tiles aren't the same person.
  final remaining = [...counts];
  final photos = <Photo>[];
  var index = 0;
  final now = DateTime.now();
  while (photos.length < m.photoCount) {
    for (var mi = 0; mi < m.memberCount; mi++) {
      if (remaining[mi] <= 0) continue;
      remaining[mi]--;
      photos.add(Photo(
        id: '${m.code}_$index',
        uploader: m.members[mi % m.members.length],
        uploadedAt: now.subtract(Duration(hours: index * 4 + 1)),
        favorite: index % 5 == 0,
      ));
      index++;
      if (photos.length >= m.photoCount) break;
    }
  }
  return photos;
}

/// Mock downloads + duration for the insights sheet (no backend yet).
int mockDownloads(Moment m) => m.photoCount * m.memberCount * 4 + m.viewCount;

int mockDurationDays(Moment m) => (m.photoCount / 3).ceil().clamp(1, 60);

final momentPhotosProvider = Provider.family<List<Photo>, String>((ref, code) {
  // Live lookup so freshly-created moments (not in the seed) still resolve.
  final m = ref.watch(momentByCodeProvider(code));
  return m == null ? const [] : photosForMoment(m);
});

/// Every photo across all rolls, newest first — the "All Photos" collection.
List<Photo> allPhotos() {
  final photos = [for (final m in mockMoments) ...photosForMoment(m)];
  photos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  return photos;
}

final allPhotosProvider = Provider<List<Photo>>((ref) => allPhotos());

/// Resolves a photo-viewer source key into its collection. `'all'` is the
/// All Photos mosaic; any other value is treated as a moment code. New sources
/// (favorites, a gang, search) slot in here without touching the viewer.
List<Photo> photosForSource(String source) {
  if (source == 'all') return allPhotos();
  final m = mockMomentByCode(source);
  return m == null ? const [] : photosForMoment(m);
}

/// The photo a moment uses as its cover — the first uploaded image — or null
/// when the roll has none yet (callers fall back to a default gradient). Covers
/// are derived automatically; users no longer pick one during creation.
String? momentCoverPhotoId(Moment m) {
  final photos = photosForMoment(m);
  return photos.isEmpty ? null : photos.first.id;
}
