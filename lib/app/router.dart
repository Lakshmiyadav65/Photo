// App router — all routes per spec App Flow doc.
//
// Structure:
//   • Splash at `/` — checks auth, redirects (frontend: → /onboarding).
//   • Auth flow: /onboarding → /auth → /auth/profile → /home
//   • ShellRoute wraps the 4 bottom-tab destinations: /home, /search, /grid,
//     /profile. A center shutter button (not a destination) pushes /camera.
//   • Moment sub-paths nest under /moment/:code.
//   • Modal-style routes (camera, photo viewer, share, settings) push above
//     the shell.
//
// Deep-link plan: `gangroll://join/<code>` and https links resolve to /join
// with the code prefilled (wired in Phase 6 of the implementation plan).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../features/active_moment/data/camera_shortcut_store.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/gangs/presentation/create_gang_screen.dart';
import '../features/gangs/presentation/gang_detail_screen.dart';
import '../features/gangs/presentation/gangs_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/moments/presentation/create_moment_screen.dart';
import '../features/moments/presentation/home_screen.dart';
import '../features/moments/presentation/join_moment_screen.dart';
import '../features/moments/presentation/members_screen.dart';
import '../features/moments/presentation/moment_detail_screen.dart';
import '../features/moments/presentation/moment_settings_screen.dart';
import '../features/moments/presentation/share_screen.dart';
import '../features/moments/data/mock_moments.dart';
import '../features/moments/data/mock_photos.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/permissions_screen.dart';
import '../features/photos/presentation/photo_viewer_screen.dart';
import '../features/upload/presentation/upload_actions.dart';
import '../features/upload/presentation/upload_progress_screen.dart';
import '../features/profile/presentation/grid_screen.dart';
import '../features/profile/presentation/profile_edit_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/quick_shoot/presentation/camera_screen.dart';
import '../features/quick_shoot/presentation/shortcut_setup_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'theme.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/permissions',
        builder: (_, _) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, _) => const AuthScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (_, _) => const ProfileSetupScreen(),
          ),
        ],
      ),

      // Bottom-tab shell: Home, Search, Grid, Profile (+ center shutter).
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, _, child) => _TabShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          // Search tab opens the Gangs experience — the social side of the app.
          GoRoute(path: '/search', builder: (_, _) => const GangsScreen()),
          GoRoute(path: '/grid', builder: (_, _) => const GridScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),

      // Profile sub-routes (pushed above the shell).
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ProfileEditScreen(),
      ),
      // Pushed from the profile — same Gangs screen, with a back control.
      GoRoute(
        path: '/gangs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const GangsScreen(showBack: true),
      ),
      GoRoute(
        path: '/gang/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            GangDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create-gang',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const CreateGangScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
      ),

      // Moment flow (pushed above the shell so the tab bar hides).
      GoRoute(
        path: '/create',
        parentNavigatorKey: _rootNavigatorKey,
        // Optional `extra` carries member names to pre-invite — used when
        // launching from a Gang ("Start new moment with them →").
        builder: (_, state) {
          final prefilled = state.extra is List<String>
              ? state.extra as List<String>
              : const <String>[];
          return CreateMomentScreen(prefilledMembers: prefilled);
        },
      ),
      GoRoute(
        path: '/join',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => JoinMomentScreen(
          prefilledCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/moment/:code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => MomentDetailScreen(
          code: state.pathParameters['code']!,
        ),
        routes: [
          GoRoute(
            path: 'share',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                ShareScreen(code: state.pathParameters['code']!),
          ),
          GoRoute(
            path: 'insights',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                InsightsScreen(code: state.pathParameters['code']!),
          ),
          GoRoute(
            path: 'members',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                MembersScreen(code: state.pathParameters['code']!),
          ),
          GoRoute(
            path: 'settings',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                MomentSettingsScreen(code: state.pathParameters['code']!),
          ),
        ],
      ),

      // Upload progress for real picked/captured files. `extra` carries the
      // XFile list; `?moment=<code>` is the destination. The picker/camera
      // step happens before this route via upload_actions so the user always
      // arrives here with files in hand.
      GoRoute(
        path: '/upload-progress',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) {
          final code = state.uri.queryParameters['moment'] ?? '';
          final files = (state.extra as List<XFile>?) ?? const [];
          final moment = ref.read(momentByCodeProvider(code));
          return _slideUpPage(
            key: state.pageKey,
            child: UploadProgressScreen(
              files: files,
              momentCode: code,
              momentTitle: moment?.title ?? 'your moment',
            ),
          );
        },
      ),

      // The one shared fullscreen photo viewer. `:source` selects the
      // collection to page through ('all' → All Photos, otherwise a moment
      // code); the viewing experience is identical for every source.
      GoRoute(
        path: '/photos/:source/:pid',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => PhotoViewerScreen(
          photos: photosForSource(state.pathParameters['source']!),
          initialPhotoId: state.pathParameters['pid']!,
        ),
      ),

      // Camera (Quick Shoot). Routes here from the shutter tab, /shortcut/setup,
      // or a moment's Snap CTA.
      GoRoute(
        path: '/camera',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => CameraScreen(
          momentCode: state.uri.queryParameters['moment'],
        ),
      ),
      GoRoute(
        path: '/shortcut/setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ShortcutSetupScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Lost')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});

/// A modal layer that slides up from the bottom with a soft fade + subtle
/// scale — the presentation used for the upload flow so it feels like a sheet
/// rising over the moment rather than a hard screen push.
CustomTransitionPage<void> _slideUpPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Bottom-tab scaffold — an edge-anchored cream bar that blends into the
/// scaffold, with a hairline top border and a coral shutter designed into the
/// row (not floating over it). Same destinations, same icons, same behavior.
class _TabShell extends ConsumerWidget {
  const _TabShell({required this.child});
  final Widget child;

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home_rounded, path: '/home'),
    (icon: Icons.search_rounded, selected: Icons.search_rounded, path: '/search'),
    (icon: Icons.grid_view_outlined, selected: Icons.grid_view_rounded, path: '/grid'),
    (icon: Icons.person_outline_rounded, selected: Icons.person_rounded, path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  /// Shutter behavior:
  ///   • Shortcut ON → straight to the device camera (capture → upload to
  ///     Active Moment). If no Active Moment is set, prompt once.
  ///   • Shortcut OFF → ask "Take photo / Upload from gallery"; the chosen
  ///     branch handles permission gating + device picker via upload_actions.
  Future<void> _onShutter(BuildContext context, WidgetRef ref) async {
    final shortcutOn = ref.read(cameraShortcutProvider).value ?? false;
    if (shortcutOn) {
      await captureWithCamera(context, ref);
      return;
    }

    final choice = await showModalBottomSheet<_ShutterChoice>(
      context: context,
      backgroundColor: AppTheme.cream,
      builder: (_) => const _ShutterChoiceSheet(),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _ShutterChoice.camera:
        await captureWithCamera(context, ref);
      case _ShutterChoice.gallery:
        await pickFromGallery(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);

    // If the app was launched via the Camera quick action, the splash routed
    // here; trigger the shutter on the next frame and clear the flag.
    if (ref.watch(cameraShortcutLaunchProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(cameraShortcutLaunchProvider.notifier).set(false);
        _onShutter(context, ref);
      });
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.cream,
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.cream,
          border: Border(top: BorderSide(color: AppTheme.line, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            // Centered cluster with fixed gaps — tighter than equal-slot
            // distribution. Nav-to-nav gap is smaller than nav-to-shutter, so
            // the shutter (the heavier element) gets a touch more breathing
            // room without breaking symmetry.
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavButton(
                    data: _destinations[0],
                    active: index == 0,
                    onTap: () => context.go(_destinations[0].path),
                  ),
                  const SizedBox(width: 16),
                  _NavButton(
                    data: _destinations[1],
                    active: index == 1,
                    onTap: () => context.go(_destinations[1].path),
                  ),
                  const SizedBox(width: 24),
                  _ShutterButton(onTap: () => _onShutter(context, ref)),
                  const SizedBox(width: 24),
                  _NavButton(
                    data: _destinations[2],
                    active: index == 2,
                    onTap: () => context.go(_destinations[2].path),
                  ),
                  const SizedBox(width: 16),
                  _NavButton(
                    data: _destinations[3],
                    active: index == 3,
                    onTap: () => context.go(_destinations[3].path),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.active,
    required this.onTap,
  });

  final ({IconData icon, IconData selected, String path}) data;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 34,
      highlightColor: Colors.transparent,
      splashColor: AppTheme.coral.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        // Cross-fade between the outlined/filled variants when the tab activates
        // so the state change reads as one smooth icon swap, not a flicker.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Icon(
            active ? data.selected : data.icon,
            key: ValueKey(active),
            size: 30,
            color: active ? AppTheme.coral : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: DecoratedBox(
          // Slightly deeper ambient coral shadow gives the primary action
          // weight without turning it into a floating widget.
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.softShadow,
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.coral,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Method-of-capture choice surfaced when Camera Shortcut is off.
enum _ShutterChoice { camera, gallery }

class _ShutterChoiceSheet extends StatelessWidget {
  const _ShutterChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cream2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _ChoiceTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take a photo',
              subtitle: 'Capture and upload to your active moment.',
              onTap: () => Navigator.of(context).pop(_ShutterChoice.camera),
            ),
            const SizedBox(height: 10),
            _ChoiceTile(
              icon: Icons.photo_library_rounded,
              title: 'Upload from gallery',
              subtitle: 'Pick existing photos to add.',
              onTap: () => Navigator.of(context).pop(_ShutterChoice.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.paper,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.coral.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.cream2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
