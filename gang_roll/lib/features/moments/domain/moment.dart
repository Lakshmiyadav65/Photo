// Moment — the core concept (a shared "roll" of film for one event). Mirrors
// the `events` Firestore doc (schema doc 05); this is the frontend-facing
// subset used by the UI with mock data until Phase 4 wires Firestore.
//
// "roll" is user-facing copy; the type stays `Moment` per the brief naming.

/// The film lifecycle of a moment. Photos stay locked while [live], reveal at
/// once when the timer ends ([developing] → [developed]).
enum RollState { live, developing, developed }

class Moment {
  const Moment({
    required this.id,
    required this.title,
    required this.code,
    required this.state,
    required this.photoCount,
    required this.memberCount,
    required this.members,
    this.shotsLeft,
    this.endsAt,
    this.developedAt,
    this.viewCount = 0,
  });

  final String id;
  final String title;
  final String code; // 6-char join code, uppercase
  final RollState state;
  final int photoCount;
  final int memberCount;

  /// Member display names, host first — drives the avatar strip.
  final List<String> members;

  /// Remaining shots for the current user (per-person quota), when [live].
  final int? shotsLeft;

  /// When a [live] roll develops. Null for already-developed rolls.
  final DateTime? endsAt;

  /// When a [developed] roll finished developing (for "3 days ago" labels).
  final DateTime? developedAt;

  final int viewCount;

  bool get isLive => state == RollState.live;
  bool get isDeveloping => state == RollState.developing;
  bool get isDeveloped => state == RollState.developed;

  Duration? get timeLeft {
    if (endsAt == null) return null;
    final d = endsAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }
}
