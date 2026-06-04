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
/// Simple-album model: no develop-lock / timer / shot quota — every roll is
/// treated as [RollState.live]. `memberIds` (a flat uid array) is stored
/// alongside `members` so the dashboard query and security rules can use
/// `arrayContains` / `in`.
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
      };

  /// Map to the UI domain type. Host is ordered first (drives the avatar strip).
  Moment toMoment() {
    final ordered = [
      for (final m in members) if (m.isHost) m,
      for (final m in members) if (!m.isHost) m,
    ];
    return Moment(
      id: id,
      title: title,
      code: code,
      state: RollState.live,
      photoCount: photoCount,
      memberCount: members.length,
      members: [for (final m in ordered) m.name],
      vibe: vibe,
      viewCount: viewCount,
      lastActiveAt: lastActiveAt,
      coverUrlOverride: coverUrl,
    );
  }
}
