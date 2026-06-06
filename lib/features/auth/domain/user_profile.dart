import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_helpers.dart';

/// A gang.roll user — the `users/{uid}` Firestore document.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.nickname = '',
    this.photoUrl,
    this.createdAt,
  });

  final String uid;

  /// The user's full/real name — shown on the profile and to other members.
  final String displayName;
  final String email;

  /// Short, friendly name used in the home greeting ("Hi, Lakshmi"). Collected
  /// in the one-time profile setup; falls back to the first word of
  /// [displayName] via [greetingName] when not set yet.
  final String nickname;
  final String? photoUrl;
  final DateTime? createdAt;

  /// What the greeting header shows: the nickname if set, otherwise the first
  /// word of the full name (so an existing user without a nickname still reads
  /// naturally before they complete setup).
  String get greetingName {
    final n = nickname.trim();
    if (n.isNotEmpty) return n;
    final first = displayName.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'there' : first;
  }

  /// True once the user has picked a nickname — drives the one-time setup gate.
  bool get hasNickname => nickname.trim().isNotEmpty;

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) =>
      UserProfile(
        uid: uid,
        displayName: (data['displayName'] ?? '') as String,
        email: (data['email'] ?? '') as String,
        nickname: (data['nickname'] ?? '') as String,
        photoUrl: data['photoUrl'] as String?,
        createdAt: dateFromFirestore(data['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        if (nickname.isNotEmpty) 'nickname': nickname,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  UserProfile copyWith({
    String? displayName,
    String? nickname,
    String? photoUrl,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email,
        nickname: nickname ?? this.nickname,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );
}
