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
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/permissions_screen.dart';
import '../features/photos/presentation/photo_viewer_screen.dart';
import '../features/profile/presentation/grid_screen.dart';
import '../features/profile/presentation/profile_edit_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/quick_shoot/presentation/camera_screen.dart';
import '../features/quick_shoot/presentation/moment_with_pending_screen.dart';
import '../features/quick_shoot/presentation/quick_shoot_settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/updates/presentation/update_toast.dart';
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

      // (Removed) /upload-progress — gallery/camera picks now upload optimistically
      // inside the moment's photo grid (see upload_actions + the Quick Shoot
      // PendingPhoto queue), so there is no separate upload screen.

      // The one shared fullscreen photo viewer. `:source` selects the
      // collection to page through ('all' → All Photos, otherwise a moment
      // code); the viewing experience is identical for every source.
      GoRoute(
        path: '/photos/:source/:pid',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => PhotoViewerScreen(
          source: state.pathParameters['source']!,
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
        builder: (_, _) => const QuickShootSettingsScreen(),
      ),
      // Moment view surfacing Quick Shoot photos waiting to upload. Kept as a
      // distinct top-level path so it doesn't collide with /moment/:code's
      // nested sub-routes (share / insights / members / settings).
      GoRoute(
        path: '/pending/:code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            MomentWithPendingScreen(code: state.pathParameters['code']!),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Lost')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});

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

  /// The in-app shutter ALWAYS opens the custom camera directly — no
  /// "Take photo / Upload from gallery" chooser. The camera resolves the
  /// last-selected (Active) moment itself; with none ever chosen it opens with
  /// an empty selector and blocks capture until the user picks one. Closing the
  /// camera lands on the selected moment.
  void _onShutter(BuildContext context, WidgetRef ref) {
    context.push('/camera');
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
      // The tab content, with the floating "update available" toast layered
      // above it (renders nothing until an un-dismissed update exists).
      body: Stack(
        children: [
          child,
          const UpdateToastLayer(),
        ],
      ),
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

