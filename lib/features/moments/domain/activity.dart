// A single entry in a roll's activity feed — the in-app stand-in for push
// notifications (gang.roll has no server to send them). One doc lives at
// `events/{id}/activity/{autoId}`; members write their own actions, everyone in
// the roll reads them.

/// What happened. [unknown] guards forward-compatibility if a newer client
/// writes a type this build doesn't know.
enum ActivityType { created, joined, uploaded, unknown }

class Activity {
  const Activity({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.at,
  });

  final String id;
  final ActivityType type;

  /// Uid of who did it — lets the UI say "You" and skip self-actions in the
  /// unread count.
  final String actorId;

  /// Display name of who did it.
  final String actorName;

  final DateTime at;
}
