import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_repository.dart';
import '../../domain/moment.dart';

/// Data boundary for rolls (events). The Firebase-backed implementation is
/// wired in `main.dart`; screens depend only on this interface and the UI
/// [Moment] type, so swapping mocks → Firestore is invisible to them.
abstract class EventsRepository {
  /// The signed-in user's rolls, most-recently-active first.
  Stream<List<Moment>> watchMyEvents(String uid);

  /// A single roll by id (emits null if it's gone or the user isn't a member).
  Stream<Moment?> watchEvent(String eventId);

  /// Create a roll with the given (already-displayed) join code. Returns the
  /// new [Moment]. The caller generates the code so it can be shared before the
  /// roll is persisted. [endsAt] sets the develop-lock deadline — when non-null
  /// the roll is Live (photos locked) until then; null is an open album.
  Future<Moment> createEvent({
    required AuthUser host,
    required String title,
    required String code,
    String? vibe,
    DateTime? endsAt,
  });

  /// Resolve a share code to a lightweight preview WITHOUT joining — backed by
  /// the public `codes/{CODE}` doc (non-members can't read the event itself).
  /// Returns null if the code matches no roll.
  Future<Moment?> lookupByCode(String code);

  /// Join a roll by its share code. Throws [EventNotFoundException] when the
  /// code resolves to nothing.
  Future<Moment> joinByCode({required String code, required AuthUser user});

  /// Remove the user from a roll. This is the app's "delete" — it leaves /
  /// removes the roll from the user's dashboard; it persists for other members.
  Future<void> leaveEvent({required String eventId, required String uid});

  /// Stamp the roll as recently active (e.g. after an upload) so the dashboard
  /// re-sorts it to the top.
  Future<void> bumpActivity(String eventId);

  /// Develop the roll right now — sets `endsAt` to the current time so a Live
  /// roll reveals its photos immediately. Host-only (enforced by the rules).
  Future<void> developNow(String eventId);

  /// Bump the roll's `viewCount` by one (a member opened its gallery). Counted
  /// once per roll per app session by the caller. Deliberately does NOT touch
  /// `lastActiveAt` — viewing shouldn't resurface a roll on the dashboard.
  Future<void> incrementViewCount(String eventId);
}

/// Thrown by [EventsRepository.joinByCode] when no roll matches the code.
class EventNotFoundException implements Exception {
  const EventNotFoundException(this.code);
  final String code;
  @override
  String toString() => 'No roll found for code "$code".';
}

/// Overridden in `main.dart` once Firebase is initialised.
final eventsRepositoryProvider = Provider<EventsRepository>(
  (_) => throw UnimplementedError(
    'eventsRepositoryProvider must be overridden in main.dart after Firebase init',
  ),
);
