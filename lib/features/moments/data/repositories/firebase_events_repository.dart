import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/data/auth_repository.dart';
import '../../domain/moment.dart';
import '../models/event_data.dart';
import 'events_repository.dart';

/// Firestore-backed [EventsRepository]. Writes are shaped to satisfy the
/// hardened `firestore.rules`:
/// - create: host is the sole member, counters zeroed, then the code doc.
/// - join: `arrayUnion` self (no prior read — non-members can't read the event).
/// - leave: transactional `arrayRemove` of self.
/// - `lastActiveAt` is a client [Timestamp] so freshly-written docs appear in
///   the dashboard query immediately (a pending serverTimestamp reads null and
///   would drop the doc from the `orderBy('lastActiveAt')` query).
class FirebaseEventsRepository implements EventsRepository {
  FirebaseEventsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');
  CollectionReference<Map<String, dynamic>> get _codes =>
      _db.collection('codes');

  String _nameOf(AuthUser u) =>
      (u.displayName != null && u.displayName!.trim().isNotEmpty)
          ? u.displayName!.trim()
          : u.email.split('@').first;

  @override
  Stream<List<Moment>> watchMyEvents(String uid) {
    return _events
        .where('memberIds', arrayContains: uid)
        .orderBy('lastActiveAt', descending: true)
        .snapshots()
        .map((qs) => [
              for (final d in qs.docs)
                EventData.fromMap(d.data(), d.id).toMoment(),
            ]);
  }

  @override
  Stream<Moment?> watchEvent(String eventId) {
    return _events.doc(eventId).snapshots().map(
          (d) =>
              d.exists ? EventData.fromMap(d.data()!, d.id).toMoment() : null,
        );
  }

  @override
  Future<Moment> createEvent({
    required AuthUser host,
    required String title,
    required String code,
    String? vibe,
  }) async {
    final hostName = _nameOf(host);
    final upper = code.toUpperCase();
    final now = Timestamp.now();
    final eventRef = _events.doc(); // auto-id

    // 1. Event first (host = sole member) — satisfies the create rule.
    await eventRef.set({
      'title': title,
      'code': upper,
      'hostId': host.uid,
      'hostName': hostName,
      'members': [
        {'uid': host.uid, 'name': hostName, 'role': 'host'},
      ],
      'memberIds': [host.uid],
      'memberCount': 1,
      'photoCount': 0,
      'viewCount': 0,
      'vibe': ?vibe,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': now,
    });

    // 2. Code doc (event-first ordering required by the codes rule). Denormalise
    //    title + hostName so the join screen can preview without reading the
    //    event (non-members can't).
    await _codes.doc(upper).set({
      'eventId': eventRef.id,
      'title': title,
      'hostName': hostName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Moment(
      id: eventRef.id,
      title: title,
      code: upper,
      state: RollState.live,
      photoCount: 0,
      memberCount: 1,
      members: [hostName],
      vibe: vibe,
      lastActiveAt: now.toDate(),
    );
  }

  @override
  Future<Moment?> lookupByCode(String code) async {
    final snap = await _codes.doc(code.toUpperCase()).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    return Moment(
      id: (data['eventId'] ?? '') as String,
      title: (data['title'] ?? 'Moment') as String,
      code: code.toUpperCase(),
      state: RollState.live,
      photoCount: 0,
      memberCount: 1,
      members: [(data['hostName'] ?? 'Host') as String],
    );
  }

  @override
  Future<Moment> joinByCode({
    required String code,
    required AuthUser user,
  }) async {
    final upper = code.toUpperCase();
    final codeSnap = await _codes.doc(upper).get();
    if (!codeSnap.exists) throw EventNotFoundException(upper);
    final eventId = (codeSnap.data()!['eventId'] ?? '') as String;

    // arrayUnion — no read of the event needed (a non-member can't read it).
    await _events.doc(eventId).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'members': FieldValue.arrayUnion([
        {'uid': user.uid, 'name': _nameOf(user), 'role': 'member'},
      ]),
      'memberCount': FieldValue.increment(1),
      'lastActiveAt': Timestamp.now(),
    });

    // Now a member — safe to read it back.
    final snap = await _events.doc(eventId).get();
    return EventData.fromMap(snap.data()!, snap.id).toMoment();
  }

  @override
  Future<void> leaveEvent({
    required String eventId,
    required String uid,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _events.doc(eventId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final members = (snap.data()!['members'] as List?) ?? const [];
      Map<String, dynamic>? mine;
      for (final m in members) {
        if (m is Map && m['uid'] == uid) {
          mine = Map<String, dynamic>.from(m);
          break;
        }
      }
      tx.update(ref, {
        'memberIds': FieldValue.arrayRemove([uid]),
        if (mine != null) 'members': FieldValue.arrayRemove([mine]),
        'memberCount': FieldValue.increment(-1),
        'lastActiveAt': Timestamp.now(),
      });
    });
  }

  @override
  Future<void> bumpActivity(String eventId) async {
    await _events.doc(eventId).update({'lastActiveAt': Timestamp.now()});
  }
}
