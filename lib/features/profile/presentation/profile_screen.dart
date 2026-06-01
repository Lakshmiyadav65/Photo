// Profile tab — avatar, identity, stats, the Camera Shortcut toggle card, and
// the "MY PROFILE" menu. Mock identity until auth lands (Phase 3 sources
// name/handle/avatar from users/{uid}).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../active_moment/data/camera_shortcut_store.dart';

const _name = 'Aarav Roy';
const _handle = "@aarav · joined nov '25";

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcutOn = ref.watch(cameraShortcutProvider).value ?? true;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Header — avatar, name, handle, stats.
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.cream2, AppTheme.cream],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _IconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/settings'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const GangAvatar(name: _name, size: 88),
                  const SizedBox(height: 14),
                  Text(_name, style: AppText.display(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(_handle,
                      style: AppText.mono(fontSize: 12, color: AppTheme.muted)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _Stat(value: '14', label: 'MOMENTS'),
                      SizedBox(width: 32),
                      _Stat(value: '312', label: 'PHOTOS'),
                      SizedBox(width: 32),
                      _Stat(value: '38', label: 'GANG'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Camera Shortcut toggle card — controls whether the shutter goes
          // straight to camera or surfaces the destination picker first.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: _ToggleCard(
              icon: Icons.camera_alt_rounded,
              title: 'Enable camera shortcut',
              subtitle: shortcutOn
                  ? 'Shutter opens the camera directly.'
                  : 'Shutter asks where to upload first.',
              value: shortcutOn,
              onChanged: (v) =>
                  ref.read(cameraShortcutProvider.notifier).set(v),
            ),
          ),

          // Settings list — every row uses the same _MenuItem styling so the
          // hierarchy stays clean. "My profile" opens the editable details
          // screen; the rest follow.
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'My profile',
                  subtitle: 'Name, email, phone & avatar',
                  onTap: () => context.push('/profile/edit'),
                ),
                _MenuItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Moment history',
                  subtitle: '14 developed moments',
                  onTap: () => _soon(context),
                ),
                _MenuItem(
                  icon: Icons.tune_rounded,
                  title: 'Appearance',
                  subtitle: 'Film, grain & themes',
                  onTap: () => context.push('/settings'),
                ),
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  subtitle: 'FAQs, contact us',
                  onTap: () => _soon(context),
                ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  danger: true,
                  onTap: () => context.go('/auth'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.display(fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: AppText.label(fontSize: 9)),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.paper,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.line),
        ),
        child: Icon(icon, size: 18, color: AppTheme.ink),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.cream2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.coral : AppTheme.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.line2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.line),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: color),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (!danger)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}
