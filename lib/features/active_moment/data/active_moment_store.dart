// Active Moment — the single roll the camera shutter and quick uploads target,
// so users pick a destination *once*. Persisted with shared_preferences across
// sessions; cleared automatically when the roll is deleted/archived (cascaded
// from MomentsNotifier).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../moments/data/mock_moments.dart';
import '../../moments/domain/moment.dart';

const _kActiveMomentPrefsKey = 'active_moment_code';

class ActiveMomentNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActiveMomentPrefsKey);
  }

  /// Persist [code] as the new active moment. Reflects immediately in [state]
  /// so listening widgets update without waiting for the disk write.
  Future<void> setActive(String code) async {
    state = AsyncValue.data(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveMomentPrefsKey, code);
  }

  /// Wipe the saved selection — the next upload will prompt the user again.
  Future<void> clear() async {
    state = const AsyncValue.data(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveMomentPrefsKey);
  }

  /// Idempotent clear: drops the selection only when it matches [code]. Called
  /// when the active moment is deleted/archived, so unrelated rolls aren't
  /// touched.
  Future<void> clearIfMatches(String code) async {
    if (state.value == code) {
      await clear();
    }
  }
}

final activeMomentCodeProvider =
    AsyncNotifierProvider<ActiveMomentNotifier, String?>(
  ActiveMomentNotifier.new,
);

/// Resolves the saved code to a live [Moment] from the moments store. Returns
/// null while prefs are loading, when nothing is set, or when the moment no
/// longer exists.
final activeMomentProvider = Provider<Moment?>((ref) {
  final code = ref.watch(activeMomentCodeProvider).value;
  if (code == null) return null;
  for (final m in ref.watch(momentsProvider)) {
    if (m.code == code && !m.archived) return m;
  }
  return null;
});
