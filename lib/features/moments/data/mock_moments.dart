// Moments providers — backed by a live Firestore stream of the signed-in user's
// rolls (events where `memberIds` contains me, most-recently-active first). The
// dashboard reads [visibleMomentsProvider]; lookups use [momentByCodeProvider].
// Mutations (create / join / leave) go through [eventsRepositoryProvider] at the
// call sites. (Filename kept so existing imports stay valid.)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/moment.dart';
import 'repositories/events_repository.dart';

/// Live stream of the signed-in user's rolls. Emits `[]` when signed out.
final myEventsProvider = StreamProvider<List<Moment>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <Moment>[]);
  return ref.watch(eventsRepositoryProvider).watchMyEvents(user.uid);
});

/// The raw moments list (empty while the stream loads). Kept under the original
/// name so every existing consumer keeps working unchanged.
final momentsProvider = Provider<List<Moment>>((ref) {
  return ref.watch(myEventsProvider).value ?? const <Moment>[];
});

/// What the dashboard renders: archived rolls hidden, most recent first.
final visibleMomentsProvider = Provider<List<Moment>>((ref) {
  final all = ref.watch(momentsProvider);
  final visible = [
    for (final m in all) if (!m.archived) m,
  ];
  visible.sort((a, b) => b.sortTime.compareTo(a.sortTime));
  return visible;
});

/// Reactive lookup by code (or id) from the live store.
final momentByCodeProvider = Provider.family<Moment?, String>((ref, code) {
  final target = code.toLowerCase();
  for (final m in ref.watch(momentsProvider)) {
    if (m.code.toLowerCase() == target || m.id.toLowerCase() == target) {
      return m;
    }
  }
  return null;
});

/// Legacy ref-less seed lookup, retained for a couple of callers. With the mock
/// seed removed it always returns null — prefer [momentByCodeProvider].
Moment? mockMomentByCode(String code) => null;

/// Legacy seed accessor, retained for compatibility — now always empty.
List<Moment> get mockMoments => const <Moment>[];
