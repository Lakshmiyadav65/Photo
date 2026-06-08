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
    this.hostId = '',
    this.vibe,
    this.shotsLeft,
    this.endsAt,
    this.developedAt,
    this.viewCount = 0,
    this.lastActiveAt,
    this.archived = false,
    this.coverUrlOverride,
  });

  final String id;
  final String title;
  final String code; // 6-char join code, uppercase

  /// Uid of the host — lets the UI gate host-only actions (e.g. "Develop now").
  /// Empty for lightweight previews that don't carry it.
  final String hostId;

  final RollState state;
  final int photoCount;
  final int memberCount;

  /// Member display names, host first — drives the avatar strip.
  final List<String> members;

  /// Optional mood picked at creation ('chaotic', 'nostalgic', 'wholesome',
  /// 'cinematic', 'wild', 'soft memories'). Drives the auto cover image when
  /// the roll has no user photos yet.
  final String? vibe;

  /// Remaining shots for the current user (per-person quota), when [live].
  final int? shotsLeft;

  /// When a [live] roll develops. Null for already-developed rolls.
  final DateTime? endsAt;

  /// When a [developed] roll finished developing (for "3 days ago" labels).
  final DateTime? developedAt;

  final int viewCount;

  /// Most recent meaningful activity (upload, join, …). Drives the dashboard's
  /// "recently active" sort. Falls back to [developedAt]/[endsAt] when null.
  final DateTime? lastActiveAt;

  /// Soft-deleted (archived) rolls are hidden from the dashboard but retained.
  final bool archived;

  /// Manually-selected cover image URL (highest priority over the auto
  /// vibe/photo derivation). Future "Change cover" host action writes here.
  final String? coverUrlOverride;

  bool get isLive => state == RollState.live;
  bool get isDeveloping => state == RollState.developing;
  bool get isDeveloped => state == RollState.developed;

  Duration? get timeLeft {
    if (endsAt == null) return null;
    final d = endsAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  /// Sort key for "recently active" — uses [lastActiveAt] if set, otherwise
  /// the closest natural timestamp the roll has. Returns the epoch for the
  /// empty case so the moment lands at the bottom rather than crashing.
  DateTime get sortTime =>
      lastActiveAt ??
      developedAt ??
      endsAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  /// First member (by convention) is the host.
  String? get hostName => members.isNotEmpty ? members.first : null;

  Moment copyWith({
    int? photoCount,
    int? memberCount,
    List<String>? members,
    DateTime? lastActiveAt,
    bool? archived,
    String? coverUrlOverride,
  }) =>
      Moment(
        id: id,
        title: title,
        code: code,
        hostId: hostId,
        state: state,
        photoCount: photoCount ?? this.photoCount,
        memberCount: memberCount ?? this.memberCount,
        members: members ?? this.members,
        vibe: vibe,
        shotsLeft: shotsLeft,
        endsAt: endsAt,
        developedAt: developedAt,
        viewCount: viewCount,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        archived: archived ?? this.archived,
        coverUrlOverride: coverUrlOverride ?? this.coverUrlOverride,
      );
}
