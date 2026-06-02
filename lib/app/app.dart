// Root widget. Owns MaterialApp.router, theme, and the GoRouter instance.
// Also initializes the Camera quick action so launches from the long-press
// app-icon shortcut land directly in the camera flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../features/active_moment/data/camera_shortcut_store.dart';
import '../features/quick_shoot/data/shortcut_repository.dart';
import 'router.dart';
import 'scroll_behavior.dart';
import 'theme.dart';

class GangRollApp extends ConsumerStatefulWidget {
  const GangRollApp({super.key});

  @override
  ConsumerState<GangRollApp> createState() => _GangRollAppState();
}

class _GangRollAppState extends ConsumerState<GangRollApp> {
  static const _shortcuts = ShortcutRepository();

  @override
  void initState() {
    super.initState();
    // Dynamic (long-press app icon) quick action — the fallback path.
    const QuickActions().initialize((type) {
      if (type == kCameraShortcutType) {
        ref.read(cameraShortcutLaunchProvider.notifier).set(true);
      }
    });

    // Pinned home-screen shortcut — WARM start only (app already running):
    // push the camera, deferred to the next frame so we never navigate while
    // the navigator is locked. The COLD start is consumed by the splash (which
    // skips the brand hold and goes straight to the camera).
    _shortcuts.listen(_warmOpenCamera);
  }

  /// Warm-start tap of the pinned icon: open the camera bound to the moment.
  /// Closing the camera (X / back) lands on that moment — handled by the camera.
  void _warmOpenCamera(String momentId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appRouterProvider).push('/camera?moment=$momentId');
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'gang.roll',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Light mode only in v1 per spec.
      themeMode: ThemeMode.light,
      // Clamp scrolling app-wide — no bounce, no stretch overscroll.
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
    );
  }
}
