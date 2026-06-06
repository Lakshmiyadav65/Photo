import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';
import 'auth_repository.dart';

/// Data boundary for the signed-in user's `users/{uid}` profile doc. The
/// Firebase-backed implementation is wired in `main.dart`; screens depend only
/// on this interface and the [UserProfile] type.
abstract class UserProfileRepository {
  /// Live profile for [uid] (emits null until the doc exists / on error).
  Stream<UserProfile?> watch(String uid);

  /// One-shot read — used to decide the post-auth route (setup vs home) without
  /// waiting on the live stream.
  Future<UserProfile?> fetch(String uid);

  /// Persist the names chosen in the one-time setup. [nickname] drives the
  /// greeting; [displayName] is the full/real name shown elsewhere.
  Future<void> updateNames({
    required String uid,
    required String nickname,
    required String displayName,
  });
}

/// Overridden in `main.dart` once Firebase is initialised.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (_) => throw UnimplementedError(
    'userProfileRepositoryProvider must be overridden in main.dart after '
    'Firebase init',
  ),
);

/// Live profile of the currently signed-in user (null when signed out / still
/// loading). The single source for the greeting nickname and the profile
/// screen identity.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watch(user.uid);
});
