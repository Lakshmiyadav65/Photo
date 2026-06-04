import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repository.dart';

/// Firebase-backed [AuthRepository]. Wired in `main.dart` once Firebase is
/// initialised. Writes a `users/{uid}` profile doc on sign-up / first sign-in
/// so the rest of the app can resolve display names.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// True only on real mobile targets, where `google_sign_in` has a platform
  /// implementation. Web uses the Firebase popup; desktop has neither.
  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  AuthUser? _map(User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: u.email ?? '',
          displayName: u.displayName,
          photoUrl: u.photoURL,
        );

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    // Self-heal: if a prior sign-up created the auth account but failed to
    // write the profile doc, create it now (no-op if it already exists).
    await _ensureProfile(
      uid: user.uid,
      name: user.displayName ?? 'Friend',
      email: user.email ?? email.trim(),
      photoUrl: user.photoURL,
    );
    return _map(user)!;
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    try {
      await user.updateDisplayName(name.trim());
      await _createProfile(
        uid: user.uid,
        name: name.trim(),
        email: user.email ?? email.trim(),
        photoUrl: user.photoURL,
      );
    } catch (_) {
      // Roll back the half-created account so the email can be reused, then
      // surface the original failure to the UI.
      try {
        await user.delete();
      } catch (_) {/* ignore — original error is what matters */}
      rethrow;
    }
    await user.reload();
    return _map(_auth.currentUser)!;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final UserCredential cred;
    if (kIsWeb) {
      // Web: Firebase drives the OAuth popup (firebase_auth_web is installed).
      cred = await _auth.signInWithPopup(GoogleAuthProvider());
    } else if (_isMobile) {
      // Mobile: google_sign_in v7. Needs the Web OAuth client id as
      // serverClientId to mint a Firebase-usable idToken, plus the app's
      // SHA-1 registered in Firebase. Verified after email/password.
      final signIn = GoogleSignIn.instance;
      await signIn.initialize();
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google sign-in returned no idToken. Set serverClientId '
              '(Web OAuth client) and register the app SHA-1 in Firebase.',
        );
      }
      cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } else {
      // Desktop (Windows/macOS/Linux): neither google_sign_in nor firebase_auth
      // ship a desktop implementation in this build, so both paths would throw
      // an opaque UnimplementedError. Fail with a clear, actionable message.
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message: 'Google sign-in is not supported on desktop in this build. '
            'Use email/password, or run on Android or web.',
      );
    }

    final user = cred.user!;
    await _ensureProfile(
      uid: user.uid,
      name: user.displayName ?? 'Friend',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
    return _map(user)!;
  }

  @override
  Future<void> signOut() async {
    if (_isMobile) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Not signed in via Google, or not initialised — ignore.
      }
    }
    await _auth.signOut();
  }

  /// Unconditional create of `users/{uid}` (sign-up path). Stamps `createdAt`.
  Future<void> _createProfile({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    await _db.collection('users').doc(uid).set({
      'displayName': name,
      'email': email,
      'photoUrl': ?photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Idempotent: writes `users/{uid}` only if it doesn't exist yet. Used by
  /// sign-in self-heal and first Google sign-in so we never clobber a profile
  /// the user later edited.
  Future<void> _ensureProfile({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final doc = _db.collection('users').doc(uid);
    final snap = await doc.get();
    if (snap.exists) return;
    await doc.set({
      'displayName': name,
      'email': email,
      'photoUrl': ?photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
