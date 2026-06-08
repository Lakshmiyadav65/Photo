import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/activity.dart';

/// Read boundary for a roll's activity feed. Writes happen at their atomic
/// sources (the events repo on create/join, the photos repo on upload — each
/// constructs an [ActivityData] and persists it alongside the action), so this
/// repository only needs to stream the feed back for the UI.
abstract class ActivityRepository {
  /// A roll's activity, newest first (capped — the feed is recent history, not
  /// an audit log).
  Stream<List<Activity>> watchActivity(String eventId);
}

/// Overridden in `main.dart` once Firebase is initialised.
final activityRepositoryProvider = Provider<ActivityRepository>(
  (_) => throw UnimplementedError(
    'activityRepositoryProvider must be overridden in main.dart after Firebase init',
  ),
);
