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

  /// Create a roll; generates a unique join code. Returns the new [Moment].
  Future<Moment> createEvent({
    required AuthUser host,
    required String title,
    String? vibe,
  });

  /// Join a roll by its share code. Throws [EventNotFoundException] when the
  /// code resolves to nothing.
  Future<Moment> joinByCode({required String code, required AuthUser user});

  /// Remove the user from a roll. This is the app's "delete" — it leaves /
  /// removes the roll from the user's dashboard; it persists for other members.
  Future<void> leaveEvent({required String eventId, required String uid});

  /// Stamp the roll as recently active (e.g. after an upload) so the dashboard
  /// re-sorts it to the top.
  Future<void> bumpActivity(String eventId);
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
