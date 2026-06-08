// A roll in the home list: a large photo card with a date pill, an insights
// button, the gang's avatars, and the shot count over a legibility gradient.
// Photos aren't wired yet (Phase 4/5), so the image is a per-roll gradient.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/gang_avatar.dart';
import '../../data/mock_moments.dart';
import '../../domain/moment.dart';
import 'moment_cover.dart';

class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.moment,
    this.onTap,
    this.onLongPress,
    this.onInsights,
  });

  final Moment moment;
  final VoidCallback? onTap;

  /// Long-press surfaces the leave/delete action sheet.
  final VoidCallback? onLongPress;
  final VoidCallback? onInsights;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 11,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MomentCover(moment: moment),
              // Legibility wash toward the bottom for the title/meta.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xCC0A0A0A)],
                    begin: Alignment(0, 0.05),
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              Positioned(
                top: 14,
                left: 14,
                child: _StatusPill(moment: moment),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: _GlassIconButton(
                  icon: Icons.insights_rounded,
                  onTap: onInsights,
                ),
              ),

              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _AvatarStrip(members: moment.members),
                        const SizedBox(width: 10),
                        Text(
                          '${moment.photoCount} shots',
                          style: AppText.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlapping circle avatars for the gang, capped with a "+N" overflow chip.
class _AvatarStrip extends StatelessWidget {
  const _AvatarStrip({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    const step = 15.0;
    final shown = members.take(4).toList();
    final extra = members.length - shown.length;
    final slots = shown.length + (extra > 0 ? 1 : 0);
    final width = slots == 0 ? 0.0 : size + (slots - 1) * step;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: GangAvatar(
                name: shown[i],
                size: size,
                borderColor: Colors.white,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: AppText.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Top-left card pill: a date once developed, or an amber **LIVE + countdown**
/// while the roll is still develop-locked. Watches [tickerProvider] only while
/// locked, so it ticks down and clears itself the instant the roll develops.
class _StatusPill extends ConsumerWidget {
  const _StatusPill({required this.moment});

  final Moment moment;

  static String _short(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked =
        moment.endsAt != null && DateTime.now().isBefore(moment.endsAt!);
    if (!locked) {
      final d = moment.developedAt ?? moment.endsAt ?? DateTime.now();
      return _GlassPill(
        child: Text(
          DateFormat('MMM d').format(d).toUpperCase(),
          style: AppText.mono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
      );
    }
    ref.watch(tickerProvider); // live countdown while locked
    final left = moment.timeLeft ?? Duration.zero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.amber,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            'LIVE · ${_short(left)}',
            style: AppText.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
