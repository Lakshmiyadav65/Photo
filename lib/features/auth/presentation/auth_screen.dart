// Auth — sign in / create account in one screen with a mode toggle, matching
// the prototype's login & signup layouts (underline fields + Google).
//
// Wired to AuthRepository (Firebase): Sign in / Create account / Continue with
// Google call the repo; on success we route to /home or /permissions. Errors
// surface as a snackbar with a friendly message.

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../onboarding/data/permissions_store.dart';
import '../data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _signUp = false;
  bool _busy = false;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => _signUp = !_signUp);

  /// After a successful sign-in / sign-up: first-time users land on the
  /// Permissions screen; returning users go straight to /home.
  void _afterAuth() {
    final completed = ref.read(permissionsProvider).value?.completed ?? false;
    context.go(completed ? '/home' : '/permissions');
  }

  /// Runs an auth action with busy-state + error handling, navigating on success.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _afterAuth();
    } on FirebaseAuthException catch (e) {
      _showError(_messageFor(e));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() {
    final auth = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    final password = _password.text;
    if (_signUp) {
      return _run(() => auth.signUpWithEmail(
            name: _name.text.trim(),
            email: email,
            password: password,
          ));
    }
    return _run(() => auth.signInWithEmail(email: email, password: password));
  }

  Future<void> _google() {
    final auth = ref.read(authRepositoryProvider);
    return _run(auth.signInWithGoogle);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'email-already-in-use':
        return 'That email is already registered — try signing in.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'unsupported-platform':
      case 'missing-id-token':
        return e.message ?? 'Google sign-in is unavailable here.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 64),
                    HeroTitle(
                      before: _signUp ? 'Start your ' : 'Welcome ',
                      emphasis: _signUp ? 'first moment' : 'back',
                      fontSize: 38,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _signUp
                          ? 'Takes thirty seconds, max.'
                          : 'Pick up where you left off.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),

                    // Fields
                    if (_signUp) ...[
                      LabeledField(
                        label: 'Your name',
                        hint: 'Aarav',
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 22),
                      LabeledField(
                        label: 'Email',
                        hint: 'you@gangroll.app',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 22),
                      LabeledField(
                        label: 'Password',
                        hint: 'At least 6 characters',
                        controller: _password,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                      ),
                    ] else ...[
                      LabeledField(
                        label: 'Email',
                        hint: 'you@gangroll.app',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 22),
                      LabeledField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _password,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                      ),
                    ],

                    const SizedBox(height: 36),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_signUp ? 'Create account' : 'Sign in'),
                    ),

                    if (!_signUp) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: AppText.label()),
                          ),
                          Expanded(child: Divider(color: AppTheme.line)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _google,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                        label: const Text('Continue with Google'),
                      ),
                    ],

                    const Spacer(),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : _toggle,
                        child: Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                  text: _signUp
                                      ? 'Already in?  '
                                      : 'New here?  '),
                              TextSpan(
                                text: _signUp
                                    ? 'Sign in'
                                    : 'Create an account',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.coral,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
