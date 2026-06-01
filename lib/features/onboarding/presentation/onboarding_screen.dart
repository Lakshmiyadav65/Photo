// Onboarding — 3-slide intro carousel for first-time users (prototype copy).
// Slide 2 sells the film "develop-lock" mechanic that defines the product.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../features/splash/presentation/splash_screen.dart' show CameraMark;
import '../../../shared/widgets/brand.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

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
      context.go('/auth');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: Text('Skip',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppTheme.coral
                                : AppTheme.ink.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  _NextButton(onTap: _next, isLast: _isLast),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              color: AppTheme.cream2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _buildArt(slide.art),
          ),
          const SizedBox(height: 48),
          HeroTitle(
            before: slide.before,
            emphasis: slide.emphasis,
            fontSize: 34,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              slide.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap, required this.isLast});

  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppTheme.ink,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
          color: AppTheme.cream,
          size: 22,
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
