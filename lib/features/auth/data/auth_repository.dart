import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal, provider-agnostic authenticated user. Decouples the app from
/// `firebase_auth`'s `User` so screens and repositories depend only on this.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// The authentication boundary. The Firebase-backed implementation is wired in
/// `main.dart` after `Firebase.initializeApp` (it overrides
/// [authRepositoryProvider]).
abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthUser> signInWithGoogle();

  Future<void> signOut();
}

/// Overridden in `main.dart` once Firebase is initialised. Throws if read
/// before then so misuse fails loudly rather than silently no-ops.
final authRepositoryProvider = Provider<AuthRepository>(
  (_) => throw UnimplementedError(
    'authRepositoryProvider must be overridden in main.dart after Firebase init',
  ),
);

/// Reactive auth state for router redirects (signed-in vs not).
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
