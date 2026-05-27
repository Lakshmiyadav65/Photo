// A roll in the home list: gradient thumbnail, title, mono meta, status badge.

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/moment.dart';
import 'roll_badge.dart';

class MomentCard extends StatelessWidget {
  const MomentCard({super.key, required this.moment, this.onTap});

  final Moment moment;
  final VoidCallback? onTap;

  String get _meta {
    final tail = switch (moment.state) {
      RollState.live => _timeLeftLabel(moment.timeLeft),
      RollState.developing => 'Developing',
      RollState.developed => _agoLabel(moment.developedAt),
    };
    return '${moment.photoCount} photos   ·   ${moment.memberCount} gang   ·   $tail';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.paper,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            children: [
              _RollThumb(moment: moment),
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
                      style: AppText.display(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mono(fontSize: 11, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RollBadge(state: moment.state),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollThumb extends StatelessWidget {
  const _RollThumb({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    // Developed rolls show a warm "photo" gradient; locked rolls (live /
    // developing) show a muted, undeveloped tile with a lock hint.
    final developed = moment.isDeveloped;
    final seed = moment.code.hashCode.abs();
    final palettes = [
      [AppTheme.coral, AppTheme.amber],
      [const Color(0xFF2A4A5A), const Color(0xFF5A8A7A)],
      [AppTheme.sage, const Color(0xFF5A6F50)],
      [AppTheme.amber, const Color(0xFF7A3E2D)],
    ];
    final colors = palettes[seed % palettes.length];

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: developed
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: developed ? null : AppTheme.cream2,
      ),
      alignment: Alignment.center,
      child: developed
          ? null
          : Icon(
              moment.isDeveloping ? Icons.hourglass_top_rounded : Icons.lock_outline,
              size: 20,
              color: AppTheme.ink.withValues(alpha: 0.35),
            ),
    );
  }
}

String _timeLeftLabel(Duration? d) {
  if (d == null || d == Duration.zero) return 'Ending';
  if (d.inHours >= 1) return '${d.inHours}h left';
  if (d.inMinutes >= 1) return '${d.inMinutes}m left';
  return 'Ending';
}

String _agoLabel(DateTime? t) {
  if (t == null) return 'Developed';
  final d = DateTime.now().difference(t);
  if (d.inDays >= 7) {
    final w = d.inDays ~/ 7;
    return w == 1 ? '1 week ago' : '$w weeks ago';
  }
  if (d.inDays >= 1) return d.inDays == 1 ? '1 day ago' : '${d.inDays} days ago';
  if (d.inHours >= 1) return '${d.inHours}h ago';
  return 'Just now';
}
