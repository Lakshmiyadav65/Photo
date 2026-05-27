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

import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/moments/presentation/create_moment_screen.dart';
import '../features/moments/presentation/home_screen.dart';
import '../features/moments/presentation/join_moment_screen.dart';
import '../features/moments/presentation/members_screen.dart';
import '../features/moments/presentation/moment_detail_screen.dart';
import '../features/moments/presentation/moment_settings_screen.dart';
import '../features/moments/presentation/share_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/photos/presentation/photo_viewer_screen.dart';
import '../features/profile/presentation/gangs_screen.dart';
import '../features/profile/presentation/grid_screen.dart';
import '../features/profile/presentation/profile_edit_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/search_screen.dart';
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
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
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
      GoRoute(
        path: '/gangs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const GangsScreen(),
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
        builder: (_, _) => const CreateMomentScreen(),
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
            path: 'photo/:pid',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => PhotoViewerScreen(
              code: state.pathParameters['code']!,
              photoId: state.pathParameters['pid']!,
            ),
          ),
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

/// Bottom-tab scaffold — a dark, rounded, floating bar with a center coral
/// shutter (prototype .tab-bar). The body extends behind it.
class _TabShell extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.cream,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 64,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.ink.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.32),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavButton(
                data: _destinations[0],
                active: index == 0,
                onTap: () => context.go(_destinations[0].path),
              ),
              _NavButton(
                data: _destinations[1],
                active: index == 1,
                onTap: () => context.go(_destinations[1].path),
              ),
              _ShutterButton(onTap: () => context.push('/camera')),
              _NavButton(
                data: _destinations[2],
                active: index == 2,
                onTap: () => context.go(_destinations[2].path),
              ),
              _NavButton(
                data: _destinations[3],
                active: index == 3,
                onTap: () => context.go(_destinations[3].path),
              ),
            ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          active ? data.selected : data.icon,
          size: 22,
          color: active ? AppTheme.cream : AppTheme.cream.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppTheme.coral,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
