// Screen A — Quick Shoot settings. Bind one moment to the home-screen shortcut
// and toggle it on/off.
//
// Rules:
//   • Enable toggle is OFF until the user opts in (Bug #1).
//   • Enabling with no bound moment is blocked — pick a moment first.
//   • Enabling registers the OS shortcut "Quick Shoot — {moment}" (Bug #2);
//     disabling clears it. Changing the moment re-labels a live shortcut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../active_moment/data/camera_shortcut_store.dart';
import '../../moments/data/mock_moments.dart';
import '../../moments/domain/moment.dart';
import '../data/services/local_storage_service.dart';
import 'shortcut_toggle_actions.dart';

class QuickShootSettingsScreen extends ConsumerWidget {
  const QuickShootSettingsScreen({super.key});

  void _toast(String msg) => Fluttertoast.showToast(
        msg: msg,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.ink,
        textColor: AppTheme.cream,
      );

  Future<void> _pickMoment(BuildContext context, WidgetRef ref) async {
    final moments = ref.read(visibleMomentsProvider);
    final chosen = await showModalBottomSheet<Moment>(
      context: context,
      backgroundColor: AppTheme.paper,
      builder: (_) => _MomentPickerSheet(moments: moments),
    );
    if (chosen == null) return;
    await ref
        .read(quickShootBindingProvider.notifier)
        .bind(chosen.code, chosen.title);
    // Re-label a live shortcut to the new destination.
    final enabled = ref.read(cameraShortcutProvider).value ?? false;
    if (enabled) _toast('Shortcut now points to ${chosen.title}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(cameraShortcutProvider).value ?? false;
    final binding = ref.watch(quickShootBindingProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Quick Shoot')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          // Enable toggle.
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable Quick Shoot',
                          style: AppText.display(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        enabled
                            ? 'Shortcut is live on your home screen.'
                            : 'Off — turn on to add the home-screen shortcut.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AppToggle(
                    value: enabled,
                    onChanged: (v) => handleShortcutToggle(context, ref, v)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bound moment.
          Text('BOUND MOMENT', style: AppText.label()),
          const SizedBox(height: 8),
          _Card(
            onTap: () => _pickMoment(context, ref),
            child: Row(
              children: [
                const Icon(Icons.place_rounded,
                    color: AppTheme.coral, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    binding?.name ?? 'Pick a moment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(fontSize: 16),
                  ),
                ),
                const Icon(Icons.expand_more_rounded, color: AppTheme.muted),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Photos shot with the shortcut are queued for upload to this moment.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          // Storage location (display only).
          Text('STORAGE LOCATION', style: AppText.label()),
          const SizedBox(height: 8),
          Text(
            'Pictures/${LocalStorageService.albumName}/',
            style: AppText.mono(fontSize: 13),
          ),
          const SizedBox(height: 24),

          // How it works.
          Text('HOW IT WORKS', style: AppText.label()),
          const SizedBox(height: 8),
          const _Step(n: '1', text: 'Tap the shortcut → camera opens.'),
          const _Step(n: '2', text: 'Shoot freely — as many as you like.'),
          const _Step(n: '3', text: 'Open the app → tap Resume Upload.'),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return GestureDetector(onTap: onTap, child: body);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});

  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n  ', style: AppText.mono(fontSize: 13, color: AppTheme.coral)),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _MomentPickerSheet extends StatelessWidget {
  const _MomentPickerSheet({required this.moments});

  final List<Moment> moments;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bind a moment', style: AppText.display(fontSize: 20)),
            const SizedBox(height: 16),
            if (moments.isEmpty)
              Text('Create or join a moment first.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              for (final m in moments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bolt_rounded,
                      color: AppTheme.coral),
                  title: Text(m.title, style: AppText.display(fontSize: 16)),
                  subtitle: Text(
                    '${m.memberCount} members · ${m.photoCount} shots',
                    style: AppText.label(fontSize: 10),
                  ),
                  onTap: () => Navigator.of(context).pop(m),
                ),
          ],
        ),
      ),
    );
  }
}
