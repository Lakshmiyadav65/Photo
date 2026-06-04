import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_helpers.dart';

/// A gang.roll user — the `users/{uid}` Firestore document.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime? createdAt;

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) =>
      UserProfile(
        uid: uid,
        displayName: (data['displayName'] ?? '') as String,
        email: (data['email'] ?? '') as String,
        photoUrl: data['photoUrl'] as String?,
        createdAt: dateFromFirestore(data['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  UserProfile copyWith({String? displayName, String? photoUrl}) => UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );
}
