// First-run permissions — camera + gallery + the camera-shortcut toggle, in
// three cards under an editorial header. Built only from existing tokens; no
// new design language. The Continue CTA stays disabled until both camera and
// gallery are granted; tapping it marks the onboarding step complete and
// hands the user off to the dashboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../../shared/widgets/brand.dart';
import '../../active_moment/data/camera_shortcut_store.dart';
import '../data/permissions_store.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionsProvider).value;
    final cameraGranted = perms?.cameraGranted ?? false;
    final galleryGranted = perms?.galleryGranted ?? false;
    final shortcutOn = ref.watch(cameraShortcutProvider).value ?? true;
    final canContinue = cameraGranted && galleryGranted;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                children: [
                  Text('ONE MORE THING', style: AppText.label(fontSize: 11)),
                  const SizedBox(height: 10),
                  const HeroTitle(
                    before: 'a couple ',
                    emphasis: 'permissions',
                    fontSize: 28,
                  ),
                  const SizedBox(height: 24),
                  _PermissionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Allow camera access',
                    body: 'Capture moments directly from your camera.',
                    granted: cameraGranted,
                    onAllow: () async {
                      HapticFeedback.selectionClick();
                      await ref
                          .read(permissionsProvider.notifier)
                          .requestCamera();
                    },
                  ),
                  const SizedBox(height: 14),
                  _PermissionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Allow gallery access',
                    body: 'Upload photos from your device.',
                    granted: galleryGranted,
                    onAllow: () async {
                      HapticFeedback.selectionClick();
                      await ref
                          .read(permissionsProvider.notifier)
                          .requestGallery();
                    },
                  ),
                  const SizedBox(height: 14),
                  _ShortcutCard(
                    value: shortcutOn,
                    onChanged: (v) =>
                        ref.read(cameraShortcutProvider.notifier).set(v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                style: AppTheme.coralButton,
                onPressed: canContinue
                    ? () async {
                        await ref
                            .read(permissionsProvider.notifier)
                            .markCompleted();
                        if (context.mounted) context.go('/home');
                      }
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.granted,
    required this.onAllow,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool granted;
  final Future<void> Function() onAllow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon),
              const Spacer(),
              if (granted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.sage.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 14, color: AppTheme.sage),
                      const SizedBox(width: 4),
                      Text('GRANTED',
                          style: AppText.label(
                              fontSize: 9, color: AppTheme.sage)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: AppText.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          if (!granted)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 40,
                child: FilledButton(
                  style: AppTheme.coralButton.copyWith(
                    minimumSize:
                        const WidgetStatePropertyAll(Size(96, 40)),
                    padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 22)),
                  ),
                  onPressed: onAllow,
                  child: const Text('Allow'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.bolt_rounded),
              const Spacer(),
              AppToggle(value: value, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 14),
          Text('Enable camera shortcut',
              style: AppText.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Open camera faster from your device shortcut.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: AppTheme.coral),
    );
  }
}
