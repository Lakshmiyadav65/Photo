// Root widget. Owns MaterialApp.router, theme, and the GoRouter instance.
// Also initializes the Camera quick action so launches from the long-press
// app-icon shortcut land directly in the camera flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../features/active_moment/data/camera_shortcut_store.dart';
import 'router.dart';
import 'scroll_behavior.dart';
import 'theme.dart';

class GangRollApp extends ConsumerStatefulWidget {
  const GangRollApp({super.key});

  @override
  ConsumerState<GangRollApp> createState() => _GangRollAppState();
}

class _GangRollAppState extends ConsumerState<GangRollApp> {
  @override
  void initState() {
    super.initState();
    // Register the quick-action handler once. When the user taps the "Camera"
    // shortcut on the launcher, this fires before splash routing decides
    // where to go — we flip a flag the splash watches.
    const QuickActions().initialize((type) {
      if (type == kCameraShortcutType) {
        ref.read(cameraShortcutLaunchProvider.notifier).set(true);
      }
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
