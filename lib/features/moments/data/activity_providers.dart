// Activity-feed providers for a roll — the live stream plus the derived unread
// count that drives the gallery bell's dot. Keyed by moment code (resolved to
// the Firestore event id, like the photo providers).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/activity.dart';
import 'activity_seen_store.dart';
import 'mock_moments.dart';
import 'repositories/activity_repository.dart';

/// Live activity for a roll, streamed from Firestore (events/{id}/activity),
/// newest first.
final momentActivityStreamProvider =
    StreamProvider.family<List<Activity>, String>((ref, code) {
  final m = ref.watch(momentByCodeProvider(code));
  if (m == null) return Stream.value(const <Activity>[]);
  return ref.watch(activityRepositoryProvider).watchActivity(m.id);
});

/// Sync view of [momentActivityStreamProvider] (empty while loading).
final momentActivityProvider =
    Provider.family<List<Activity>, String>((ref, code) {
  return ref.watch(momentActivityStreamProvider(code)).value ??
      const <Activity>[];
});

/// How many feed entries the user hasn't seen yet for a roll — drives the bell's
/// unread dot. Excludes the user's own actions (no need to flag what you did) and
/// counts everything when the feed has never been opened.
final unreadActivityProvider = Provider.family<int, String>((ref, code) {
  final m = ref.watch(momentByCodeProvider(code));
  if (m == null) return 0;
  final activities = ref.watch(momentActivityProvider(code));
  final seen = ref.watch(activitySeenProvider)[m.id];
  final myUid = ref.watch(authStateProvider).value?.uid;
  return activities
      .where((a) =>
          a.actorId != myUid && (seen == null || a.at.isAfter(seen)))
      .length;
});
