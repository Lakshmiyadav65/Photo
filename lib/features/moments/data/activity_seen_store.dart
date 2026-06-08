// Tracks, per roll, when the user last opened its activity feed — so the bell
// can show an unread dot and stop showing it once they've looked. Persisted to
// shared_preferences (survives restarts) and mirrored in memory for reactive
// badges.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitySeenStore {
  const ActivitySeenStore();

  static const _prefix = 'activity_seen_';

  /// Every roll's last-seen timestamp, keyed by event id.
  Future<Map<String, DateTime>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, DateTime>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final ms = prefs.getInt(key);
      if (ms != null) {
        out[key.substring(_prefix.length)] =
            DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    return out;
  }

  Future<void> save(String eventId, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$eventId', at.millisecondsSinceEpoch);
  }
}

/// In-memory "last opened the feed" timestamps per roll, hydrated from disk and
/// updated on [markSeen]. Watched by [unreadActivityProvider] so badges update
/// the instant the user opens a feed.
class ActivitySeenNotifier extends Notifier<Map<String, DateTime>> {
  final _store = const ActivitySeenStore();

  @override
  Map<String, DateTime> build() {
    // Start empty, then hydrate from disk; in-memory (newer) values win on merge.
    _store.loadAll().then((loaded) {
      if (loaded.isNotEmpty) state = {...loaded, ...state};
    });
    return const {};
  }

  /// Mark a roll's feed as seen as of now.
  void markSeen(String eventId) {
    final now = DateTime.now();
    state = {...state, eventId: now};
    _store.save(eventId, now);
  }
}

final activitySeenProvider =
    NotifierProvider<ActivitySeenNotifier, Map<String, DateTime>>(
  ActivitySeenNotifier.new,
);
