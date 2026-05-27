// Splash — brand mark on a warm cream gradient, then routes by auth state.
//
// Frontend behaviour: routes to /onboarding so the first-run flow can be
// walked. Phase 3 will check authStateProvider and route /onboarding (first
// launch) | /auth (logged out) | /home (logged in).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';

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
    // Brand mark holds ~1.6s, then into the first-run flow.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      // TODO(phase 3): check authStateProvider; route /onboarding | /auth | /home.
      context.go('/onboarding');
    });
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
