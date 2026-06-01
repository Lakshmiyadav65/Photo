// Mock gangs — replaced by a derived stream (membership overlap across
// moments) once the data layer lands. The store is mutable so newly created
// gangs surface on the Gangs screen instantly (spec: "no refresh required").

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moments/data/mock_moments.dart';
import '../domain/gang.dart';

final _seedGangs = <Gang>[
  Gang(
    id: 'college-crew',
    name: 'College crew',
    members: ['Aarav', 'Meera', 'Rohan', 'Karan', 'Priya', 'Dev'],
    createdAt: DateTime(2024, 1, 12),
    momentCount: 12,
    momentCodes: ['GOA204', 'GANG5K'],
  ),
  Gang(
    id: 'trip-squad',
    name: 'Trip squad',
    members: ['Priya', 'Aarav', 'Karan', 'Meera'],
    createdAt: DateTime(2024, 3, 4),
    momentCount: 5,
    momentCodes: ['GOA204', 'HYD909'],
  ),
  Gang(
    id: 'family',
    name: 'Family',
    members: ['Aarav', 'Meera', 'Isha', 'Sana', 'Dev', 'Ananya', 'Rohan'],
    createdAt: DateTime(2023, 6, 20),
    momentCount: 23,
    momentCodes: ['SATN8T', 'HYD909'],
  ),
  Gang(
    id: 'supper-club',
    name: 'Supper club',
    members: ['Rohan', 'Ananya', 'Karan', 'Meera', 'Dev'],
    createdAt: DateTime(2024, 9, 2),
    momentCount: 8,
    momentCodes: ['SATN8T'],
  ),
];

class GangsNotifier extends Notifier<List<Gang>> {
  @override
  List<Gang> build() => List<Gang>.unmodifiable(_seedGangs);

  /// Insert a newly-created gang at the top so it appears on the Gangs screen
  /// immediately after Save (spec: "no refresh required").
  void addGang(Gang gang) {
    state = [gang, ...state];
  }
}

final gangsProvider =
    NotifierProvider<GangsNotifier, List<Gang>>(GangsNotifier.new);

final gangByIdProvider = Provider.family<Gang?, String>((ref, id) {
  for (final g in ref.watch(gangsProvider)) {
    if (g.id == id) return g;
  }
  return null;
});

/// People the user has shared moments with — the pool the Create Gang member
/// selector draws from. Excludes the current user (they're always the owner).
/// Spec: "Members can only be selected from people already present in Moments
/// the user belongs to."
final availableMembersProvider = Provider.family<List<String>, String>((
  ref,
  currentUser,
) {
  final seen = <String>{};
  for (final m in ref.watch(momentsProvider)) {
    if (m.archived) continue;
    if (!m.members.contains(currentUser)) continue;
    for (final name in m.members) {
      if (name != currentUser) seen.add(name);
    }
  }
  final list = seen.toList()..sort();
  return list;
});
