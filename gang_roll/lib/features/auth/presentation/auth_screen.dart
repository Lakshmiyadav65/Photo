// Auth — sign in / create account in one screen with a mode toggle, matching
// the prototype's login & signup layouts (underline fields + Google).
//
// Frontend behaviour: Sign in → /home; Create account → /auth/profile
// (first-run profile setup). Phase 3 wires Firebase Auth via AuthRepository.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/labeled_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _signUp = false;

  void _toggle() => setState(() => _signUp = !_signUp);

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
                      emphasis: _signUp ? 'first roll' : 'back',
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
                      const LabeledField(label: 'Your name', hint: 'Aarav'),
                      const SizedBox(height: 22),
                      const LabeledField(
                        label: 'Email',
                        hint: 'you@gangroll.app',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 22),
                      const LabeledField(
                        label: 'Password',
                        hint: 'At least 8 characters',
                        obscureText: true,
                      ),
                    ] else ...[
                      const LabeledField(
                        label: 'Email or phone',
                        hint: 'you@gangroll.app',
                      ),
                      const SizedBox(height: 22),
                      const LabeledField(
                        label: 'Password',
                        hint: '••••••••',
                        obscureText: true,
                      ),
                    ],

                    const SizedBox(height: 36),
                    FilledButton(
                      onPressed: () => context.go(_signUp ? '/auth/profile' : '/home'),
                      child: Text(_signUp ? 'Create account' : 'Sign in'),
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
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                        label: const Text('Continue with Google'),
                      ),
                    ],

                    const Spacer(),
                    Center(
                      child: TextButton(
                        onPressed: _toggle,
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
