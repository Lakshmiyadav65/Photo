import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/gang.dart';

/// A member of a gang (denormalised name for display).
class GangMember {
  const GangMember({required this.uid, required this.name});

  final String uid;
  final String name;

  factory GangMember.fromMap(Map<String, dynamic> data) => GangMember(
        uid: (data['uid'] ?? '') as String,
        name: (data['name'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {'uid': uid, 'name': name};
}

/// The `gangs/{id}` document — a personal, owner-private grouping of members
/// the user has shot with. Maps to the UI [Gang].
class GangData {
  const GangData({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    this.momentCount = 0,
    this.momentCodes = const [],
    this.muted = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<GangMember> members;
  final int momentCount;
  final List<String> momentCodes;
  final bool muted;
  final DateTime? createdAt;

  List<String> get memberIds => [for (final m in members) m.uid];

  factory GangData.fromMap(Map<String, dynamic> data, String id) => GangData(
        id: id,
        name: (data['name'] ?? '') as String,
        ownerId: (data['ownerId'] ?? '') as String,
        members: [
          for (final m in (data['members'] as List? ?? const []))
            GangMember.fromMap(Map<String, dynamic>.from(m as Map)),
        ],
        momentCount: (data['momentCount'] ?? 0) as int,
        momentCodes: [
          for (final c in (data['momentCodes'] as List? ?? const []))
            c as String,
        ],
        muted: (data['muted'] ?? false) as bool,
        createdAt: dateFromFirestore(data['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'members': [for (final m in members) m.toMap()],
        'memberIds': memberIds,
        'momentCount': momentCount,
        'momentCodes': momentCodes,
        'muted': muted,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  Gang toGang() => Gang(
        id: id,
        name: name,
        members: [for (final m in members) m.name],
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        momentCount: momentCount,
        momentCodes: momentCodes,
        muted: muted,
      );
}
