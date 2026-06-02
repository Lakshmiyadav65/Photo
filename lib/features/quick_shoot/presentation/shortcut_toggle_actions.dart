// Shared handler for the "Enable camera shortcut" / "Enable Quick Shoot"
// toggles. Turning it ON pins a real home-screen icon (the Android
// "Add to Home screen?" system dialog) bound to a resolved moment; turning it
// OFF disables the pinned shortcut and clears the flag.
//
// Used by both the Profile toggle and the Quick Shoot settings screen so the
// behaviour is identical wherever the user flips it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../active_moment/data/active_moment_store.dart';
import '../../active_moment/data/camera_shortcut_store.dart';
import '../../moments/data/mock_moments.dart';
import '../../moments/domain/moment.dart';
import '../data/shortcut_repository.dart';

/// Which moment a newly-enabled shortcut should target: the explicit Quick
/// Shoot binding, else the Active Moment, else the first visible moment.
Moment? _resolveMoment(WidgetRef ref) {
  final binding = ref.read(quickShootBindingProvider).value;
  if (binding != null) {
    final m = ref.read(momentByCodeProvider(binding.code));
    if (m != null) return m;
  }
  final active = ref.read(activeMomentProvider);
  if (active != null) return active;
  final visible = ref.read(visibleMomentsProvider);
  return visible.isEmpty ? null : visible.first;
}

/// Handle a toggle change. Shows the appropriate system/in-app feedback.
Future<void> handleShortcutToggle(
  BuildContext context,
  WidgetRef ref,
  bool next,
) async {
  const shortcuts = ShortcutRepository();

  // ── OFF ────────────────────────────────────────────────────────────────
  if (!next) {
    await ref.read(cameraShortcutProvider.notifier).set(false);
    await shortcuts.removeShortcut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Quick Shoot disabled. Remove the home-screen icon '
            'manually if it’s still there.'),
      ));
    }
    return;
  }

  // ── ON ─────────────────────────────────────────────────────────────────
  // 1. Resolve (and remember) the destination moment.
  final moment = _resolveMoment(ref);
  if (moment == null) {
    _snack(context, 'Create a moment first.');
    return; // toggle stays OFF
  }
  await ref
      .read(quickShootBindingProvider.notifier)
      .bind(moment.code, moment.title);

  // 2. Enable via the lowest-friction path for this device — native picks the
  //    legacy silent broadcast on OEM launchers, else requestPinShortcut (which
  //    shows the OS "Add" dialog). We stay SILENT on the pin path (the OS dialog
  //    is the feedback); the legacy path is unconfirmable, so we gently guide.
  final result = await shortcuts.enableShortcut(
    momentId: moment.code,
    momentName: moment.title,
  );
  await ref.read(cameraShortcutProvider.notifier).set(true);
  if (!context.mounted) return;

  if (!result.success) {
    _snack(context, "Couldn't add shortcut, try again.");
  } else if (result.isLegacy) {
    _snack(context,
        'Adding “${moment.title}” to your home screen. If it doesn’t appear, '
        'enable “Create home-screen shortcuts” in Settings → Apps → gang.roll.');
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
