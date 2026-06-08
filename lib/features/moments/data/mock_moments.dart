// Moments providers — backed by a live Firestore stream of the signed-in user's
// rolls (events where `memberIds` contains me, most-recently-active first). The
// dashboard reads [visibleMomentsProvider]; lookups use [momentByCodeProvider].
// Mutations (create / join / leave) go through [eventsRepositoryProvider] at the
// call sites. (Filename kept so existing imports stay valid.)

import 'dart:async';

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

/// Roll ids whose gallery view has already been counted this app session, so
/// reopening the same roll doesn't inflate `viewCount`. Mutable set that lives
/// for the ProviderContainer's lifetime (i.e. the whole session).
final countedViewRollsProvider = Provider<Set<String>>((_) => <String>{});

/// A 1-second wall-clock tick. Drives live develop-lock countdowns and the
/// reveal. Only LIVE rolls subscribe (via [rollDevelopedProvider] and the
/// countdown widgets), so developed/open rolls never trigger per-second
/// rebuilds.
final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

/// Whether a roll has developed — i.e. its photos are visible. True for open
/// albums (no `endsAt`) and for rolls past their `endsAt`. While a roll is still
/// Live it watches [tickerProvider], so this flips false→true exactly once at
/// the develop time; that rebuild auto-re-subscribes the photo/cover streams
/// (no manual invalidate). After it develops it stops watching the tick.
final rollDevelopedProvider = Provider.family<bool, String>((ref, code) {
  final m = ref.watch(momentByCodeProvider(code));
  if (m == null || m.endsAt == null) return true;
  if (!DateTime.now().isBefore(m.endsAt!)) return true; // already developed
  ref.watch(tickerProvider); // LIVE only → re-evaluate on each tick
  return !DateTime.now().isBefore(m.endsAt!);
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
