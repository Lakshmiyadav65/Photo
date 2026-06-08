import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/activity.dart';

/// The `events/{id}/activity/{autoId}` document — the single source of truth for
/// the activity-feed shape, used by every writer (events repo for create/join,
/// photos repo for upload) and the reader. [at] is a client timestamp (like the
/// roll's `lastActiveAt`) so a freshly-written entry sorts correctly right away
/// instead of reading null under a pending serverTimestamp.
class ActivityData {
  const ActivityData({
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.at,
  });

  final ActivityType type;
  final String actorId;
  final String actorName;
  final DateTime at;

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'actorId': actorId,
        'actorName': actorName,
        'at': Timestamp.fromDate(at),
      };

  static ActivityType typeFrom(String? s) => switch (s) {
        'created' => ActivityType.created,
        'joined' => ActivityType.joined,
        'uploaded' => ActivityType.uploaded,
        _ => ActivityType.unknown,
      };

  static Activity toActivity(Map<String, dynamic> data, String id) => Activity(
        id: id,
        type: typeFrom(data['type'] as String?),
        actorId: (data['actorId'] ?? '') as String,
        actorName: (data['actorName'] ?? '') as String,
        at: dateFromFirestore(data['at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
