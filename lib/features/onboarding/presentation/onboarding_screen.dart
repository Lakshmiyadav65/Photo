// Onboarding — 3-slide intro carousel for first-time users (prototype copy).
// Slide 2 sells the film "develop-lock" mechanic that defines the product.
//
// Layout/motion tuned to a RunBuds-style feel: a top segmented progress bar,
// a generous hero with a soft coral-glow ring, big editorial type, parallax
// between art and text while swiping, and a full-width ink CTA that hands off
// cleanly into the permissions step. Copy + art + palette are unchanged.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../features/splash/presentation/splash_screen.dart' show CameraMark;
import '../../../shared/widgets/brand.dart';
import '../data/permissions_store.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;

  /// One-shot entrance fade/rise for the whole screen, matching the splash.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  /// Live page position (fractional during a swipe) used to drive the parallax
  /// and the partial fill of the progress bar. Falls back to the settled page
  /// before the PageView has dimensions.
  double get _pageValue {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return _controller.page ?? _page.toDouble();
    }
    return _page.toDouble();
  }

  /// Leaving the intro carousel = onboarding done. Persist it so onboarding
  /// never shows again, then continue into the first-run auth flow.
  void _finishOnboarding() {
    ref.read(permissionsProvider.notifier).markOnboarded();
    context.go('/auth');
  }

  static const _slides = <_Slide>[
    _Slide(
      before: 'Snap with ',
      emphasis: 'your gang',
      body: 'Create a moment. Invite your friends. Every photo from your '
          'night, party, or trip ends up in one place.',
      art: _Art.camera,
    ),
    _Slide(
      before: 'Develop ',
      emphasis: 'together',
      body: "Photos stay locked while the moment is live. When time's up — the "
          'whole gallery develops at once. Like real film.',
      art: _Art.film,
    ),
    _Slide(
      before: 'Relive the ',
      emphasis: 'whole night',
      body: "No one's stuck behind the camera. No one misses a moment. Just "
          'one beautiful shared moment.',
      art: _Art.polaroids,
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  void _next() {
    if (_isLast) {
      _finishOnboarding();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    final rise = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: rise,
            child: Column(
              children: [
                // ── Top chrome: segmented progress + Skip ──────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, _) => _ProgressBar(
                            value: _pageValue,
                            count: _slides.length,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: Text('Skip',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                // ── Slides with art/text parallax ──────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => AnimatedBuilder(
                      animation: _controller,
                      builder: (_, _) {
                        final delta = _pageValue - i;
                        return _SlideView(slide: _slides[i], delta: delta);
                      },
                    ),
                  ),
                ),
                // ── Full-width primary CTA ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: FilledButton(
                    onPressed: _next,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Row(
                        key: ValueKey(_isLast),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_isLast ? 'Get started' : 'Continue'),
                          const SizedBox(width: 8),
                          Icon(
                            _isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top progress: one rounded segment per slide. The active segment fills
/// fractionally as the user swipes, so the bar tracks the gesture, not just
/// the settled page.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.count});

  /// Fractional page position (e.g. 1.4 = 40% of the way from slide 1 to 2).
  final double value;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
              child: _Segment(fill: (value - i + 1).clamp(0.0, 1.0)),
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 5,
        color: AppTheme.ink.withValues(alpha: 0.12),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fill,
          child: Container(color: AppTheme.coral),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, this.delta = 0});

  final _Slide slide;

  /// Distance of this slide from the viewport centre (0 = centred, ±1 =
  /// neighbour). Drives the parallax: art drifts faster than text and both
  /// fade out as the slide leaves.
  final double delta;

  @override
  Widget build(BuildContext context) {
    // Art moves more than text → a gentle parallax; content fades as it exits.
    final opacity = (1 - delta.abs() * 1.4).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(-delta * 56, 0),
              child: _HeroArt(art: slide.art),
            ),
            const SizedBox(height: 52),
            Transform.translate(
              offset: Offset(-delta * 22, 0),
              child: Column(
                children: [
                  HeroTitle(
                    before: slide.before,
                    emphasis: slide.emphasis,
                    fontSize: 36,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      slide.body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The circular art well, now with a soft coral-glow ring behind it for depth.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.art});

  final _Art art;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer glow ring.
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.coral.withValues(alpha: 0.06),
            ),
          ),
          // Inner art well.
          Container(
            width: 232,
            height: 232,
            decoration: const BoxDecoration(
              color: AppTheme.cream2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _buildArt(art),
          ),
        ],
      ),
    );
  }

  Widget _buildArt(_Art art) => switch (art) {
        _Art.camera => const CameraMark(size: 120),
        _Art.film => const _FilmArt(),
        _Art.polaroids => const _PolaroidCluster(),
      };
}

class _FilmArt extends StatelessWidget {
  const _FilmArt();

  @override
  Widget build(BuildContext context) {
    const frameColors = [
      Color(0xFF3A3530),
      Color(0xFF7A3E2D),
      Color(0xFF5A4738),
      AppTheme.coral,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in frameColors)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  color: c,
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppTheme.coral,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hourglass_top_rounded,
              color: AppTheme.cream, size: 22),
        ),
      ],
    );
  }
}

class _PolaroidCluster extends StatelessWidget {
  const _PolaroidCluster();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          _Polaroid(angle: -0.22, dx: -46, dy: 4, color: AppTheme.sage),
          _Polaroid(angle: 0.18, dx: 46, dy: -6, color: AppTheme.coral),
          _Polaroid(angle: -0.04, dx: 0, dy: 14, color: AppTheme.amber),
        ],
      ),
    );
  }
}

class _Polaroid extends StatelessWidget {
  const _Polaroid({
    required this.angle,
    required this.dx,
    required this.dy,
    required this.color,
  });

  final double angle;
  final double dx;
  final double dy;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 72,
          height: 88,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 16),
          decoration: BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(color: color),
        ),
      ),
    );
  }
}

enum _Art { camera, film, polaroids }

class _Slide {
  const _Slide({
    required this.before,
    required this.emphasis,
    required this.body,
    required this.art,
  });

  final String before;
  final String emphasis;
  final String body;
  final _Art art;
}
