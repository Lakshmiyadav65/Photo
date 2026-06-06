// Edit profile — avatar + name + handle + email + phone, built from the same
// LabeledField underline-input + display-text styling used in auth / create
// flows. Frontend stub: edits are local until Phase 3+ writes them through to
// users/{uid} (and denormalized event member docs).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../../shared/widgets/labeled_field.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _name = TextEditingController(text: 'Aarav Roy');
  final _handle = TextEditingController(text: 'aarav');
  final _email = TextEditingController(text: 'aarav@gang.roll');
  final _phone = TextEditingController(text: '+91 98765 43210');

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  void _save() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile updated')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  // Avatar + edit affordance. Real avatar upload lands later;
                  // tapping the camera badge shows a "soon" toast.
                  Center(
                    child: _AvatarEditor(
                      name: _name.text,
                      onTap: () => _soon('Avatar picker coming soon'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  LabeledField(
                    label: 'Full name',
                    hint: 'Aarav Roy',
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Username (optional)',
                    hint: 'aarav',
                    controller: _handle,
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Email',
                    hint: 'you@gangroll.app',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Phone',
                    hint: '+91 98765 43210',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.ink,
          ),
          Expanded(
            child: Center(
              child: Text('Edit profile',
                  style: AppText.display(fontSize: 17)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GangAvatar(name: name, size: 108),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cream, width: 3),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
