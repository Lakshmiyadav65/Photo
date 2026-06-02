// Gang — a recurring friend group, derived from membership overlap across the
// rolls they've shot together. Frontend-facing subset with mock data until the
// data layer computes these from real moment memberships.

class Gang {
  const Gang({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    required this.momentCount,
    this.momentCodes = const [],
    this.muted = false,
  });

  final String id;
  final String name;

  /// Member display names, host first — drives the avatar stack and members tab.
  final List<String> members;

  /// When the gang first formed — shown as "SINCE JAN 2024".
  final DateTime createdAt;

  /// Total moments shared with this gang (the headline stat). May exceed the
  /// number of [momentCodes] resolvable in the frontend mock.
  final int momentCount;

  /// Codes of moments to surface in the detail list, resolved against the
  /// existing moments mock so tapping opens the real Moment experience.
  final List<String> momentCodes;

  /// Notifications for this gang are muted (per-user preference).
  final bool muted;

  int get peopleCount => members.length;

  /// First member (by convention) is the owner/host.
  String? get hostName => members.isNotEmpty ? members.first : null;

  Gang copyWith({List<String>? members, bool? muted}) => Gang(
        id: id,
        name: name,
        members: members ?? this.members,
        createdAt: createdAt,
        momentCount: momentCount,
        momentCodes: momentCodes,
        muted: muted ?? this.muted,
      );
}
