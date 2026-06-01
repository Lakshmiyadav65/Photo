// The Moments tab of a gang: shared moments as compact, soft cards (gradient
// cover, serif-italic title, muted date · shots meta, chevron), closed by a
// quiet text-style coral CTA to start a new moment together. Tapping a row
// opens the existing Moment experience.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../moments/domain/moment.dart';
import '../../../moments/presentation/widgets/moment_cover.dart';
import '../../../moments/presentation/widgets/press_card.dart';

class GangMomentsList extends StatelessWidget {
  const GangMomentsList({
    super.key,
    required this.moments,
    required this.onOpenMoment,
    required this.onStartMoment,
  });

  final List<Moment> moments;
  final ValueChanged<Moment> onOpenMoment;
  final VoidCallback onStartMoment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('gang-moments'),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: [
        for (final m in moments)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MomentRow(moment: m, onTap: () => onOpenMoment(m)),
          ),
        const SizedBox(height: 8),
        _StartMomentCta(onTap: onStartMoment),
      ],
    );
  }
}

class _MomentRow extends StatelessWidget {
  const _MomentRow({required this.moment, required this.onTap});

  final Moment moment;
  final VoidCallback onTap;

  String get _meta {
    final d = moment.developedAt ?? moment.endsAt ?? DateTime.now();
    final date = DateFormat('MMM d').format(d).toUpperCase();
    return '$date · ${moment.photoCount} SHOTS';
  }

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: SizedBox(
              width: 56,
              height: 56,
              child: MomentCover(moment: moment, memCacheWidth: 160),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  moment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(_meta, style: AppText.label(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

class _StartMomentCta extends StatefulWidget {
  const _StartMomentCta({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_StartMomentCta> createState() => _StartMomentCtaState();
}

class _StartMomentCtaState extends State<_StartMomentCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _down ? 0.7 : 1,
          duration: const Duration(milliseconds: 110),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start new moment with them',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.coral,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    size: 17, color: AppTheme.coral),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
