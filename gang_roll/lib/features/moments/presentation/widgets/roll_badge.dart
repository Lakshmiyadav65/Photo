// The Live / Dev / Done status badge for a roll, with a pulsing dot when live.

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/moment.dart';

extension RollStateUi on RollState {
  String get badgeLabel => switch (this) {
        RollState.live => 'Live',
        RollState.developing => 'Dev',
        RollState.developed => 'Done',
      };

  Color get badgeColor => switch (this) {
        RollState.live => AppTheme.coral,
        RollState.developing => AppTheme.amber,
        RollState.developed => AppTheme.sage,
      };

  Color get badgeTextColor =>
      this == RollState.developing ? AppTheme.ink : AppTheme.cream;
}

class RollBadge extends StatelessWidget {
  const RollBadge({super.key, required this.state});

  final RollState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: state.badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == RollState.live) ...[
            const _PulseDot(),
            const SizedBox(width: 5),
          ],
          Text(
            state.badgeLabel.toUpperCase(),
            style: AppText.mono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: state.badgeTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
