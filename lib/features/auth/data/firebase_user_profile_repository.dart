import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/user_profile.dart';
import 'user_profile_repository.dart';

/// Firestore-backed [UserProfileRepository] over `users/{uid}`. The owner-only
/// write rule covers [updateNames] (uid() == userId).
class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Stream<UserProfile?> watch(String uid) => _doc(uid).snapshots().map(
        (d) => d.exists ? UserProfile.fromMap(d.data()!, d.id) : null,
      );

  @override
  Future<UserProfile?> fetch(String uid) async {
    final d = await _doc(uid).get();
    return d.exists ? UserProfile.fromMap(d.data()!, d.id) : null;
  }

  @override
  Future<void> updateNames({
    required String uid,
    required String nickname,
    required String displayName,
  }) async {
    // merge so we never clobber email / photoUrl / createdAt on the doc.
    await _doc(uid).set({
      'nickname': nickname.trim(),
      'displayName': displayName.trim(),
    }, SetOptions(merge: true));
  }
}
