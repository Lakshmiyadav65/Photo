import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/activity.dart';
import '../models/activity_data.dart';
import 'activity_repository.dart';

/// Firestore-backed [ActivityRepository]. Streams `events/{id}/activity` newest
/// first, capped at the most recent [_feedLimit] entries.
class FirebaseActivityRepository implements ActivityRepository {
  FirebaseActivityRepository(this._db);

  final FirebaseFirestore _db;

  static const int _feedLimit = 50;

  @override
  Stream<List<Activity>> watchActivity(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('activity')
        .orderBy('at', descending: true)
        .limit(_feedLimit)
        .snapshots()
        .map((qs) => [
              for (final d in qs.docs) ActivityData.toActivity(d.data(), d.id),
            ]);
  }
}
