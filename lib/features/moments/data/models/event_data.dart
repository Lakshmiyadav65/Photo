import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/moment.dart';

/// One member of an event, denormalised onto the `events/{id}` doc so a
/// dashboard card renders (names + avatar strip) from a single read.
class EventMember {
  const EventMember({
    required this.uid,
    required this.name,
    this.role = 'member',
  });

  final String uid;
  final String name;
  final String role; // 'host' | 'member'

  bool get isHost => role == 'host';

  factory EventMember.fromMap(Map<String, dynamic> data) => EventMember(
        uid: (data['uid'] ?? '') as String,
        name: (data['name'] ?? '') as String,
        role: (data['role'] ?? 'member') as String,
      );

  Map<String, dynamic> toMap() => {'uid': uid, 'name': name, 'role': role};
}

/// The `events/{id}` Firestore document (a roll). Maps to the UI [Moment].
///
/// Develop-lock model: an optional [endsAt] gives a roll a film lifecycle —
/// while `now < endsAt` it's [RollState.live] (photos locked; reads blocked by
/// the rules); at/after [endsAt] it's [RollState.developed] (revealed). A null
/// [endsAt] is an open album: always developed, no lock. `memberIds` (a flat uid
/// array) is stored alongside `members` so the dashboard query and security
/// rules can use `arrayContains` / `in`.
class EventData {
  const EventData({
    required this.id,
    required this.title,
    required this.code,
    required this.hostId,
    required this.hostName,
    required this.members,
    this.vibe,
    this.coverUrl,
    this.photoCount = 0,
    this.viewCount = 0,
    this.createdAt,
    this.lastActiveAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final String code;
  final String hostId;
  final String hostName;
  final List<EventMember> members;
  final String? vibe;
  final String? coverUrl;
  final int photoCount;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  /// When this roll develops (photos reveal). Null = open album, no lock.
  final DateTime? endsAt;

  List<String> get memberIds => [for (final m in members) m.uid];

  factory EventData.fromMap(Map<String, dynamic> data, String id) => EventData(
        id: id,
        title: (data['title'] ?? '') as String,
        code: (data['code'] ?? '') as String,
        hostId: (data['hostId'] ?? '') as String,
        hostName: (data['hostName'] ?? '') as String,
        members: [
          for (final m in (data['members'] as List? ?? const []))
            EventMember.fromMap(Map<String, dynamic>.from(m as Map)),
        ],
        vibe: data['vibe'] as String?,
        coverUrl: data['coverUrl'] as String?,
        photoCount: (data['photoCount'] ?? 0) as int,
        viewCount: (data['viewCount'] ?? 0) as int,
        createdAt: dateFromFirestore(data['createdAt']),
        lastActiveAt: dateFromFirestore(data['lastActiveAt']),
        endsAt: dateFromFirestore(data['endsAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'code': code,
        'hostId': hostId,
        'hostName': hostName,
        'members': [for (final m in members) m.toMap()],
        'memberIds': memberIds,
        'memberCount': members.length,
        'photoCount': photoCount,
        'viewCount': viewCount,
        if (vibe != null) 'vibe': vibe,
        if (coverUrl != null) 'coverUrl': coverUrl,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (lastActiveAt != null)
          'lastActiveAt': Timestamp.fromDate(lastActiveAt!),
        if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
      };

  /// Map to the UI domain type. Host is ordered first (drives the avatar strip).
  ///
  /// Develop state is DERIVED from [endsAt] vs the current time: a roll with no
  /// end time (or whose end time has passed) is [RollState.developed] (visible);
  /// one whose end time is still ahead is [RollState.live] (locked).
  Moment toMoment() {
    final ordered = [
      for (final m in members) if (m.isHost) m,
      for (final m in members) if (!m.isHost) m,
    ];
    final developed = endsAt == null || !DateTime.now().isBefore(endsAt!);
    return Moment(
      id: id,
      title: title,
      code: code,
      hostId: hostId,
      state: developed ? RollState.developed : RollState.live,
      photoCount: photoCount,
      memberCount: members.length,
      members: [for (final m in ordered) m.name],
      vibe: vibe,
      viewCount: viewCount,
      lastActiveAt: lastActiveAt,
      coverUrlOverride: coverUrl,
      endsAt: endsAt,
      developedAt: developed ? endsAt : null,
    );
  }
}
