// Persists, across sessions, which update version the user has dismissed so the
// floating toast doesn't reappear for a version they've already waved off. A
// newer release (a different version string) clears the suppression naturally —
// the stored value simply won't match the new one.

import 'package:shared_preferences/shared_preferences.dart';

class DismissedUpdateStore {
  const DismissedUpdateStore();

  static const _kDismissedVersionKey = 'dismissed_update_version';

  /// The normalized version the user last dismissed, or null if none.
  Future<String?> dismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDismissedVersionKey);
  }

  /// Remember [version] (normalized, e.g. `1.0.3`) as dismissed.
  Future<void> setDismissedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedVersionKey, version);
  }
}
