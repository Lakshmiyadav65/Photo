import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/gang.dart';
import '../models/gang_data.dart';
import 'gangs_repository.dart';

/// Firestore-backed [GangsRepository]. Gangs are owner-private (the rules gate
/// every operation on `ownerId == uid`), so they're stored as the owner's
/// personal list of member display names — no member uids are needed.
/// `createdAt` is a client [Timestamp] so a freshly-created gang appears in the
/// `orderBy('createdAt')` query immediately.
class FirebaseGangsRepository implements GangsRepository {
  FirebaseGangsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _gangs =>
      _db.collection('gangs');

  @override
  Stream<List<Gang>> watchMyGangs(String uid) {
    return _gangs
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => [
              for (final d in qs.docs) GangData.fromMap(d.data(), d.id).toGang(),
            ]);
  }

  @override
  Future<Gang> createGang({
    required String ownerId,
    required String name,
    required List<String> memberNames,
  }) async {
    final ref = _gangs.doc();
    final now = Timestamp.now();
    await ref.set({
      'name': name,
      'ownerId': ownerId,
      'members': [for (final n in memberNames) {'name': n}],
      'memberCount': memberNames.length,
      'momentCount': 0,
      'muted': false,
      'createdAt': now,
    });
    return Gang(
      id: ref.id,
      name: name,
      members: memberNames,
      createdAt: now.toDate(),
      momentCount: 0,
    );
  }

  @override
  Future<void> setMuted({required String gangId, required bool muted}) {
    return _gangs.doc(gangId).update({'muted': muted});
  }

  @override
  Future<void> deleteGang(String gangId) {
    return _gangs.doc(gangId).delete();
  }
}
