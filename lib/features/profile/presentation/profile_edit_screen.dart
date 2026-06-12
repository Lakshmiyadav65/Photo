// Edit profile — avatar + name + username + email + phone.
//
// Sources its values from the live signed-in profile (users/{uid}) — no more
// hardcoded placeholder identity. Name + username persist to Firestore via
// [UserProfileRepository.updateNames]; the avatar is picked from the gallery /
// camera and stored locally (see [userAvatarProvider]); phone is kept locally
// (no field on the profile doc yet); email is shown read-only (it changes
// through a separate verified flow).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_profile_repository.dart';
import '../../auth/domain/user_profile.dart';
import '../data/avatar_store.dart';

const _kPhoneKey = 'user_phone';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  /// Guards the one-time prefill so a late profile emission never stomps edits
  /// the user has already started typing.
  bool _prefilled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Prefill immediately if the profile/auth state is already in memory
    // (common — this screen is pushed from the profile tab).
    _maybePrefill(
      profile: ref.read(currentUserProfileProvider).value,
      authUser: ref.read(authStateProvider).value,
    );
    _loadPhone();
    _name.addListener(() => setState(() {}));
  }

  Future<void> _loadPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_kPhoneKey) ?? '';
    if (mounted && _phone.text.isEmpty) _phone.text = phone;
  }

  /// Populate the fields from the real identity, once.
  void _maybePrefill({UserProfile? profile, AuthUser? authUser}) {
    if (_prefilled) return;
    if (profile == null && authUser == null) return;
    _prefilled = true;
    _name.text = (profile?.displayName.trim().isNotEmpty ?? false)
        ? profile!.displayName.trim()
        : (authUser?.displayName?.trim() ?? '');
    _handle.text = profile?.nickname.trim() ?? '';
    _email.text = (profile?.email.trim().isNotEmpty ?? false)
        ? profile!.email.trim()
        : (authUser?.email.trim() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_busy;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    // Persist name + username to the profile doc when signed in; persist phone
    // locally (no field on the doc yet). Avatar already saved on pick.
    final user = ref.read(authStateProvider).value;
    try {
      if (user != null) {
        await ref.read(userProfileRepositoryProvider).updateNames(
              uid: user.uid,
              nickname: _handle.text.trim(),
              displayName: _name.text.trim(),
            );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPhoneKey, _phone.text.trim());
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Couldn’t save that — check your connection.')));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile updated')));
    context.pop();
  }

  // ── Avatar picker ──────────────────────────────────────────────────────────

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked == null) return; // user cancelled
      await ref.read(userAvatarProvider.notifier).setFromFile(picked.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Couldn’t open the camera/gallery — check permissions.')));
    }
  }

  void _openAvatarSheet() {
    final hasAvatar = ref.read(userAvatarProvider).value != null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profile photo',
                      style: AppText.display(fontSize: 18)),
                ),
              ),
              _SheetAction(
                icon: Icons.photo_camera_rounded,
                label: 'Take photo',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAvatar(ImageSource.camera);
                },
              ),
              _SheetAction(
                icon: Icons.photo_library_rounded,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (hasAvatar)
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove photo',
                  danger: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(userAvatarProvider.notifier).clear();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prefill late if the profile stream emits after this screen opened.
    ref.listen(currentUserProfileProvider, (_, next) {
      if (!_prefilled && next.value != null) {
        _maybePrefill(
          profile: next.value,
          authUser: ref.read(authStateProvider).value,
        );
        setState(() {});
      }
    });

    final avatarPath = ref.watch(userAvatarProvider).value;

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
                  Center(
                    child: _AvatarEditor(
                      name: _name.text,
                      imagePath: avatarPath,
                      onTap: _openAvatarSheet,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LabeledField(
                    label: 'Full name',
                    hint: 'Your name',
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Username (optional)',
                    hint: 'username',
                    controller: _handle,
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Email',
                    hint: 'you@gangroll.app',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Phone',
                    hint: 'Add a phone number',
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
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
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
  const _AvatarEditor({
    required this.name,
    required this.imagePath,
    required this.onTap,
  });

  final String name;
  final String? imagePath;
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
            GangAvatar(name: name, size: 108, imagePath: imagePath),
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

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.coral : AppTheme.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
