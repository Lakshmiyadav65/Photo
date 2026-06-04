// Gangs providers — backed by a live Firestore stream of the signed-in user's
// gangs (owner-private). The Search tab reads [gangsProvider]; the Create Gang
// member pool comes from [availableMembersProvider] (people in your rolls).
// Mutations go through [gangsRepositoryProvider] at the call sites. (Filename
// kept so existing imports stay valid.)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../moments/data/mock_moments.dart';
import '../domain/gang.dart';
import 'repositories/gangs_repository.dart';

/// Live stream of the signed-in user's gangs. Emits `[]` when signed out.
final myGangsProvider = StreamProvider<List<Gang>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <Gang>[]);
  return ref.watch(gangsRepositoryProvider).watchMyGangs(user.uid);
});

/// The gangs list (empty while the stream loads). Kept under the original name.
final gangsProvider = Provider<List<Gang>>((ref) {
  return ref.watch(myGangsProvider).value ?? const <Gang>[];
});

final gangByIdProvider = Provider.family<Gang?, String>((ref, id) {
  for (final g in ref.watch(gangsProvider)) {
    if (g.id == id) return g;
  }
  return null;
});

/// People the user has shared moments with — the pool the Create Gang member
/// selector draws from. Excludes the current user (they're always the owner).
/// Spec: members can only be picked from people already in the user's moments.
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
