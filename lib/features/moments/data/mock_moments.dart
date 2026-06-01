// Mock moments — the user's rolls list. Replaced by a Firestore stream in
// Phase 4. The store is now mutable so leave / archive / delete / upload-bumps
// flow through state. The dashboard reads [visibleMomentsProvider] which hides
// archived rolls and sorts by `lastActiveAt` (Recently Active per spec).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../active_moment/data/active_moment_store.dart';
import '../domain/moment.dart';

/// Public read-only view of the seed list — exposed so pure-function callers
/// (e.g. [photosForMoment] / All Photos aggregation) can iterate without
/// reaching into a Riverpod scope.
List<Moment> get mockMoments => List<Moment>.unmodifiable(_seedMoments);

final _seedMoments = <Moment>[
  Moment(
    id: 'gang5k',
    title: "Aarav's birthday",
    code: 'GANG5K',
    state: RollState.live,
    photoCount: 14,
    memberCount: 8,
    vibe: 'wholesome',
    shotsLeft: 3,
    endsAt: DateTime.now().add(const Duration(hours: 2, minutes: 14)),
    members: ['Aarav', 'Meera', 'Rohan', 'Sana', 'Karan', 'Priya', 'Dev', 'Isha'],
    lastActiveAt: DateTime.now().subtract(const Duration(minutes: 18)),
  ),
  Moment(
    id: 'goa204',
    title: 'Goa weekend',
    code: 'GOA204',
    state: RollState.developing,
    photoCount: 32,
    memberCount: 6,
    vibe: 'cinematic',
    endsAt: DateTime.now().add(const Duration(minutes: 12, seconds: 42)),
    members: ['Priya', 'Aarav', 'Karan', 'Meera', 'Rohan', 'Dev'],
    lastActiveAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  Moment(
    id: 'satn8t',
    title: 'Saturday night out',
    code: 'SATN8T',
    state: RollState.developed,
    photoCount: 27,
    memberCount: 5,
    vibe: 'chaotic',
    viewCount: 142,
    developedAt: DateTime.now().subtract(const Duration(days: 3)),
    members: ['Rohan', 'Ananya', 'Karan', 'Meera', 'Dev'],
    lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Moment(
    id: 'hyd909',
    title: 'Hyderabad rooftop',
    code: 'HYD909',
    state: RollState.developed,
    photoCount: 19,
    memberCount: 4,
    vibe: 'soft memories',
    viewCount: 88,
    developedAt: DateTime.now().subtract(const Duration(days: 7)),
    members: ['Ananya', 'Karan', 'Priya', 'Aarav'],
    lastActiveAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
];

/// Mutable moments store. Backed by [_seedMoments] in the frontend mock; the
/// real impl swaps this for a Firestore stream.
class MomentsNotifier extends Notifier<List<Moment>> {
  @override
  List<Moment> build() => List<Moment>.unmodifiable(_seedMoments);

  /// Remove a roll (host-only "Delete moment" — the irreversible variant).
  /// Cascades to the active-moment selection if this roll was the active one.
  void remove(String code) {
    state = [
      for (final m in state) if (m.code != code) m,
    ];
    ref.read(activeMomentCodeProvider.notifier).clearIfMatches(code);
  }

  /// Soft-delete: hides from the dashboard but preserves data ("Archive"). Same
  /// cascade as [remove] for the active moment so uploads don't silently land
  /// in something the user thinks is gone.
  void archive(String code) {
    state = [
      for (final m in state)
        if (m.code == code) m.copyWith(archived: true) else m,
    ];
    ref.read(activeMomentCodeProvider.notifier).clearIfMatches(code);
  }

  /// Drop the current user from a roll (member "Leave"). For the mock this
  /// just removes the moment from the user's list — same shape as [remove],
  /// but distinct in intent (no admin action, no cascade beyond active).
  void leave(String code) {
    state = [
      for (final m in state) if (m.code != code) m,
    ];
    ref.read(activeMomentCodeProvider.notifier).clearIfMatches(code);
  }

  /// Insert a newly-created moment so the dashboard reflects it instantly
  /// (spec: "no manual refresh required"). With Recently Active sort, the new
  /// moment lands at the top because its `lastActiveAt` is the freshest.
  void addMoment(Moment moment) {
    state = [moment, ...state];
  }

  /// Stamp the roll as recently active — the dashboard re-sorts on this. Called
  /// after a successful upload simulation or other activity.
  void bumpActivity(String code) {
    state = [
      for (final m in state)
        if (m.code == code)
          m.copyWith(lastActiveAt: DateTime.now())
        else
          m,
    ];
  }

  /// Add the current user to a roll (member "Join"). No-op when already a
  /// member.
  void addMember(String code, String name) {
    state = [
      for (final m in state)
        if (m.code == code && !m.members.contains(name))
          m.copyWith(
            members: [...m.members, name],
            memberCount: m.memberCount + 1,
            lastActiveAt: DateTime.now(),
          )
        else
          m,
    ];
  }
}

final momentsProvider =
    NotifierProvider<MomentsNotifier, List<Moment>>(MomentsNotifier.new);

/// What the dashboard renders: archived rolls hidden, sorted by most recent
/// activity. Keep this as the consumer-facing list so screens never have to
/// remember to filter/sort themselves.
final visibleMomentsProvider = Provider<List<Moment>>((ref) {
  final all = ref.watch(momentsProvider);
  final visible = [
    for (final m in all) if (!m.archived) m,
  ];
  visible.sort((a, b) => b.sortTime.compareTo(a.sortTime));
  return visible;
});

/// Reactive lookup by code from the *live* moments store — includes moments
/// the user created at runtime (not just the seed). Use this in any screen
/// that resolves a moment by code so newly-created ones open correctly.
final momentByCodeProvider = Provider.family<Moment?, String>((ref, code) {
  final target = code.toLowerCase();
  for (final m in ref.watch(momentsProvider)) {
    if (m.code.toLowerCase() == target || m.id.toLowerCase() == target) {
      return m;
    }
  }
  return null;
});

/// Synchronous, seed-only lookup. Kept for callers that genuinely have no
/// ref (legacy fallbacks, pure-function utilities). Returns null for moments
/// added after app start — prefer [momentByCodeProvider] in widgets.
Moment? mockMomentByCode(String code) {
  for (final m in _seedMoments) {
    if (m.code.toLowerCase() == code.toLowerCase() ||
        m.id.toLowerCase() == code.toLowerCase()) {
      return m;
    }
  }
  return null;
}
