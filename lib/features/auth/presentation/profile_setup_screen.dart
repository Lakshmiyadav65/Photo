// One-time profile setup — runs once per account, before the dashboard. Two
// steps, in the order the user asked for:
//   1. Nickname  → with a live "Hi, <nickname>" greeting preview.
//   2. Full name → the real name shown on the profile / to other members.
// On finish we write users/{uid} and continue to permissions (new account) or
// straight home (an existing user who just filled in their nickname).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../onboarding/data/permissions_store.dart';
import '../data/auth_repository.dart';
import '../data/user_profile_repository.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nickname = TextEditingController();
  final _name = TextEditingController();
  int _step = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Prefill the full name from the existing account name (e.g. an existing
    // user who only needs to add a nickname), so they can confirm in one tap.
    // Use the synchronous currentUser — the authStateProvider stream may not
    // have emitted yet this early in the session (it reads null on first read).
    final authUser = ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    _name.text = (authUser?.displayName ?? '').trim();
    _nickname.addListener(() => setState(() {}));
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nickname.dispose();
    _name.dispose();
    super.dispose();
  }

  void _toNameStep() {
    if (_nickname.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  Future<void> _finish() async {
    if (_busy || _name.text.trim().isEmpty) return;
    // Prefer the synchronous currentUser: the authStateProvider stream can
    // still read null this early (right after the splash/auth gate), which
    // would wrongly bounce a signed-in user to /auth without saving.
    final user = ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      context.go('/auth');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(userProfileRepositoryProvider).updateNames(
            uid: user.uid,
            nickname: _nickname.text.trim(),
            displayName: _name.text.trim(),
          );
      if (!mounted) return;
      // New accounts still owe the permissions walk; returning users skip it.
      final completed = ref.read(permissionsProvider).value?.completed ?? false;
      context.go(completed ? '/home' : '/permissions');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Couldn’t save that — check your connection.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Scrollable + min-height/IntrinsicHeight so the Spacer-based layout
        // still fills the screen normally, but the content scrolls (instead of
        // overflowing) once the keyboard shrinks the viewport.
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _step == 0 ? _buildNicknameStep() : _buildNameStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNicknameStep() {
    final nickname = _nickname.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 56),
        const HeroTitle(
            before: 'What should we ', emphasis: 'call you?', fontSize: 34),
        const SizedBox(height: 10),
        Text(
          'Pick a nickname for your greeting. You can use your real name next.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 44),
        LabeledField(
          label: 'Nickname',
          hint: 'Enter a nickname',
          controller: _nickname,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _toNameStep(),
        ),
        const SizedBox(height: 36),
        // Live greeting preview — exactly what the home header will show.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: AppTheme.cream2,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR GREETING', style: AppText.label(fontSize: 10)),
              const SizedBox(height: 10),
              HeroTitle(
                before: 'Hi, ',
                emphasis: nickname.isEmpty ? 'friend' : nickname,
                fontSize: 26,
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: nickname.isEmpty ? null : _toNameStep,
          child: const Text('Continue  →'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNameStep() {
    final name = _name.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 56),
        const HeroTitle(
            before: 'A face for the ', emphasis: 'gang', fontSize: 34),
        const SizedBox(height: 10),
        Text(
          'Add your name so friends know who’s shooting.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        Center(child: GangAvatar(name: name.isEmpty ? '?' : name, size: 104)),
        const SizedBox(height: 40),
        LabeledField(
          label: 'Your name',
          hint: 'Aarav Roy',
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _finish(),
        ),
        const Spacer(),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _step = 0),
          child: const Text('← Back to nickname'),
        ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: (name.isEmpty || _busy) ? null : _finish,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enter gang.roll'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
