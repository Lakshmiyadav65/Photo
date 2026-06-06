// Splash — brand mark on a warm cream gradient, then routes by auth state.
//
// Frontend behaviour: routes to /onboarding so the first-run flow can be
// walked. Phase 3 will check authStateProvider and route /onboarding (first
// launch) | /auth (logged out) | /home (logged in).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_bootstrap.dart';
import '../../../shared/widgets/brand.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_profile_repository.dart';
import '../../onboarding/data/permissions_store.dart';
import '../../quick_shoot/data/shortcut_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Route by launch state:
  ///   • Pinned-shortcut launch ALWAYS wins → straight to the camera, no brand
  ///     hold, bypassing onboarding/dashboard.
  ///   • Else hold the brand mark briefly, then route ONCE on the persisted
  ///     onboarding flag — a returning (onboarded) user never sees onboarding
  ///     again, even if a permission was later revoked.
  Future<void> _bootstrap() async {
    // Consumed once natively; the warm path is handled in app.dart.
    final shortcutMoment = await const ShortcutRepository().initialMoment();
    await ref.read(permissionsProvider.notifier).refresh();
    if (!mounted) return;

    if (shortcutMoment != null) {
      // Skip the brand hold; go straight to the camera (which shows a
      // permission fallback if camera access isn't granted).
      final router = ref.read(appRouterProvider);
      router.go('/home');
      Future.microtask(() => router.push('/camera?moment=$shortcutMoment'));
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final onboarded = ref.read(permissionsProvider).value?.onboarded ?? false;
    if (!onboarded) {
      context.go('/onboarding');
      return;
    }
    // Onboarded + signed-in but no nickname yet → one-time setup before home.
    if (await _needsProfileSetup()) {
      if (!mounted) return;
      context.go('/auth/profile');
      return;
    }
    if (!mounted) return;
    context.go('/home');
  }

  /// True when a signed-in user hasn't picked a nickname yet. Safe no-op when
  /// Firebase isn't wired or nobody is signed in (preserves the old straight-to-
  /// home path).
  Future<bool> _needsProfileSetup() async {
    if (ref.read(firebaseStatusProvider) != FirebaseStatus.ready) return false;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return false;
    try {
      final profile =
          await ref.read(userProfileRepositoryProvider).fetch(user.uid);
      return profile == null || !profile.hasNickname;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final rise = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.cream, Color(0xFFE8DCC4)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: rise,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CameraMark(size: 96),
                  const SizedBox(height: 32),
                  const Wordmark(fontSize: 60),
                  const SizedBox(height: 18),
                  Text(
                    'CAPTURE · DEVELOP · SHARE',
                    style: AppText.label(fontSize: 10).copyWith(letterSpacing: 3),
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

/// A small stylized film camera: dark body, coral top band, lens. Reused on
/// onboarding too.
class CameraMark extends StatelessWidget {
  const CameraMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final w = size;
    final h = size * 0.8;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // body
          Container(
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(size * 0.08),
            ),
          ),
          // top coral band
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: h * 0.22,
              decoration: BoxDecoration(
                color: AppTheme.coral,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * 0.08),
                ),
              ),
            ),
          ),
          // lens
          Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2622),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.coral, width: 2),
            ),
            alignment: Alignment.center,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: const BoxDecoration(
                color: AppTheme.ink,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
